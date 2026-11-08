import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/data/data_source/remote_search_cache_data_source.dart';
import 'package:opennutritracker/core/domain/entity/app_theme_entity.dart';
import 'package:opennutritracker/core/domain/entity/config_entity.dart';
import 'package:opennutritracker/core/domain/entity/tracked_day_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_entity.dart';
import 'package:opennutritracker/core/domain/usecase/add_config_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/add_tracked_day_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_config_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_kcal_goal_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_macro_goal_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_tracked_day_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/set_day_boundary_usecase.dart';
import 'package:opennutritracker/core/utils/calc/day_boundary_calc.dart';
import 'package:opennutritracker/core/utils/energy_unit_provider.dart';
import 'package:opennutritracker/core/utils/locator.dart';
import 'package:opennutritracker/features/diary/presentation/bloc/calendar_day_bloc.dart';
import 'package:opennutritracker/features/diary/presentation/bloc/diary_bloc.dart';
import 'package:opennutritracker/features/home/presentation/bloc/home_bloc.dart';
import 'package:opennutritracker/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:opennutritracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:opennutritracker/features/settings/presentation/widgets/diary_day_boundary_dialog.dart';
import 'package:opennutritracker/features/settings/presentation/widgets/kcal_adjustment_dialog.dart';
import 'package:opennutritracker/features/settings/presentation/widgets/macro_split_dialog.dart';
import 'package:opennutritracker/features/settings/presentation/widgets/nutrient_goals_screen.dart';
import 'package:opennutritracker/generated/l10n.dart';
import 'package:provider/provider.dart';

import '../../../../fixture/user_entity_fixtures.dart';
import '../../../../helpers/fake_reload_blocs.dart';
import '../../../../helpers/test_l10n.dart';

/// #1360: with "Day starts at" later than the current time, today is
/// yesterday's date. Goal edits have to land on that day — the one Home
/// and the Diary show — not on `DateTime.now()`'s calendar date.

/// 20:40 on the 11th with the day starting at 22:00: the logical day is
/// the 10th.
final _now = DateTime(2026, 10, 11, 20, 40);
final _logicalDay = DateTime(2026, 10, 10);

class _FakeSettingsBloc extends Fake implements SettingsBloc {
  final List<DateTime> trackedDayUpdates = [];
  final List<DateTime> trackedDayReads = [];
  final List<DateTime> nutrientGoalWrites = [];

  /// The boundary passes as soon as a tracked day is updated, so a save
  /// that resolved the day a second time would write to the next day.
  @override
  Future<DateTime> getCurrentLogicalDay() async => trackedDayUpdates.isEmpty
      ? _logicalDay
      : _logicalDay.add(const Duration(days: 1));

  @override
  Future<void> updateTrackedDay(DateTime day) async =>
      trackedDayUpdates.add(day);

  @override
  Future<TrackedDayEntity?> getTodayTrackedDay(DateTime day) async {
    trackedDayReads.add(day);
    return null;
  }

  @override
  Future<void> setTodayNutrientGoals(
    DateTime day, {
    double? fibreGoal,
    double? satFatGoal,
    double? sugarsGoal,
    double? sodiumGoal,
    double? calciumGoal,
    double? ironGoal,
    double? potassiumGoal,
    double? vitaminDGoal,
    double? vitaminB12Goal,
    double? magnesiumGoal,
    bool clearAll = false,
  }) async => nutrientGoalWrites.add(day);

  @override
  Future<double> getKcalAdjustment() async => 0;

  @override
  Future<void> setKcalAdjustment(double kcalAdjustment) async {}

  @override
  Future<double?> getUserCarbGoalPct() async => 0.6;

  @override
  Future<double?> getUserProteinGoalPct() async => 0.15;

  @override
  Future<double?> getUserFatGoalPct() async => 0.25;

  @override
  Future<void> setMacroGoals(
    double carbGoalPct,
    double proteinGoalPct,
    double fatGoalPct,
  ) async {}

  @override
  Future<int> getDayStartOffsetHours() async => 22;

  @override
  Future<int> getDayStartOffsetMinutes() async => 0;

  @override
  Future<void> setDayStartOffset(int hours, int minutes) async {}

  @override
  void add(SettingsEvent event) {}
}

class _FakeProfileBloc extends Fake implements ProfileBloc {
  @override
  Future<UserEntity> getUser() async =>
      UserEntityFixtures.youngSedentaryMaleWantingToMaintainWeight;
}

class _FakeHomeBloc extends Fake implements HomeBloc {
  @override
  void add(HomeEvent event) {}
}

class _RecordingDiaryBloc extends Fake implements DiaryBloc {
  final List<DiaryEvent> events = [];

  @override
  void add(DiaryEvent event) => events.add(event);
}

class _FakeCalendarDayBloc extends Fake implements CalendarDayBloc {
  @override
  void add(CalendarDayEvent event) {}
}

class _FakeConfigUsecase extends Fake implements GetConfigUsecase {
  @override
  Future<ConfigEntity> getConfig() async => const ConfigEntity(
    true,
    true,
    false,
    AppThemeEntity.system,
    dayStartOffsetHours: 22,
  );
}

Widget _openerApp(Widget Function() dialog) => ChangeNotifierProvider(
  create: (_) => EnergyUnitProvider(),
  child: MaterialApp(
    localizationsDelegates: const [S.delegate],
    supportedLocales: S.supportedLocales,
    home: Scaffold(
      body: Builder(
        builder: (context) => ElevatedButton(
          onPressed: () =>
              showDialog<void>(context: context, builder: (_) => dialog()),
          child: const Text('Open'),
        ),
      ),
    ),
  ),
);

void main() {
  // The kcal and macro dialogs reload the Diary and Trends through the
  // locator after saving (#1359).
  setUp(() => ReloadRecorder().register());
  tearDown(() async => locator.reset());

  test('getCurrentLogicalDay resolves the configured boundary', () async {
    DayBoundaryCalc.clock = () => _now;
    addTearDown(() => DayBoundaryCalc.clock = DateTime.now);

    final bloc = SettingsBloc(
      _FakeConfigUsecase(),
      _UnusedAddConfigUsecase(),
      _UnusedAddTrackedDayUsecase(),
      _UnusedGetKcalGoalUsecase(),
      _UnusedGetMacroGoalUsecase(),
      _UnusedRemoteSearchCacheDataSource(),
      _UnusedGetTrackedDayUsecase(),
      _UnusedSetDayBoundaryUsecase(),
    );
    addTearDown(bloc.close);

    expect(await bloc.getCurrentLogicalDay(), _logicalDay);
  });

  testWidgets('the kcal adjustment updates the logical day', (tester) async {
    final settingsBloc = _FakeSettingsBloc();
    await tester.pumpWidget(
      _openerApp(
        () => KcalAdjustmentDialog(
          settingsBloc: settingsBloc,
          profileBloc: _FakeProfileBloc(),
          homeBloc: _FakeHomeBloc(),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    await tester.tap(find.bySemanticsIdentifier('kcal-adjustment-save'));
    await tester.pumpAndSettle();

    expect(settingsBloc.trackedDayUpdates, [_logicalDay]);
  });

  testWidgets('the macro split updates the logical day', (tester) async {
    final settingsBloc = _FakeSettingsBloc();
    await tester.pumpWidget(
      _openerApp(
        () => MacroSplitDialog(
          settingsBloc: settingsBloc,
          homeBloc: _FakeHomeBloc(),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    await tester.tap(find.text(l10nEn.dialogOKLabel));
    await tester.pumpAndSettle();

    expect(settingsBloc.trackedDayUpdates, [_logicalDay]);
  });

  testWidgets('nutrient goals are read from and written to the logical day', (
    tester,
  ) async {
    final settingsBloc = _FakeSettingsBloc();
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [S.delegate],
        supportedLocales: S.supportedLocales,
        home: NutrientGoalsScreen(
          settingsBloc: settingsBloc,
          profileBloc: _FakeProfileBloc(),
          diaryBloc: _RecordingDiaryBloc(),
          calendarDayBloc: _FakeCalendarDayBloc(),
          homeBloc: _FakeHomeBloc(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(settingsBloc.trackedDayReads, [_logicalDay]);

    await tester.tap(find.bySemanticsIdentifier('nutrient-goals-save'));
    await tester.pumpAndSettle();

    // The row check/creation and the per-nutrient write share one day.
    expect(settingsBloc.trackedDayUpdates, [_logicalDay]);
    expect(settingsBloc.nutrientGoalWrites, [_logicalDay]);
  });

  testWidgets('saving the day boundary reloads the Diary', (tester) async {
    final diaryBloc = _RecordingDiaryBloc();
    await tester.pumpWidget(
      _openerApp(
        () => DiaryDayBoundaryDialog(
          settingsBloc: _FakeSettingsBloc(),
          homeBloc: _FakeHomeBloc(),
          diaryBloc: diaryBloc,
          calendarDayBloc: _FakeCalendarDayBloc(),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    await tester.tap(find.bySemanticsIdentifier('day-boundary-save'));
    await tester.pumpAndSettle();

    // DiaryBloc resolves the Diary's "today" on load, so without this the
    // today marker stays on the day the old boundary gave.
    expect(diaryBloc.events, [isA<LoadDiaryYearEvent>()]);
  });
}

class _UnusedAddConfigUsecase extends Fake implements AddConfigUsecase {}

class _UnusedAddTrackedDayUsecase extends Fake
    implements AddTrackedDayUsecase {}

class _UnusedGetKcalGoalUsecase extends Fake implements GetKcalGoalUsecase {}

class _UnusedGetMacroGoalUsecase extends Fake implements GetMacroGoalUsecase {}

class _UnusedRemoteSearchCacheDataSource extends Fake
    implements RemoteSearchCacheDataSource {}

class _UnusedGetTrackedDayUsecase extends Fake
    implements GetTrackedDayUsecase {}

class _UnusedSetDayBoundaryUsecase extends Fake
    implements SetDayBoundaryUsecase {}
