import 'package:opennutritracker/core/data/dbo/config_dbo.dart';
import 'package:opennutritracker/core/domain/entity/config_entity.dart';

/// The active profile's goal settings as they travel in a JSON backup, as
/// `goal_settings.json` (#1363).
///
/// Only the goals the config keeps per profile (see `ConfigDataSource`):
/// the kcal adjustment, the macro split, the per-meal kcal shares and the
/// daily water goal. Device-wide preferences (theme, language, units,
/// notifications, consents) and the health-import state are left out; see
/// `docs/export-format.md` for why. Per-nutrient goals are not here either:
/// they are stored on each tracked day and travel in
/// `user_tracked_day.json`.
///
/// A null field means "no override, use the app's default".
class GoalSettingsBackup {
  /// Bumped only for a change an older reader would misread. A reader
  /// that meets a newer version skips the file rather than guess.
  static const formatVersion = 1;

  // The ranges the Settings dialogs enforce. Kept loose where an older
  // build's rounding could have stored a value just off the mark: the macro
  // split was truncated per macro before the largest-remainder fix, and
  // the meal shares are rounded per meal.
  static const minKcalAdjustment = -1000.0;
  static const maxKcalAdjustment = 1000.0;
  static const _macroSumTolerance = 0.05;
  static const _mealShareSumTolerance = 2;
  static const minDailyWaterGoalMl = 100;
  static const maxDailyWaterGoalMl = 10000;

  static const _mealKeys = [
    ConfigEntity.mealKeyBreakfast,
    ConfigEntity.mealKeyLunch,
    ConfigEntity.mealKeyDinner,
    ConfigEntity.mealKeySnack,
  ];

  final double? kcalAdjustment;
  final double? carbGoalPct;
  final double? proteinGoalPct;
  final double? fatGoalPct;
  final Map<String, int>? mealKcalSharesPct;
  final int? dailyWaterGoalMl;

  const GoalSettingsBackup({
    this.kcalAdjustment,
    this.carbGoalPct,
    this.proteinGoalPct,
    this.fatGoalPct,
    this.mealKcalSharesPct,
    this.dailyWaterGoalMl,
  });

  /// The goals stored in [config], with any value [fromJson] would reject
  /// written as null instead. A corrupt stored value is already ignored by
  /// the app (see `ConfigEntity.fromConfigDBO`); exporting it would make
  /// the whole backup unrestorable.
  factory GoalSettingsBackup.fromConfigDBO(ConfigDBO config) {
    final macros = [
      config.userCarbGoalPct,
      config.userProteinGoalPct,
      config.userFatGoalPct,
    ];
    final macrosValid = _macroSplitError(macros) == null;
    final shares = config.mealKcalSharesPct;
    final water = config.dailyWaterGoalMl;
    return GoalSettingsBackup(
      kcalAdjustment: _kcalAdjustmentError(config.userKcalAdjustment) == null
          ? config.userKcalAdjustment
          : null,
      carbGoalPct: macrosValid ? macros[0] : null,
      proteinGoalPct: macrosValid ? macros[1] : null,
      fatGoalPct: macrosValid ? macros[2] : null,
      mealKcalSharesPct: shares != null && _mealSharesError(shares) == null
          ? {for (final k in _mealKeys) k: shares[k]!}
          : null,
      dailyWaterGoalMl: _waterGoalError(water) == null ? water : null,
    );
  }

  /// Parses and validates a decoded `goal_settings.json`.
  ///
  /// Returns null when the file was written by a newer format this build
  /// does not know, so the rest of the backup still restores. Throws a
  /// [FormatException] when the file is not a valid goal-settings object.
  /// A missing key reads as null, which restores the app's default.
  /// Unknown keys are ignored.
  static GoalSettingsBackup? fromJson(Object? json) {
    if (json is! Map<String, dynamic>) {
      throw const FormatException('goal settings must be a JSON object');
    }
    final version = json['version'];
    if (version is! int || version < 1) {
      throw FormatException('unsupported goal settings version: $version');
    }
    if (version > formatVersion) return null;

    final kcal = _optionalDouble(json, 'kcalAdjustment');
    final macros = [
      _optionalDouble(json, 'carbGoalPct'),
      _optionalDouble(json, 'proteinGoalPct'),
      _optionalDouble(json, 'fatGoalPct'),
    ];
    final shares = _optionalShares(json, 'mealKcalSharesPct');
    final water = _optionalInt(json, 'dailyWaterGoalMl');

    final error =
        _kcalAdjustmentError(kcal) ??
        _macroSplitError(macros) ??
        (shares == null ? null : _mealSharesError(shares)) ??
        _waterGoalError(water);
    if (error != null) throw FormatException(error);

    return GoalSettingsBackup(
      kcalAdjustment: kcal,
      carbGoalPct: macros[0],
      proteinGoalPct: macros[1],
      fatGoalPct: macros[2],
      mealKcalSharesPct: shares == null
          ? null
          : {for (final k in _mealKeys) k: shares[k]!},
      dailyWaterGoalMl: water,
    );
  }

  Map<String, dynamic> toJson() => {
    'version': formatVersion,
    'kcalAdjustment': kcalAdjustment,
    'carbGoalPct': carbGoalPct,
    'proteinGoalPct': proteinGoalPct,
    'fatGoalPct': fatGoalPct,
    'mealKcalSharesPct': mealKcalSharesPct,
    'dailyWaterGoalMl': dailyWaterGoalMl,
  };

  static double? _optionalDouble(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value == null) return null;
    if (value is! num || !value.isFinite) {
      throw FormatException('$key must be a number, got $value');
    }
    return value.toDouble();
  }

  static int? _optionalInt(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value == null) return null;
    if (value is! int) {
      throw FormatException('$key must be a whole number, got $value');
    }
    return value;
  }

  static Map<String, int>? _optionalShares(
    Map<String, dynamic> json,
    String key,
  ) {
    final value = json[key];
    if (value == null) return null;
    if (value is! Map<String, dynamic> || value.values.any((v) => v is! int)) {
      throw FormatException('$key must map meal names to whole numbers');
    }
    return value.cast<String, int>();
  }

  static String? _kcalAdjustmentError(double? kcal) {
    if (kcal == null) return null;
    // NaN fails every comparison, so it is checked for first: a stored NaN
    // would otherwise pass and make `jsonEncode` throw on export.
    if (!kcal.isFinite ||
        kcal < minKcalAdjustment ||
        kcal > maxKcalAdjustment) {
      return 'kcalAdjustment $kcal is outside '
          '$minKcalAdjustment..$maxKcalAdjustment';
    }
    return null;
  }

  /// The split is stored as three fractions that are set together, so it is
  /// all three or none.
  static String? _macroSplitError(List<double?> macros) {
    if (macros.every((m) => m == null)) return null;
    if (macros.any((m) => m == null)) {
      return 'the macro split needs carbs, protein and fat together';
    }
    if (macros.any((m) => !m!.isFinite || m < 0 || m > 1)) {
      return 'macro goals are fractions between 0 and 1, got $macros';
    }
    final sum = macros.fold<double>(0, (a, m) => a + m!);
    if ((sum - 1).abs() > _macroSumTolerance) {
      return 'the macro split adds up to $sum, not 1';
    }
    return null;
  }

  static String? _mealSharesError(Map<String, int> shares) {
    if (!_mealKeys.every(shares.containsKey)) {
      return 'mealKcalSharesPct needs all of $_mealKeys';
    }
    final values = [for (final k in _mealKeys) shares[k]!];
    if (values.any((v) => v < 0 || v > 100)) {
      return 'meal shares are percentages between 0 and 100, got $values';
    }
    final sum = values.fold<int>(0, (a, v) => a + v);
    if ((sum - 100).abs() > _mealShareSumTolerance) {
      return 'the meal shares add up to $sum, not 100';
    }
    return null;
  }

  static String? _waterGoalError(int? water) {
    if (water == null) return null;
    if (water < minDailyWaterGoalMl || water > maxDailyWaterGoalMl) {
      return 'dailyWaterGoalMl $water is outside '
          '$minDailyWaterGoalMl..$maxDailyWaterGoalMl';
    }
    return null;
  }
}
