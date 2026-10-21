import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/domain/entity/app_theme_entity.dart';
import 'package:opennutritracker/core/domain/entity/config_entity.dart';
import 'package:opennutritracker/core/domain/entity/intake_entity.dart';
import 'package:opennutritracker/core/domain/entity/intake_type_entity.dart';
import 'package:opennutritracker/core/domain/usecase/get_config_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_intake_usecase.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/reminders/data/meals_logged_today.dart';
import 'package:opennutritracker/features/reminders/domain/reminder.dart';

class _Intakes implements GetIntakeUsecase {
  final Set<IntakeTypeEntity> logged;
  final offsets = <(int, int)>[];
  _Intakes(this.logged);

  Future<List<IntakeEntity>> _of(IntakeTypeEntity type, int h, int m) async {
    offsets.add((h, m));
    return logged.contains(type)
        ? [
            IntakeEntity(
              id: type.name,
              unit: 'g',
              amount: 100,
              type: type,
              meal: MealEntity.empty(),
              dateTime: DateTime(2026, 10, 21, 8),
            ),
          ]
        : const [];
  }

  @override
  Future<List<IntakeEntity>> getTodayBreakfastIntake({
    int dayStartOffsetHours = 0,
    int dayStartOffsetMinutes = 0,
  }) => _of(
    IntakeTypeEntity.breakfast,
    dayStartOffsetHours,
    dayStartOffsetMinutes,
  );

  @override
  Future<List<IntakeEntity>> getTodayLunchIntake({
    int dayStartOffsetHours = 0,
    int dayStartOffsetMinutes = 0,
  }) => _of(IntakeTypeEntity.lunch, dayStartOffsetHours, dayStartOffsetMinutes);

  @override
  Future<List<IntakeEntity>> getTodayDinnerIntake({
    int dayStartOffsetHours = 0,
    int dayStartOffsetMinutes = 0,
  }) =>
      _of(IntakeTypeEntity.dinner, dayStartOffsetHours, dayStartOffsetMinutes);

  @override
  Future<List<IntakeEntity>> getTodaySnackIntake({
    int dayStartOffsetHours = 0,
    int dayStartOffsetMinutes = 0,
  }) => _of(IntakeTypeEntity.snack, dayStartOffsetHours, dayStartOffsetMinutes);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Config implements GetConfigUsecase {
  @override
  Future<ConfigEntity> getConfig() async => ConfigEntity(
    true,
    true,
    false,
    AppThemeEntity.system,
    dayStartOffsetHours: 4,
    dayStartOffsetMinutes: 30,
  );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test('nothing logged answers nothing', () async {
    expect(await mealsLoggedToday(_Intakes({}), _Config()), isEmpty);
  });

  test('a logged meal answers its reminder and the daily one', () async {
    expect(
      await mealsLoggedToday(_Intakes({IntakeTypeEntity.lunch}), _Config()),
      {ReminderType.lunch, ReminderType.logMeals},
    );
  });

  test('reads today under the day-start offset', () async {
    final intakes = _Intakes({});

    await mealsLoggedToday(intakes, _Config());

    expect(intakes.offsets.toSet(), {(4, 30)});
  });
}
