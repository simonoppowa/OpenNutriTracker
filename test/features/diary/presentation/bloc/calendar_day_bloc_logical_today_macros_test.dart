// Covers #1441: with the day boundary moved past the current hour, the
// logical today's calendar date can equal a past calendar date. Home
// computes macro targets live from the config split (carb/fat/protein
// percentages); the Diary read them off the stored tracked-day row, which
// was written under whatever split was in effect when the row was last
// touched. If the user changed the split and then moved the boundary, the
// two screens showed different targets for the same logical day.
//
// After the fix, the Diary's logical-today row is restamped with macro
// goals derived from the current split, so Home and Diary agree. Past
// days still show the split they were tracked under.

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
import 'package:opennutritracker/core/domain/usecase/add_config_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/add_tracked_day_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/delete_intake_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/delete_user_activity_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_config_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_intake_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_macro_goal_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_tracked_day_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_user_activity_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/update_intake_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/update_user_activity_usecase.dart';
import 'package:opennutritracker/core/utils/calc/day_boundary_calc.dart';
import 'package:opennutritracker/core/utils/calc/macro_calc.dart';
import 'package:opennutritracker/features/diary/presentation/bloc/calendar_day_bloc.dart';

import '../../../../helpers/fake_hive_db_provider.dart';
import '../../../../helpers/hive_test_setup.dart';

class _FakeUpdateIntake extends Fake implements UpdateIntakeUsecase {}

class _FakeUpdateActivity extends Fake implements UpdateUserActivityUsecase {}

TrackedDayDBO _row(
  DateTime day, {
  required double goal,
  required double carbs,
  required double fat,
  required double protein,
}) =>
    TrackedDayDBO(
      day: day,
      calorieGoal: goal,
      caloriesTracked: 0,
      carbsGoal: carbs,
      fatGoal: fat,
      proteinGoal: protein,
    );

void main() {
  var boxTag = 0;
  late Box<TrackedDayDBO> trackedDayBox;
  late CalendarDayBloc bloc;
  late DateTime logicalToday;

  setUpAll(registerHiveAdaptersOnce);

  setUp(() async {
    final tag = boxTag++;
    final configBox = await Hive.openBox<ConfigDBO>(
      'logical_today_macros_config_$tag',
      bytes: Uint8List(0),
    );
    final intakeBox = await Hive.openBox<IntakeDBO>(
      'logical_today_macros_intake_$tag',
      bytes: Uint8List(0),
    );
    trackedDayBox = await Hive.openBox<TrackedDayDBO>(
      'logical_today_macros_day_$tag',
      bytes: Uint8List(0),
    );
    final activityBox = await Hive.openBox<UserActivityDBO>(
      'logical_today_macros_act_$tag',
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
    // The live split: 45/21/34, matching the Home values in #1441.
    await configDataSource.setConfigCarbGoalPct(0.45);
    await configDataSource.setConfigFatGoalPct(0.21);
    await configDataSource.setConfigProteinGoalPct(0.34);
    // Boundary at 23:00 so the moment the test looks at falls into
    // yesterday's logical day, mirroring the issue's set-up.
    await configDataSource.setConfigDayStartOffset(23, 0);

    final intakeRepository = IntakeRepository(IntakeDataSource(db));
    final activityRepository =
        UserActivityRepository(UserActivityDataSource(db));
    final configRepository = ConfigRepository(configDataSource);
    final trackedDayRepository = TrackedDayRepository(TrackedDayDataSource(db));

    // The row the user has for the logical today, written under the old
    // 50/19/31 split a Home refresh has since superseded.
    logicalToday = DayBoundaryCalc.currentLogicalDayLabel(23, 0);
    await trackedDayBox.put(
      logicalToday.toIso8601String().substring(0, 10),
      _row(logicalToday, goal: 2934, carbs: 367, fat: 62, protein: 220),
    );

    bloc = CalendarDayBloc(
      GetUserActivityUsecase(activityRepository),
      GetIntakeUsecase(intakeRepository, RecipeRepository(RecipeDataSource(db))),
      DeleteIntakeUsecase(intakeRepository),
      DeleteUserActivityUsecase(activityRepository, configRepository),
      GetTrackedDayUsecase(trackedDayRepository),
      AddTrackedDayUsecase(trackedDayRepository),
      _FakeUpdateIntake(),
      _FakeUpdateActivity(),
      GetConfigUsecase(configRepository),
      AddConfigUsecase(configRepository),
      GetMacroGoalUsecase(configRepository),
    );
  });

  tearDown(() => bloc.close());

  test(
    'the logical today reads macro goals from the current split, not the stored row',
    () async {
      bloc.add(LoadCalendarDayEvent(logicalToday));
      final loaded = await bloc.stream
          .firstWhere((s) => s is CalendarDayLoaded) as CalendarDayLoaded;

      final entity = loaded.trackedDayEntity!;
      // Home computes `(2934 * pct) / kcalPerGram`; expect the same here.
      final expectedCarbs = MacroCalc.getTotalCarbsGoal(
        2934,
        userCarbsGoal: 0.45,
      );
      final expectedFat = MacroCalc.getTotalFatsGoal(2934, userFatsGoal: 0.21);
      final expectedProtein = MacroCalc.getTotalProteinsGoal(
        2934,
        userProteinsGoal: 0.34,
      );
      expect(entity.carbsGoal, expectedCarbs);
      expect(entity.fatGoal, expectedFat);
      expect(entity.proteinGoal, expectedProtein);
      // kcal goal still comes from the stored row.
      expect(entity.calorieGoal, 2934);
    },
  );

  test('a past day keeps the macro goals it was tracked under', () async {
    final yesterday = logicalToday.subtract(const Duration(days: 1));
    await trackedDayBox.put(
      yesterday.toIso8601String().substring(0, 10),
      _row(yesterday, goal: 2934, carbs: 367, fat: 62, protein: 220),
    );

    bloc.add(LoadCalendarDayEvent(yesterday));
    final loaded = await bloc.stream.firstWhere((s) => s is CalendarDayLoaded)
        as CalendarDayLoaded;

    final entity = loaded.trackedDayEntity!;
    expect(entity.carbsGoal, 367);
    expect(entity.fatGoal, 62);
    expect(entity.proteinGoal, 220);
  });
}
