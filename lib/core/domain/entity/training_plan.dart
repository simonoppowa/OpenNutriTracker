import 'package:equatable/equatable.dart';
import 'package:opennutritracker/core/data/dbo/config_dbo.dart';
import 'package:opennutritracker/core/domain/entity/goal_targets.dart';

enum DayType { rest, training }

/// What logging an activity on a rest day does (#36).
enum AutoTrainingDay { off, suggest, automatic }

enum AutoTrainingDayDecision { none, suggest, switchToTraining }

/// Separate goals for training days (#35): the training goal set, the
/// weekdays that are training days by default, and the days the user set
/// by hand, which win over the weekly plan, and what logging an activity
/// does (#36). Kept per profile in the config (fields 110–113). Without training goals every day uses the normal
/// goals, as before.
class TrainingPlan extends Equatable {
  final GoalTargets? trainingTargets;

  /// [DateTime.monday] to [DateTime.sunday].
  final Set<int> trainingWeekdays;

  /// Day types set by hand, keyed by `yyyy-MM-dd`.
  final Map<String, DayType> dayTypes;

  final AutoTrainingDay autoTrainingDay;

  const TrainingPlan({
    this.trainingTargets,
    this.trainingWeekdays = const {},
    this.dayTypes = const {},
    this.autoTrainingDay = AutoTrainingDay.off,
  });

  /// Whether training days have goals of their own.
  bool get isEnabled => trainingTargets != null;

  DayType dayTypeOf(DateTime day) =>
      dayTypes[_key(day)] ??
      (trainingWeekdays.contains(day.weekday)
          ? DayType.training
          : DayType.rest);

  bool isSetByHand(DateTime day) => dayTypes.containsKey(_key(day));

  /// What an activity logged on [day] should do: nothing on a training day,
  /// on a day the user set by hand, or while training days have no goals of
  /// their own; else what [autoTrainingDay] says.
  AutoTrainingDayDecision decisionAfterActivity(DateTime day) {
    if (!isEnabled || isSetByHand(day) || dayTypeOf(day) == DayType.training) {
      return AutoTrainingDayDecision.none;
    }
    return switch (autoTrainingDay) {
      AutoTrainingDay.off => AutoTrainingDayDecision.none,
      AutoTrainingDay.suggest => AutoTrainingDayDecision.suggest,
      AutoTrainingDay.automatic => AutoTrainingDayDecision.switchToTraining,
    };
  }

  /// The goals that apply on [day]: the training goals on a training day
  /// when there are any, else [restTargets].
  GoalTargets targetsFor(DateTime day, GoalTargets restTargets) {
    final training = trainingTargets;
    return training != null && dayTypeOf(day) == DayType.training
        ? training
        : restTargets;
  }

  TrainingPlan withDayType(DateTime day, DayType type) =>
      _copy(dayTypes: {...dayTypes, _key(day): type});

  TrainingPlan withTrainingTargets(GoalTargets? targets) => TrainingPlan(
    trainingTargets: targets,
    trainingWeekdays: trainingWeekdays,
    dayTypes: dayTypes,
    autoTrainingDay: autoTrainingDay,
  );

  TrainingPlan withAutoTrainingDay(AutoTrainingDay mode) =>
      _copy(autoTrainingDay: mode);

  TrainingPlan withTrainingWeekdays(Set<int> weekdays) =>
      _copy(trainingWeekdays: weekdays);

  TrainingPlan _copy({
    Set<int>? trainingWeekdays,
    Map<String, DayType>? dayTypes,
    AutoTrainingDay? autoTrainingDay,
  }) => TrainingPlan(
    trainingTargets: trainingTargets,
    trainingWeekdays: trainingWeekdays ?? this.trainingWeekdays,
    dayTypes: dayTypes ?? this.dayTypes,
    autoTrainingDay: autoTrainingDay ?? this.autoTrainingDay,
  );

  /// The plan stored in [config]; a value no settings screen would store
  /// reads as unset.
  factory TrainingPlan.fromConfigDBO(ConfigDBO config) {
    GoalTargets? targets;
    final stored = config.trainingGoalTargets;
    if (stored != null) {
      try {
        targets = GoalTargets.fromJson(Map<String, dynamic>.from(stored));
      } on FormatException {
        targets = null;
      }
    }
    return TrainingPlan(
      trainingTargets: targets,
      trainingWeekdays: {
        for (final day in config.trainingWeekdays ?? const <int>[])
          if (_validWeekday(day)) day,
      },
      dayTypes: {
        for (final MapEntry(:key, :value)
            in (config.dayTypeOverrides ?? const <String, String>{}).entries)
          if (_validKey(key) && _dayType(value) != null) key: _dayType(value)!,
      },
      autoTrainingDay:
          _autoMode(config.autoTrainingDayMode) ?? AutoTrainingDay.off,
    );
  }

  void applyTo(ConfigDBO config) {
    config
      ..trainingGoalTargets = trainingTargets?.toJson()
      ..trainingWeekdays = (trainingWeekdays.toList()..sort())
      ..dayTypeOverrides = {
        for (final MapEntry(:key, :value) in dayTypes.entries) key: value.name,
      }
      ..autoTrainingDayMode = autoTrainingDay.name;
  }

  Map<String, dynamic> toJson() => {
    'trainingTargets': trainingTargets?.toJson(),
    'trainingWeekdays': trainingWeekdays.toList()..sort(),
    'dayTypes': {
      for (final MapEntry(:key, :value) in dayTypes.entries) key: value.name,
    },
    'autoTrainingDay': autoTrainingDay.name,
  };

  /// Parses the plan of a backup; a missing key is unset. Throws a
  /// [FormatException] for a value no settings screen would store.
  factory TrainingPlan.fromJson(Map<String, dynamic> json) {
    final targets = json['trainingTargets'];
    final weekdays = json['trainingWeekdays'];
    final days = json['dayTypes'];
    if (targets != null && targets is! Map<String, dynamic>) {
      throw const FormatException('invalid trainingTargets');
    }
    if (weekdays != null &&
        (weekdays is! List || !weekdays.every(_validWeekday))) {
      throw FormatException('invalid trainingWeekdays: $weekdays');
    }
    if (days != null &&
        (days is! Map ||
            !days.entries.every(
              (e) =>
                  e.key is String &&
                  _validKey(e.key as String) &&
                  e.value is String &&
                  _dayType(e.value as String) != null,
            ))) {
      throw FormatException('invalid dayTypes: $days');
    }
    final auto = json['autoTrainingDay'];
    if (auto != null && (auto is! String || _autoMode(auto) == null)) {
      throw FormatException('invalid autoTrainingDay: $auto');
    }
    return TrainingPlan(
      trainingTargets: targets == null
          ? null
          : GoalTargets.fromJson(targets as Map<String, dynamic>),
      trainingWeekdays: {...?(weekdays as List?)?.cast<int>()},
      dayTypes: {
        for (final MapEntry(:key, :value)
            in ((days as Map?) ?? const {}).entries)
          key as String: _dayType(value as String)!,
      },
      autoTrainingDay: auto == null
          ? AutoTrainingDay.off
          : _autoMode(auto as String)!,
    );
  }

  static String _key(DateTime day) =>
      '${day.year.toString().padLeft(4, '0')}-'
      '${day.month.toString().padLeft(2, '0')}-'
      '${day.day.toString().padLeft(2, '0')}';

  static final _keyFormat = RegExp(r'^\d{4}-\d{2}-\d{2}$');

  static bool _validKey(String key) => _keyFormat.hasMatch(key);

  static bool _validWeekday(Object? day) =>
      day is int && day >= DateTime.monday && day <= DateTime.sunday;

  static DayType? _dayType(String name) =>
      DayType.values.where((type) => type.name == name).firstOrNull;

  static AutoTrainingDay? _autoMode(String? name) =>
      AutoTrainingDay.values.where((mode) => mode.name == name).firstOrNull;

  @override
  List<Object?> get props => [
    trainingTargets,
    (trainingWeekdays.toList()..sort()).join(','),
    (dayTypes.entries.map((e) => '${e.key}=${e.value.name}').toList()..sort())
        .join(','),
    autoTrainingDay,
  ];
}
