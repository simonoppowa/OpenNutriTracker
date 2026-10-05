import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_ce/hive.dart';
import 'package:opennutritracker/core/data/data_source/config_data_source.dart';
import 'package:opennutritracker/core/data/data_source/intake_data_source.dart';
import 'package:opennutritracker/core/data/data_source/tracked_day_data_source.dart';
import 'package:opennutritracker/core/data/data_source/user_activity_data_source.dart';
import 'package:opennutritracker/core/data/data_source/user_activity_dbo.dart';
import 'package:opennutritracker/core/data/dbo/config_dbo.dart';
import 'package:opennutritracker/core/data/dbo/intake_dbo.dart';
import 'package:opennutritracker/core/data/dbo/tracked_day_dbo.dart';
import 'package:opennutritracker/core/data/repository/config_repository.dart';
import 'package:opennutritracker/core/data/repository/intake_repository.dart';
import 'package:opennutritracker/core/data/repository/tracked_day_repository.dart';
import 'package:opennutritracker/core/data/repository/user_activity_repository.dart';
import 'package:opennutritracker/core/domain/entity/intake_entity.dart';
import 'package:opennutritracker/core/domain/entity/intake_type_entity.dart';
import 'package:opennutritracker/core/domain/entity/profile_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_activity_entity.dart';
import 'package:opennutritracker/core/domain/usecase/add_config_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/add_tracked_day_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/delete_intake_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/delete_user_activity_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_config_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_intake_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_profiles_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_tracked_day_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_user_activity_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/update_intake_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/update_user_activity_usecase.dart';
import 'package:opennutritracker/core/presentation/widgets/activity_card.dart';
import 'package:opennutritracker/core/utils/energy_unit_provider.dart';
import 'package:opennutritracker/core/utils/extensions.dart';
import 'package:opennutritracker/features/activity_detail/presentation/bloc/activity_detail_bloc.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_nutriments_entity.dart';
import 'package:opennutritracker/features/diary/diary_page.dart';
import 'package:opennutritracker/features/diary/presentation/bloc/calendar_day_bloc.dart';
import 'package:opennutritracker/features/diary/presentation/bloc/diary_bloc.dart';
import 'package:opennutritracker/features/diary/presentation/widgets/day_info_widget.dart';
import 'package:opennutritracker/features/home/presentation/bloc/home_bloc.dart';
import 'package:opennutritracker/features/meal_detail/presentation/bloc/meal_detail_bloc.dart';
import 'package:opennutritracker/generated/l10n.dart';
import 'package:provider/provider.dart';

import '../../fixture/physical_activity_entity_fixtures.dart';
import '../../helpers/fake_hive_db_provider.dart';
import '../../helpers/hive_test_setup.dart';
import '../../helpers/test_l10n.dart';

/// #1317: deleting an entry from a past Diary day changes that day's row.
///
/// The Diary's delete handlers used to fall back to `DateTime.now()` when
/// the selected day had no tracked-day row, so deleting a past day's food
/// debited today's row and deleting its activity lowered today's goal.
/// These drive the delete through the page itself — swipe back a day,
/// long-press the entry, confirm — and check which row changed.
class _FakeMealDetailBloc extends Fake implements MealDetailBloc {}

class _FakeActivityDetailBloc extends Fake implements ActivityDetailBloc {}

class _FakeHomeBloc extends Fake implements HomeBloc {
  @override
  void add(HomeEvent event) {}
}

class _FakeUpdateIntake extends Fake implements UpdateIntakeUsecase {}

class _FakeUpdateActivity extends Fake implements UpdateUserActivityUsecase {}

class _SingleProfile implements GetProfilesUsecase {
  static final _profile = ProfileEntity(
    id: 'p1',
    name: 'Me',
    createdAt: DateTime(2026, 1, 1),
    boxSuffix: '',
  );

  @override
  List<ProfileEntity> getProfiles() => [_profile];

  @override
  String get activeProfileId => 'p1';

  @override
  ProfileEntity? getActiveProfile() => _profile;
}

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

TrackedDayDBO _row(DateTime day, {required double goal, double kcal = 0}) =>
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
  final locator = GetIt.instance;
  var boxTag = 0;

  late Box<TrackedDayDBO> trackedDayBox;
  late Box<IntakeDBO> intakeBox;
  late Box<UserActivityDBO> activityBox;
  late DateTime today;
  late DateTime yesterday;

  setUpAll(registerHiveAdaptersOnce);

  tearDown(() async {
    await locator.reset();
  });

  /// Opens in-memory boxes, so every write completes within a pump, and
  /// registers what the page resolves through the locator. Yesterday
  /// lists a 200 kcal toast and a 150 kcal ride; today has a row of its
  /// own holding 500 kcal against a 2000 kcal goal.
  Future<void> setUpDiary({required bool yesterdayHasRow}) async {
    final tag = boxTag++;
    final configBox = await Hive.openBox<ConfigDBO>(
      'diary_delete_config_$tag',
      bytes: Uint8List(0),
    );
    intakeBox = await Hive.openBox<IntakeDBO>(
      'diary_delete_intake_$tag',
      bytes: Uint8List(0),
    );
    trackedDayBox = await Hive.openBox<TrackedDayDBO>(
      'diary_delete_day_$tag',
      bytes: Uint8List(0),
    );
    activityBox = await Hive.openBox<UserActivityDBO>(
      'diary_delete_act_$tag',
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

    final now = DateTime.now();
    today = DateTime(now.year, now.month, now.day);
    yesterday = DateUtils.addDaysToDate(today, -1);

    final intakeRepository = IntakeRepository(IntakeDataSource(db));
    final activityRepository = UserActivityRepository(
      UserActivityDataSource(db),
    );
    final configRepository = ConfigRepository(configDataSource);
    final trackedDayRepository = TrackedDayRepository(TrackedDayDataSource(db));

    await intakeRepository.addIntake(
      IntakeEntity(
        id: 'toast',
        unit: 'g',
        amount: 100,
        type: IntakeTypeEntity.breakfast,
        meal: _meal,
        dateTime: yesterday,
      ),
    );
    await activityRepository.addUserActivity(
      UserActivityEntity(
        'ride',
        30,
        150,
        yesterday,
        PhysicalActivityFixtures.moderateBicycling,
      ),
    );
    await trackedDayBox.put(
      today.toParsedDay(),
      _row(today, goal: 2000, kcal: 500),
    );
    if (yesterdayHasRow) {
      await trackedDayBox.put(
        yesterday.toParsedDay(),
        _row(yesterday, goal: 2150, kcal: 200),
      );
    }

    final getConfig = GetConfigUsecase(configRepository);
    final getTrackedDay = GetTrackedDayUsecase(trackedDayRepository);
    locator
      ..registerSingleton<DiaryBloc>(DiaryBloc(getTrackedDay, getConfig))
      ..registerSingleton<CalendarDayBloc>(
        CalendarDayBloc(
          GetUserActivityUsecase(activityRepository),
          GetIntakeUsecase(intakeRepository),
          DeleteIntakeUsecase(intakeRepository),
          DeleteUserActivityUsecase(activityRepository, configRepository),
          getTrackedDay,
          AddTrackedDayUsecase(trackedDayRepository),
          _FakeUpdateIntake(),
          _FakeUpdateActivity(),
          getConfig,
          AddConfigUsecase(configRepository),
        ),
      )
      ..registerFactory<MealDetailBloc>(_FakeMealDetailBloc.new)
      ..registerFactory<ActivityDetailBloc>(_FakeActivityDetailBloc.new)
      ..registerSingleton<HomeBloc>(_FakeHomeBloc())
      ..registerFactory<GetProfilesUsecase>(_SingleProfile.new);
  }

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  /// Pumps the Diary on today, then swipes the day's detail back to
  /// yesterday, as a user would.
  Future<void> openYesterday(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 4000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ChangeNotifierProvider<EnergyUnitProvider>(
        create: (_) => EnergyUnitProvider(),
        child: const MaterialApp(
          localizationsDelegates: [
            S.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: S.supportedLocales,
          home: Scaffold(body: DiaryPage()),
        ),
      ),
    );
    await settle(tester);
    expect(find.text('Toast'), findsNothing, reason: 'today lists nothing');

    await tester.fling(find.byType(DayInfoWidget), const Offset(400, 0), 1500);
    await settle(tester);
    expect(find.text('Toast'), findsOneWidget);
  }

  Future<void> deleteToast(WidgetTester tester) async {
    await tester.ensureVisible(find.text('Toast'));
    await tester.longPress(find.text('Toast'));
    await settle(tester);
    await tester.tap(find.text(l10nEn.dialogDeleteLabel.toUpperCase()));
    await settle(tester);
    await tester.tap(find.text(l10nEn.dialogOKLabel));
    await settle(tester);
  }

  Future<void> deleteRide(WidgetTester tester) async {
    await tester.ensureVisible(find.byType(ActivityCard));
    await tester.longPress(find.byType(ActivityCard));
    await settle(tester);
    await tester.tap(find.text(l10nEn.dialogDeleteLabel.toUpperCase()));
    await settle(tester);
  }

  TrackedDayDBO? rowOf(DateTime day) => trackedDayBox.get(day.toParsedDay());

  testWidgets('deleting a past day\'s entries changes only that day\'s row', (
    tester,
  ) async {
    await setUpDiary(yesterdayHasRow: true);
    await openYesterday(tester);

    await deleteToast(tester);
    expect(intakeBox.isEmpty, isTrue);
    expect(rowOf(yesterday)!.caloriesTracked, 0);
    expect(rowOf(today)!.caloriesTracked, 500);

    await deleteRide(tester);
    expect(activityBox.isEmpty, isTrue);
    expect(rowOf(yesterday)!.calorieGoal, 2000);
    expect(rowOf(today)!.calorieGoal, 2000);
    expect(rowOf(today)!.caloriesTracked, 500);
  });

  testWidgets('deleting the entries of a past day without a row leaves '
      'today\'s row alone', (tester) async {
    await setUpDiary(yesterdayHasRow: false);
    await openYesterday(tester);

    await deleteToast(tester);
    expect(intakeBox.isEmpty, isTrue);
    expect(rowOf(today)!.caloriesTracked, 500, reason: 'was debited to 300');

    await deleteRide(tester);
    expect(activityBox.isEmpty, isTrue);
    expect(rowOf(today)!.calorieGoal, 2000, reason: 'was lowered to 1850');
    expect(rowOf(yesterday), isNull);
  });
}
