import 'dart:convert';

import 'package:logging/logging.dart';
import 'package:meta/meta.dart';
import 'package:opennutritracker/core/data/data_source/health/health_export_records.dart';
import 'package:opennutritracker/core/data/repository/config_repository.dart';
import 'package:opennutritracker/core/data/repository/health_export_repository.dart';
import 'package:opennutritracker/core/data/repository/intake_repository.dart';
import 'package:opennutritracker/core/data/repository/water_intake_repository.dart';
import 'package:opennutritracker/core/domain/entity/config_entity.dart';
import 'package:opennutritracker/core/domain/entity/intake_entity.dart';
import 'package:opennutritracker/core/domain/entity/intake_type_entity.dart';
import 'package:opennutritracker/core/domain/entity/water_intake_entity.dart';
import 'package:opennutritracker/core/utils/calc/day_boundary_calc.dart';
import 'package:opennutritracker/core/utils/hive_db_provider.dart';
import 'package:opennutritracker/core/utils/id_generator.dart';

/// Mirrors the diary's meals and water into Health Connect / Apple Health.
///
/// Each run fingerprints what every diary day would tell the store and
/// rewrites only the days whose fingerprint differs from the one saved after
/// their last write. Adds, edits, deletions and imports all reach the store
/// through this one path, and a run with nothing changed never touches the
/// platform.
class ExportDiaryToHealthUsecase {
  /// Where a date-only entry — one added from the diary calendar — is placed
  /// within its day.
  static const _slotTime = {
    IntakeTypeEntity.breakfast: Duration(hours: 8),
    IntakeTypeEntity.lunch: Duration(hours: 12, minutes: 30),
    IntakeTypeEntity.dinner: Duration(hours: 19),
    IntakeTypeEntity.snack: Duration(hours: 16),
  };

  @visibleForTesting
  static DateTime Function() clock = DateTime.now;

  final _log = Logger('ExportDiaryToHealthUsecase');

  /// The run in flight and its profile; a caller on the same profile joins
  /// it instead of rewriting the same days (as [ImportWorkoutsUsecase]).
  Future<int>? _inFlight;
  String? _inFlightProfileId;

  final HealthExportRepository _healthExportRepository;
  final ConfigRepository _configRepository;
  final IntakeRepository _intakeRepository;
  final WaterIntakeRepository _waterIntakeRepository;
  final HiveDBProvider _hiveDBProvider;

  ExportDiaryToHealthUsecase(
    this._healthExportRepository,
    this._configRepository,
    this._intakeRepository,
    this._waterIntakeRepository,
    this._hiveDBProvider,
  );

  /// The background entry point — launch, resume and pause — where a refusal
  /// is logged rather than shown.
  Future<int> exportIfDue() async {
    try {
      return await exportNow();
    } catch (error, stackTrace) {
      _log.severe('Background health export failed', error, stackTrace);
      return 0;
    }
  }

  /// Writes every day that is out of step and returns how many. Returns 0
  /// without touching the platform when the user has not opted in; throws
  /// what the health store throws.
  Future<int> exportNow() {
    final profileId = _hiveDBProvider.activeProfileId;
    final inFlight = _inFlight;
    if (inFlight != null && _inFlightProfileId == profileId) return inFlight;
    final run = _export(profileId);
    _inFlight = run;
    _inFlightProfileId = profileId;
    return run.whenComplete(() {
      if (identical(_inFlight, run)) {
        _inFlight = null;
        _inFlightProfileId = null;
      }
    });
  }

  Future<int> _export(String profileId) async {
    final config = await _configRepository.getConfig();
    if (!config.healthExportEnabled) return 0;
    final offset = config.dayStartOffsetTotalMinutes;

    final intakesByDay = <String, List<IntakeEntity>>{};
    for (final dbo in await _intakeRepository.getAllIntakesDBO()) {
      final intake = IntakeEntity.fromIntakeDBO(dbo);
      final day = DayBoundaryCalc.dayKeyOf(intake.dateTime, offset);
      (intakesByDay[day] ??= []).add(intake);
    }
    final waterByDay = <String, List<WaterIntakeEntity>>{};
    for (final entry in await _waterIntakeRepository.getAllEntries()) {
      final day = DayBoundaryCalc.dayKeyOf(
        entry.dateTime,
        offset,
        clockReading: true,
      );
      (waterByDay[day] ??= []).add(entry);
    }

    // Recent days, plus any day the store still holds something for.
    final now = clock();
    final cutoff = DayBoundaryCalc.logicalDayOfMinutes(
      now,
      offset,
    ).subtract(const Duration(days: ConfigEntity.healthExportBackfillDays));
    final days = {
      for (final day in {...intakesByDay.keys, ...waterByDay.keys})
        if (!DateTime.parse(day).isBefore(cutoff)) day,
      ...config.healthExportedDays.keys,
    }.toList()..sort();

    var written = 0;
    for (final day in days) {
      final (from, to) = _window(day, offset);
      // Health Connect refuses a record from the future, so an entry filed
      // for later today waits: left out of the fingerprint as well, it brings
      // the day back on the first run after its time.
      final meals = [
        for (final intake in intakesByDay[day] ?? const <IntakeEntity>[])
          _meal(intake, from, to),
      ].where((meal) => !meal.time.isAfter(now)).toList();
      final water = [
        for (final entry in waterByDay[day] ?? const <WaterIntakeEntity>[])
          if (!entry.dateTime.isAfter(now))
            ExportedWater(
              time: _clamp(entry.dateTime, from, to),
              millilitres: entry.amountMl,
            ),
      ];
      final fingerprint = meals.isEmpty && water.isEmpty
          ? null
          : _fingerprint(meals, water);
      if (config.healthExportedDays[day] == fingerprint) continue;
      if (!_stillOnProfile(profileId)) return written;
      await _healthExportRepository.replaceDay(
        from: from,
        to: to,
        meals: meals,
        water: water,
      );
      if (!_stillOnProfile(profileId)) return written;
      await _configRepository.setConfigHealthExportedDay(day, fingerprint);
      written++;
    }
    if (_stillOnProfile(profileId)) {
      await _configRepository.setConfigHealthLastExportAt(clock());
    }
    if (written > 0) _log.info('Exported $written diary day(s) to health');
    return written;
  }

  bool _stillOnProfile(String profileId) {
    if (_hiveDBProvider.activeProfileId == profileId) return true;
    _log.info('Abandoning the health export: the active profile changed');
    return false;
  }

  /// The wall-clock span of diary day [day] under the configured boundary.
  static (DateTime, DateTime) _window(String day, int offsetMinutes) {
    final date = DateTime.parse(day);
    final offset = Duration(minutes: offsetMinutes);
    return (
      date.add(offset),
      DateTime(date.year, date.month, date.day + 1).add(offset),
    );
  }

  static ExportedMeal _meal(IntakeEntity intake, DateTime from, DateTime to) {
    final nutriments = intake.meal.nutriments;
    double? perIntake(double? per100, [double unitsPerGram = 1]) =>
        per100 == null
        ? null
        : _finite(intake.amount * per100 / 100 / unitsPerGram);
    final logged = intake.dateTime;
    final time = DayBoundaryCalc.isDayLabel(logged)
        ? DateTime(
            logged.year,
            logged.month,
            logged.day,
          ).add(_slotTime[intake.type]!)
        : logged;
    return ExportedMeal(
      slot: ExportedMealSlot.values.byName(intake.type.name),
      time: _clamp(time, from, to),
      name: intake.meal.name,
      energyKcal: _finite(intake.totalKcal),
      carbsGram: _finite(intake.totalCarbsGram),
      proteinGram: _finite(intake.totalProteinsGram),
      fatGram: _finite(intake.totalFatsGram),
      fiberGram: perIntake(nutriments.fiber100),
      sugarGram: perIntake(nutriments.sugars100),
      saturatedFatGram: perIntake(nutriments.saturatedFat100),
      sodiumGram: perIntake(nutriments.sodium100, 1000), // stored in mg
    );
  }

  static double? _finite(double value) => value.isFinite ? value : null;

  static DateTime _clamp(DateTime time, DateTime from, DateTime to) {
    if (time.isBefore(from)) return from;
    if (!time.isBefore(to)) return to.subtract(const Duration(seconds: 1));
    return time;
  }

  /// Order-independent, so a reordered box reads as unchanged.
  static String _fingerprint(
    List<ExportedMeal> meals,
    List<ExportedWater> water,
  ) => IdGenerator.getContentID(
    ([
      for (final meal in meals) jsonEncode(meal.fields),
      for (final entry in water) jsonEncode(entry.fields),
    ]..sort()).join('\n'),
  );
}
