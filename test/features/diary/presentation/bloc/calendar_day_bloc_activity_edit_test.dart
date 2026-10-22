import 'dart:typed_data';

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
import 'package:opennutritracker/core/domain/entity/user_activity_entity.dart';
import 'package:opennutritracker/core/domain/usecase/add_config_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/add_tracked_day_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/delete_intake_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/delete_user_activity_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_config_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_intake_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_tracked_day_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_user_activity_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_user_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/update_intake_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/update_user_activity_usecase.dart';
import 'package:opennutritracker/core/utils/calc/day_boundary_calc.dart';
import 'package:opennutritracker/core/utils/calc/macro_calc.dart';
import 'package:opennutritracker/features/diary/presentation/bloc/calendar_day_bloc.dart';

import '../../../../fixture/physical_activity_entity_fixtures.dart';
import '../../../../helpers/fake_hive_db_provider.dart';
import '../../../../helpers/hive_test_setup.dart';

/// #1317 review: editing yesterday's activity in the Diary changes
/// yesterday's goal by the energy the edit adds or removes, and nothing on
/// today's row or yesterday's food totals.
class _FakeUpdateIntake extends Fake implements UpdateIntakeUsecase {}

/// Only a MET recompute asks for the user, and the imported workout below
/// scales its measured credit with the duration instead.
class _FakeGetUser extends Fake implements GetUserUsecase {}

final _yesterday = DateTime(2026, 10, 4);
final _today = DateTime(2026, 10, 5);

/// 30 minutes, 150 kcal, logged yesterday evening by the workout import.
final _ride = UserActivityEntity(
  'ride',
  30,
  150,
  DateTime(2026, 10, 4, 18),
  PhysicalActivityFixtures.moderateBicycling,
  externalId: 'record-1',
);

TrackedDayDBO _row(
  DateTime day, {
  required double goal,
  required double kcal,
}) => TrackedDayDBO(
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

  setUpAll(registerHiveAdaptersOnce);

  setUp(() async {
    DayBoundaryCalc.clock = () => DateTime(2026, 10, 5, 12);
    final tag = boxTag++;
    Future<Box<T>> open<T>(String name) => Hive.openBox<T>(
      'calendar_activity_edit_${name}_$tag',
      bytes: Uint8List(0),
    );
    trackedDayBox = await open<TrackedDayDBO>('day');
    final db = FakeHiveDBProvider(
      configBox: await open<ConfigDBO>('config'),
      intakeBox: await open<IntakeDBO>('intake'),
      trackedDayBox: trackedDayBox,
      userActivityBox: await open<UserActivityDBO>('activity'),
    );
    final configDataSource = ConfigDataSource(db);
    await configDataSource.initializeConfig();

    final intakeRepository = IntakeRepository(IntakeDataSource(db));
    final activityRepository = UserActivityRepository(
      UserActivityDataSource(db),
    );
    final configRepository = ConfigRepository(configDataSource);
    final trackedDayRepository = TrackedDayRepository(TrackedDayDataSource(db));

    await activityRepository.addUserActivity(_ride);
    // Yesterday: 200 kcal of food on a 2000 goal raised by the ride.
    await trackedDayBox.put(
      '2026-10-04',
      _row(_yesterday, goal: 2150, kcal: 200),
    );
    await trackedDayBox.put('2026-10-05', _row(_today, goal: 2000, kcal: 300));

    bloc = CalendarDayBloc(
      GetUserActivityUsecase(activityRepository),
      GetIntakeUsecase(
        intakeRepository,
        RecipeRepository(RecipeDataSource(db)),
      ),
      DeleteIntakeUsecase(intakeRepository),
      DeleteUserActivityUsecase(activityRepository, configRepository),
      GetTrackedDayUsecase(trackedDayRepository),
      AddTrackedDayUsecase(trackedDayRepository),
      _FakeUpdateIntake(),
      UpdateUserActivityUsecase(activityRepository, _FakeGetUser()),
      GetConfigUsecase(configRepository),
      AddConfigUsecase(configRepository),
    );
  });

  tearDown(() async {
    DayBoundaryCalc.clock = DateTime.now;
    await bloc.close();
  });

  void expectOnlyYesterdaysGoalsMoved(double kcalMoved) {
    final yesterday = trackedDayBox.get('2026-10-04')!;
    expect(yesterday.calorieGoal, 2150 + kcalMoved);
    expect(
      yesterday.carbsGoal,
      closeTo(250 + MacroCalc.getTotalCarbsGoal(kcalMoved), 1e-9),
    );
    expect(
      yesterday.fatGoal,
      closeTo(70 + MacroCalc.getTotalFatsGoal(kcalMoved), 1e-9),
    );
    expect(
      yesterday.proteinGoal,
      closeTo(100 + MacroCalc.getTotalProteinsGoal(kcalMoved), 1e-9),
    );
    expect(yesterday.caloriesTracked, 200);
    expect(yesterday.carbsTracked, 40);
    expect(yesterday.fatTracked, 2);
    expect(yesterday.proteinTracked, 6);

    final today = trackedDayBox.get('2026-10-05')!;
    expect(today.calorieGoal, 2000);
    expect(today.carbsGoal, 250);
    expect(today.fatGoal, 70);
    expect(today.proteinGoal, 100);
    expect(today.caloriesTracked, 300);
  }

  test('a longer ride raises only yesterday\'s goals', () async {
    // 60 minutes credits 300 kcal: 150 more.
    await bloc.updateUserActivityItem(_ride, 60, _yesterday);

    expectOnlyYesterdaysGoalsMoved(150);
  });

  test('a shorter ride lowers only yesterday\'s goals', () async {
    // 15 minutes credits 75 kcal: 75 less.
    await bloc.updateUserActivityItem(_ride, 15, _yesterday);

    expectOnlyYesterdaysGoalsMoved(-75);
  });
}
