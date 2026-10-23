import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:opennutritracker/core/data/data_source/config_data_source.dart';
import 'package:opennutritracker/core/data/data_source/intake_data_source.dart';
import 'package:opennutritracker/core/data/data_source/recipe_data_source.dart';
import 'package:opennutritracker/core/data/data_source/tracked_day_data_source.dart';
import 'package:opennutritracker/core/data/data_source/user_activity_data_source.dart';
import 'package:opennutritracker/core/data/data_source/user_activity_dbo.dart';
import 'package:opennutritracker/core/data/dbo/config_dbo.dart';
import 'package:opennutritracker/core/data/dbo/intake_dbo.dart';
import 'package:opennutritracker/core/data/dbo/tracked_day_dbo.dart';
import 'package:opennutritracker/core/data/repository/config_repository.dart';
import 'package:opennutritracker/core/data/repository/intake_repository.dart';
import 'package:opennutritracker/core/data/repository/recipe_repository.dart';
import 'package:opennutritracker/core/data/repository/tracked_day_repository.dart';
import 'package:opennutritracker/core/data/repository/user_activity_repository.dart';
import 'package:opennutritracker/core/domain/entity/intake_entity.dart';
import 'package:opennutritracker/core/domain/entity/intake_type_entity.dart';
import 'package:opennutritracker/core/domain/usecase/add_config_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/add_tracked_day_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/delete_intake_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/delete_user_activity_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_config_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_intake_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_tracked_day_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_user_activity_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/update_intake_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/update_user_activity_usecase.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_nutriments_entity.dart';
import 'package:opennutritracker/features/diary/presentation/bloc/calendar_day_bloc.dart';

import '../../../../helpers/fake_hive_db_provider.dart';
import '../../../../helpers/hive_test_setup.dart';

/// #1317 review: the day the Diary hands CalendarDayBloc is a date label.
///
/// Before #1382 the Diary opened on a raw `DateTime.now()`. The intake
/// listing reads only its calendar date, but the tracked-day lookup
/// rolls a non-midnight value back through the boundary, so at 02:30
/// under a 04:00 boundary the card showed the 4th's totals and goal
/// above the 5th's entries, and a delete there debited the 4th.
class _FakeUpdateIntake extends Fake implements UpdateIntakeUsecase {}

class _FakeUpdateActivity extends Fake implements UpdateUserActivityUsecase {}

class _FakeContext extends Fake implements BuildContext {}

/// 200 kcal per 100 g.
final _meal = MealEntity(
  code: null,
  name: 'Toast',
  url: null,
  mealQuantity: '100',
  mealUnit: 'g',
  servingQuantity: 100,
  servingUnit: 'g',
  servingSize: null,
  nutriments: MealNutrimentsEntity(
    energyKcal100: 200,
    carbohydrates100: 40,
    fat100: 2,
    proteins100: 6,
    sugars100: null,
    saturatedFat100: null,
    fiber100: null,
  ),
  source: MealSourceEntity.custom,
);

TrackedDayDBO _row(DateTime day, {required double goal, required double kcal}) =>
    TrackedDayDBO(
      day: day,
      calorieGoal: goal,
      caloriesTracked: kcal,
      carbsGoal: 250,
      carbsTracked: kcal / 5,
      fatGoal: 70,
      fatTracked: kcal / 100,
      proteinGoal: 100,
      proteinTracked: kcal * 3 / 100,
    );

void main() {
  var boxTag = 0;

  late Box<TrackedDayDBO> trackedDayBox;
  late CalendarDayBloc bloc;
  late IntakeEntity toast;

  // What the Diary selected when opened at 02:30 on the 5th.
  final selectedAt0230 = DateTime(2026, 10, 5, 2, 30);

  setUpAll(registerHiveAdaptersOnce);

  setUp(() async {
    final tag = boxTag++;
    final configBox = await Hive.openBox<ConfigDBO>(
      'calendar_label_config_$tag',
      bytes: Uint8List(0),
    );
    final intakeBox = await Hive.openBox<IntakeDBO>(
      'calendar_label_intake_$tag',
      bytes: Uint8List(0),
    );
    trackedDayBox = await Hive.openBox<TrackedDayDBO>(
      'calendar_label_day_$tag',
      bytes: Uint8List(0),
    );
    final activityBox = await Hive.openBox<UserActivityDBO>(
      'calendar_label_act_$tag',
      bytes: Uint8List(0),
    );
    final db = FakeHiveDBProvider(
      configBox: configBox,
      intakeBox: intakeBox,
      trackedDayBox: trackedDayBox,
      userActivityBox: activityBox,
    );
    final configDataSource = ConfigDataSource(db);
    await configDataSource.initializeConfig();
    await configDataSource.setConfigDayStartOffset(4, 0);

    final intakeRepository = IntakeRepository(IntakeDataSource(db));
    final activityRepository = UserActivityRepository(
      UserActivityDataSource(db),
    );
    final configRepository = ConfigRepository(configDataSource);
    final trackedDayRepository = TrackedDayRepository(TrackedDayDataSource(db));

    // Lunch on the 5th, listed on the 5th, counted on the 5th's row.
    toast = IntakeEntity(
      id: 'toast',
      unit: 'g',
      amount: 100,
      type: IntakeTypeEntity.breakfast,
      meal: _meal,
      dateTime: DateTime(2026, 10, 5, 12),
    );
    await intakeRepository.addIntake(toast);
    await trackedDayBox.put(
      '2026-10-04',
      _row(DateTime(2026, 10, 4), goal: 1800, kcal: 300),
    );
    await trackedDayBox.put(
      '2026-10-05',
      _row(DateTime(2026, 10, 5), goal: 2000, kcal: 200),
    );

    final getConfig = GetConfigUsecase(configRepository);
    bloc = CalendarDayBloc(
      GetUserActivityUsecase(activityRepository),
      GetIntakeUsecase(intakeRepository, RecipeRepository(RecipeDataSource(db))),
      DeleteIntakeUsecase(intakeRepository),
      DeleteUserActivityUsecase(activityRepository, configRepository),
      GetTrackedDayUsecase(trackedDayRepository),
      AddTrackedDayUsecase(trackedDayRepository),
      _FakeUpdateIntake(),
      _FakeUpdateActivity(),
      getConfig,
      AddConfigUsecase(configRepository),
    );
  });

  tearDown(() => bloc.close());

  test('the card shows the row of the day whose entries it lists', () async {
    bloc.add(LoadCalendarDayEvent(selectedAt0230));
    final loaded = await bloc.stream.firstWhere((s) => s is CalendarDayLoaded)
        as CalendarDayLoaded;

    expect(loaded.breakfastIntakeList.map((i) => i.id), ['toast']);
    expect(loaded.trackedDayEntity, isNotNull);
    expect(loaded.trackedDayEntity!.day.day, 5);
    expect(loaded.trackedDayEntity!.caloriesTracked, 200);
    expect(loaded.trackedDayEntity!.calorieGoal, 2000);
  });

  test('deleting a listed entry debits that day\'s row', () async {
    await bloc.deleteIntakeItem(_FakeContext(), toast, selectedAt0230);

    expect(trackedDayBox.get('2026-10-05')!.caloriesTracked, 0);
    expect(trackedDayBox.get('2026-10-04')!.caloriesTracked, 300);
  });
}
