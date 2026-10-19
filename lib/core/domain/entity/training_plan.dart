import 'package:equatable/equatable.dart';
import 'package:opennutritracker/core/data/dbo/config_dbo.dart';
import 'package:opennutritracker/core/domain/entity/goal_targets.dart';

enum DayType { rest, training }

/// Separate goals for training days (#35): the training goal set, the
/// weekdays that are training days by default, and the days the user set
/// by hand, which win over the weekly plan. Kept per profile in the config
/// (fields 110–112). Without training goals every day uses the normal
/// goals, as before.
class TrainingPlan extends Equatable {
  final GoalTargets? trainingTargets;

  /// [DateTime.monday] to [DateTime.sunday].
  final Set<int> trainingWeekdays;

  /// Day types set by hand, keyed by `yyyy-MM-dd`.
  final Map<String, DayType> dayTypes;

  const TrainingPlan({
    this.trainingTargets,
    this.trainingWeekdays = const {},
    this.dayTypes = const {},
  });

  /// Whether training days have goals of their own.
  bool get isEnabled => trainingTargets != null;

  DayType dayTypeOf(DateTime day) =>
      dayTypes[_key(day)] ??
      (trainingWeekdays.contains(day.weekday)
          ? DayType.training
          : DayType.rest);

  bool isSetByHand(DateTime day) => dayTypes.containsKey(_key(day));

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
  );

  TrainingPlan withTrainingWeekdays(Set<int> weekdays) =>
      _copy(trainingWeekdays: weekdays);

  TrainingPlan _copy({
    Set<int>? trainingWeekdays,
    Map<String, DayType>? dayTypes,
  }) => TrainingPlan(
    trainingTargets: trainingTargets,
    trainingWeekdays: trainingWeekdays ?? this.trainingWeekdays,
    dayTypes: dayTypes ?? this.dayTypes,
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
    );
  }

  void applyTo(ConfigDBO config) {
    config
      ..trainingGoalTargets = trainingTargets?.toJson()
      ..trainingWeekdays = (trainingWeekdays.toList()..sort())
      ..dayTypeOverrides = {
        for (final MapEntry(:key, :value) in dayTypes.entries) key: value.name,
      };
  }

  Map<String, dynamic> toJson() => {
    'trainingTargets': trainingTargets?.toJson(),
    'trainingWeekdays': trainingWeekdays.toList()..sort(),
    'dayTypes': {
      for (final MapEntry(:key, :value) in dayTypes.entries) key: value.name,
    },
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

  @override
  List<Object?> get props => [
    trainingTargets,
    (trainingWeekdays.toList()..sort()).join(','),
    (dayTypes.entries.map((e) => '${e.key}=${e.value.name}').toList()..sort())
        .join(','),
  ];
}
