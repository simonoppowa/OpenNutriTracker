import 'package:equatable/equatable.dart';
import 'package:opennutritracker/core/data/dbo/config_dbo.dart';

/// Whether the daily kcal goal is the app's calculation or a fixed number.
enum KcalGoalMode { calculated, fixed }

/// Whether the macro goals are a split of the kcal goal or fixed grams.
enum MacroGoalMode { percent, grams }

/// The user's own goal settings (#32): a fixed kcal goal and macro goals
/// in grams, each switchable back to the calculated or percent goal. Kept
/// per profile in the config (fields 104–109). Unset values mean the
/// app's calculation, which is what every install before them had.
class GoalTargets extends Equatable {
  static const minFixedKcal = 800.0;
  static const maxFixedKcal = 10000.0;
  static const maxMacroG = 1000.0;

  final KcalGoalMode kcalMode;
  final double? fixedKcal;
  final MacroGoalMode macroMode;
  final double? carbsG;
  final double? fatG;
  final double? proteinG;

  const GoalTargets({
    this.kcalMode = KcalGoalMode.calculated,
    this.fixedKcal,
    this.macroMode = MacroGoalMode.percent,
    this.carbsG,
    this.fatG,
    this.proteinG,
  });

  /// The targets stored in [config]; a value no settings screen would
  /// store reads as unset.
  factory GoalTargets.fromConfigDBO(ConfigDBO config) => GoalTargets(
    kcalMode: _kcalMode(config.kcalGoalMode) ?? KcalGoalMode.calculated,
    fixedKcal: _validKcal(config.fixedKcalGoal) ? config.fixedKcalGoal : null,
    macroMode: _macroMode(config.macroGoalMode) ?? MacroGoalMode.percent,
    carbsG: _validGrams(config.carbGoalG) ? config.carbGoalG : null,
    fatG: _validGrams(config.fatGoalG) ? config.fatGoalG : null,
    proteinG: _validGrams(config.proteinGoalG) ? config.proteinGoalG : null,
  );

  void applyTo(ConfigDBO config) {
    config
      ..kcalGoalMode = kcalMode.name
      ..fixedKcalGoal = fixedKcal
      ..macroGoalMode = macroMode.name
      ..carbGoalG = carbsG
      ..fatGoalG = fatG
      ..proteinGoalG = proteinG;
  }

  GoalTargets copyWith({
    KcalGoalMode? kcalMode,
    double? fixedKcal,
    MacroGoalMode? macroMode,
    double? carbsG,
    double? fatG,
    double? proteinG,
  }) => GoalTargets(
    kcalMode: kcalMode ?? this.kcalMode,
    fixedKcal: fixedKcal ?? this.fixedKcal,
    macroMode: macroMode ?? this.macroMode,
    carbsG: carbsG ?? this.carbsG,
    fatG: fatG ?? this.fatG,
    proteinG: proteinG ?? this.proteinG,
  );

  Map<String, dynamic> toJson() => {
    'kcalMode': kcalMode.name,
    'fixedKcal': fixedKcal,
    'macroMode': macroMode.name,
    'carbsG': carbsG,
    'fatG': fatG,
    'proteinG': proteinG,
  };

  /// Parses the targets of a backup; a missing key is unset. Throws a
  /// [FormatException] for a value no settings screen would store.
  factory GoalTargets.fromJson(Map<String, dynamic> json) {
    double? number(String key, bool Function(double?) valid) {
      final value = json[key];
      if (value == null) return null;
      final parsed = value is num ? value.toDouble() : null;
      if (!valid(parsed)) throw FormatException('invalid $key: $value');
      return parsed;
    }

    T? mode<T>(String key, T? Function(String?) parse) {
      final value = json[key];
      if (value == null) return null;
      final parsed = value is String ? parse(value) : null;
      if (parsed == null) throw FormatException('invalid $key: $value');
      return parsed;
    }

    return GoalTargets(
      kcalMode: mode('kcalMode', _kcalMode) ?? KcalGoalMode.calculated,
      fixedKcal: number('fixedKcal', _validKcal),
      macroMode: mode('macroMode', _macroMode) ?? MacroGoalMode.percent,
      carbsG: number('carbsG', _validGrams),
      fatG: number('fatG', _validGrams),
      proteinG: number('proteinG', _validGrams),
    );
  }

  static KcalGoalMode? _kcalMode(String? name) =>
      KcalGoalMode.values.where((mode) => mode.name == name).firstOrNull;

  static MacroGoalMode? _macroMode(String? name) =>
      MacroGoalMode.values.where((mode) => mode.name == name).firstOrNull;

  static bool _validKcal(double? kcal) =>
      kcal != null &&
      kcal.isFinite &&
      kcal >= minFixedKcal &&
      kcal <= maxFixedKcal;

  static bool _validGrams(double? grams) =>
      grams != null && grams.isFinite && grams >= 0 && grams <= maxMacroG;

  @override
  List<Object?> get props => [
    kcalMode,
    fixedKcal,
    macroMode,
    carbsG,
    fatG,
    proteinG,
  ];
}
