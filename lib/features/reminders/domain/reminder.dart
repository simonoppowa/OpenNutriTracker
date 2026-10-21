import 'package:equatable/equatable.dart';

/// What a reminder asks for (#70). [logMeals] is the daily reminder the app
/// had before, "log your meals today".
enum ReminderType { logMeals, breakfast, lunch, dinner, snack, water, weigh }

/// A reminder at a time of day on some weekdays (#70), stored as JSON in
/// the device-wide config.
class Reminder extends Equatable {
  /// Monday to Sunday as [DateTime.weekday] numbers.
  static const everyDay = {1, 2, 3, 4, 5, 6, 7};

  final String id;
  final ReminderType type;
  final int hour;
  final int minute;
  final Set<int> weekdays;
  final bool enabled;

  const Reminder({
    required this.id,
    required this.type,
    required this.hour,
    required this.minute,
    required this.weekdays,
    required this.enabled,
  });

  /// Reads a stored reminder; a type this version does not know reads as
  /// [ReminderType.logMeals].
  factory Reminder.fromJson(Map<String, dynamic> json) => Reminder(
    id: json['id'] as String,
    type:
        ReminderType.values.asNameMap()[json['type']] ?? ReminderType.logMeals,
    hour: json['hour'] as int,
    minute: json['minute'] as int,
    weekdays: {for (final day in json['weekdays'] as List) day as int},
    enabled: json['enabled'] as bool,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.name,
    'hour': hour,
    'minute': minute,
    'weekdays': (weekdays.toList()..sort()),
    'enabled': enabled,
  };

  Reminder copyWith({
    ReminderType? type,
    int? hour,
    int? minute,
    Set<int>? weekdays,
    bool? enabled,
  }) => Reminder(
    id: id,
    type: type ?? this.type,
    hour: hour ?? this.hour,
    minute: minute ?? this.minute,
    weekdays: weekdays ?? this.weekdays,
    enabled: enabled ?? this.enabled,
  );

  @override
  List<Object?> get props => [id, type, hour, minute, weekdays, enabled];
}
