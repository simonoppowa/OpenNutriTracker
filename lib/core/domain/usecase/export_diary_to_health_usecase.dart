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

  /// The pass in flight and the one queued behind it. Passes never overlap,
  /// whichever profile each is for: two at once would interleave one's
  /// deletion of a day with the other's writes. A request made while a pass
  /// runs queues one follow-up, which reads the diary afresh when it starts,
  /// so an edit made meanwhile is not lost to the running pass's snapshot;
  /// every request until then shares it.
  Future<int>? _running;
  Future<int>? _queued;

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
    if (_queued case final queued?) return queued;
    final running = _running;
    if (running == null) return _start();
    return _queued = _startAfter(running);
  }

  Future<int> _startAfter(Future<int> running) async {
    // How the running pass went is for its own callers to hear.
    await running.catchError((Object _) => 0);
    _queued = null;
    return _start();
  }

  /// Starts a pass for the profile active now, not when it was requested.
  Future<int> _start() {
    final run = _export(_hiveDBProvider.activeProfileId);
    _running = run;
    return run.whenComplete(() {
      if (identical(_running, run)) _running = null;
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

    // A boundary change moves every window, so records written under the
    // old one are cleared first. A cleared window can hold records an
    // earlier pass already rewrote under the new boundary (one that failed
    // partway), and entries that now file under a day older than the
    // backfill, so every day whose new window overlaps it is rewritten
    // below, whatever its fingerprint or age.
    final overlapsCleared = <String>{};
    for (final entry in config.healthExportedDays.entries) {
      final oldOffset = _offsetOf(entry.value, offset);
      if (oldOffset == offset) continue;
      if (!await _mayContinue(profileId)) return 0;
      final (from, to) = _window(entry.key, oldOffset);
      await _healthExportRepository.replaceDay(
        from: from,
        to: to,
        meals: const [],
        water: const [],
      );
      overlapsCleared.addAll(_daysOverlapping(entry.key, from, to, offset));
    }

    // Recent days, plus any day the store may still hold something for.
    final now = clock();
    final cutoff = DayBoundaryCalc.logicalDayOfMinutes(
      now,
      offset,
    ).subtract(const Duration(days: ConfigEntity.healthExportBackfillDays));
    final days = {
      for (final day in {...intakesByDay.keys, ...waterByDay.keys})
        if (!DateTime.parse(day).isBefore(cutoff)) day,
      ...config.healthExportedDays.keys,
      ...overlapsCleared,
    }.toList()..sort();

    var written = 0;
    // A day the store refuses (a value out of its range, say) is skipped,
    // not fatal: days run oldest first, so stopping at it would hold back
    // every newer day, today included, until it aged out of the backfill.
    // Its fingerprint is not saved, so it is retried next run, and the pass
    // still throws at the end so "Export now" reports it.
    (Object, StackTrace)? refusal;
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
          : '${_fingerprint(profileId, meals, water)}@$offset';
      final stored = config.healthExportedDays[day];
      if (stored == fingerprint && !overlapsCleared.contains(day)) continue;
      // Nothing to write, and nothing this day wrote left to clear.
      if (stored == null && fingerprint == null) continue;
      if (!await _mayContinue(profileId)) return written;
      try {
        await _healthExportRepository.replaceDay(
          from: from,
          to: to,
          meals: meals,
          water: water,
        );
      } catch (error, stackTrace) {
        _log.warning('The health store refused $day', error, stackTrace);
        refusal ??= (error, stackTrace);
        continue;
      }
      if (!await _mayContinue(profileId)) return written;
      await _configRepository.setConfigHealthExportedDay(day, fingerprint);
      written++;
    }
    if (written > 0) _log.info('Exported $written diary day(s) to health');
    if (refusal case (final error, final stackTrace)) {
      Error.throwWithStackTrace(error, stackTrace);
    }
    if (await _mayContinue(profileId)) {
      await _configRepository.setConfigHealthLastExportAt(clock());
    }
    return written;
  }

  /// Whether the run that started under [profileId] may still write: the
  /// profile is unchanged and the user has not switched the export off.
  Future<bool> _mayContinue(String profileId) async {
    if (_hiveDBProvider.activeProfileId != profileId) {
      _log.info('Abandoning the health export: the active profile changed');
      return false;
    }
    return (await _configRepository.getConfig()).healthExportEnabled;
  }

  /// The day boundary a stored `fingerprint@offset` value was written under.
  static int _offsetOf(String stored, int fallback) =>
      int.tryParse(stored.split('@').last) ?? fallback;

  /// The days whose window under [offsetMinutes] overlaps [from]–[to], the
  /// window [day] had under another boundary: [day] itself and the
  /// neighbour the move shifted part of it to.
  static Iterable<String> _daysOverlapping(
    String day,
    DateTime from,
    DateTime to,
    int offsetMinutes,
  ) sync* {
    final date = DateTime.parse(day);
    for (final shift in const [-1, 0, 1]) {
      final neighbour = DateTime(
        date.year,
        date.month,
        date.day + shift,
      ).toIso8601String().substring(0, 10);
      final (start, end) = _window(neighbour, offsetMinutes);
      if (start.isBefore(to) && from.isBefore(end)) yield neighbour;
    }
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

  /// Order-independent, so a reordered box reads as unchanged. The profile
  /// is part of it: the store is one person's and the cache device-wide, so
  /// a day written by another profile reads as changed and is rewritten.
  static String _fingerprint(
    String profileId,
    List<ExportedMeal> meals,
    List<ExportedWater> water,
  ) => IdGenerator.getContentID(
    [
      profileId,
      ...[
        for (final meal in meals) jsonEncode(meal.fields),
        for (final entry in water) jsonEncode(entry.fields),
      ]..sort(),
    ].join('\n'),
  );
}
