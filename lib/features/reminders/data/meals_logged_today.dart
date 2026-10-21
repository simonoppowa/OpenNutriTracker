import 'package:opennutritracker/core/domain/usecase/get_config_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_intake_usecase.dart';
import 'package:opennutritracker/features/reminders/domain/reminder.dart';

/// The meal reminder types already answered today (#72): each meal with an
/// entry on today's logical day (day-start offset, #139), and the daily
/// "log your meals" reminder as soon as anything is logged.
Future<Set<ReminderType>> mealsLoggedToday(
  GetIntakeUsecase intakes,
  GetConfigUsecase config,
) async {
  final settings = await config.getConfig();
  final hours = settings.dayStartOffsetHours;
  final minutes = settings.dayStartOffsetMinutes;
  final logged = {
    if ((await intakes.getTodayBreakfastIntake(
      dayStartOffsetHours: hours,
      dayStartOffsetMinutes: minutes,
    )).isNotEmpty)
      ReminderType.breakfast,
    if ((await intakes.getTodayLunchIntake(
      dayStartOffsetHours: hours,
      dayStartOffsetMinutes: minutes,
    )).isNotEmpty)
      ReminderType.lunch,
    if ((await intakes.getTodayDinnerIntake(
      dayStartOffsetHours: hours,
      dayStartOffsetMinutes: minutes,
    )).isNotEmpty)
      ReminderType.dinner,
    if ((await intakes.getTodaySnackIntake(
      dayStartOffsetHours: hours,
      dayStartOffsetMinutes: minutes,
    )).isNotEmpty)
      ReminderType.snack,
  };
  return {...logged, if (logged.isNotEmpty) ReminderType.logMeals};
}
