import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/domain/entity/tracked_day_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_entity.dart';
import 'package:opennutritracker/features/diary/presentation/bloc/calendar_day_bloc.dart';
import 'package:opennutritracker/features/diary/presentation/bloc/diary_bloc.dart';
import 'package:opennutritracker/features/home/presentation/bloc/home_bloc.dart';
import 'package:opennutritracker/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:opennutritracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:opennutritracker/features/settings/presentation/widgets/nutrient_goals_screen.dart';
import 'package:opennutritracker/generated/l10n.dart';

import '../../../../fixture/user_entity_fixtures.dart';
import '../../../../helpers/test_l10n.dart';

class _FakeSettingsBloc extends Fake implements SettingsBloc {
  int updateTrackedDayCalls = 0;
  int setNutrientGoalsCalls = 0;
  double? savedFibre;
  double? savedIron;
  bool? savedClearAll;
  Map<String, double?> savedGoals = {};

  /// Today's row as the screen loads it; null means no row yet.
  TrackedDayEntity? today;

  @override
  Future<TrackedDayEntity?> getTodayTrackedDay(DateTime day) async => today;

  @override
  Future<void> updateTrackedDay(DateTime day) async {
    updateTrackedDayCalls++;
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
  }) async {
    setNutrientGoalsCalls++;
    savedFibre = fibreGoal;
    savedIron = ironGoal;
    savedClearAll = clearAll;
    savedGoals = {
      'fibre': fibreGoal,
      'satFat': satFatGoal,
      'sugars': sugarsGoal,
      'sodium': sodiumGoal,
      'calcium': calciumGoal,
      'iron': ironGoal,
      'potassium': potassiumGoal,
      'vitaminD': vitaminDGoal,
      'vitaminB12': vitaminB12Goal,
      'magnesium': magnesiumGoal,
    };
  }

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

class _FakeDiaryBloc extends Fake implements DiaryBloc {
  @override
  void add(DiaryEvent event) {}
}

class _FakeCalendarDayBloc extends Fake implements CalendarDayBloc {
  @override
  void add(CalendarDayEvent event) {}
}

void main() {
  Future<void> openScreen(
    WidgetTester tester,
    _FakeSettingsBloc settingsBloc,
  ) async {
    // Tall enough for the ListView to build every row, iron included.
    await tester.binding.setSurfaceSize(const Size(400, 3000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [S.delegate],
        supportedLocales: S.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => NutrientGoalsScreen(
                    settingsBloc: settingsBloc,
                    profileBloc: _FakeProfileBloc(),
                    diaryBloc: _FakeDiaryBloc(),
                    calendarDayBloc: _FakeCalendarDayBloc(),
                    homeBloc: _FakeHomeBloc(),
                  ),
                ),
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
  }

  Future<void> tapSave(WidgetTester tester) async {
    await tester.tap(find.text(l10nEn.buttonSaveLabel));
    await tester.pumpAndSettle();
  }

  // #1347: typing a value and tapping Save without the keyboard's Done key
  // used to drop the typed value, saving nothing for an untouched slider.
  testWidgets('saves typed nutrient goals when Save is tapped without Done', (
    tester,
  ) async {
    final settingsBloc = _FakeSettingsBloc();
    await openScreen(tester, settingsBloc);

    // Rows run fibre, saturated fat, sugars, sodium, calcium, iron: the
    // first is a whole-number field, the sixth a decimal one.
    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), '32');
    await tester.enterText(fields.at(5), '12.5');

    await tester.tap(find.text(l10nEn.buttonSaveLabel));
    await tester.pumpAndSettle();

    expect(settingsBloc.updateTrackedDayCalls, 1);
    expect(settingsBloc.setNutrientGoalsCalls, 1);
    expect(settingsBloc.savedFibre, 32);
    expect(settingsBloc.savedIron, 12.5);
    expect(find.byType(NutrientGoalsScreen), findsNothing);
  });

  // #1371 review: Save used to re-parse every field, so an untouched
  // goal was overwritten by what its field displays — a null goal became
  // an explicit override equal to the static default (replacing the
  // Diary's age- and gender-aware reference), and a fractional goal of
  // 10 or more was saved rounded. Only fields the user edited are applied.
  group('untouched goals keep their value on Save', () {
    testWidgets('editing only fibre leaves every other null goal null', (
      tester,
    ) async {
      final settingsBloc = _FakeSettingsBloc();
      await openScreen(tester, settingsBloc);

      await tester.enterText(find.byType(TextField).at(0), '32');
      await tapSave(tester);

      expect(settingsBloc.setNutrientGoalsCalls, 1);
      expect(settingsBloc.savedGoals, {
        'fibre': 32,
        'satFat': null,
        'sugars': null,
        'sodium': null,
        'calcium': null,
        'iron': null,
        'potassium': null,
        'vitaminD': null,
        'vitaminB12': null,
        'magnesium': null,
      });
    });

    testWidgets('editing only fibre keeps a fractional iron goal of 12.5', (
      tester,
    ) async {
      final settingsBloc = _FakeSettingsBloc()
        ..today = TrackedDayEntity(
          day: DateTime(2026, 10, 14),
          calorieGoal: 2000,
          caloriesTracked: 0,
          ironGoal: 12.5,
        );
      await openScreen(tester, settingsBloc);

      // The field shows the rounded "13"; Save must not store that.
      expect(find.widgetWithText(TextField, '13'), findsOneWidget);
      await tester.enterText(find.byType(TextField).at(0), '32');
      await tapSave(tester);

      expect(settingsBloc.savedFibre, 32);
      expect(settingsBloc.savedIron, 12.5);
    });

    testWidgets('saving without edits stores every goal exactly as loaded', (
      tester,
    ) async {
      final settingsBloc = _FakeSettingsBloc()
        ..today = TrackedDayEntity(
          day: DateTime(2026, 10, 14),
          calorieGoal: 2000,
          caloriesTracked: 0,
          sugarsGoal: 42.4,
          ironGoal: 12.5,
          magnesiumGoal: 333.3,
        );
      await openScreen(tester, settingsBloc);

      await tapSave(tester);

      expect(settingsBloc.setNutrientGoalsCalls, 1);
      expect(settingsBloc.savedGoals, {
        'fibre': null,
        'satFat': null,
        'sugars': 42.4,
        'sodium': null,
        'calcium': null,
        'iron': 12.5,
        'potassium': null,
        'vitaminD': null,
        'vitaminB12': null,
        'magnesium': 333.3,
      });
    });

    testWidgets('a field edited and then reset is not applied on Save', (
      tester,
    ) async {
      final settingsBloc = _FakeSettingsBloc();
      await openScreen(tester, settingsBloc);

      await tester.enterText(find.byType(TextField).at(0), '32');
      await tester.tap(find.text(l10nEn.buttonResetLabel));
      await tester.pumpAndSettle();
      await tapSave(tester);

      expect(settingsBloc.savedGoals.values, everyElement(isNull));
    });
  });

  // #1349: Reset then Save has to clear goals already stored on today's
  // row. The data source skips null columns unless clearAll is set, so
  // the screen must pass it with every goal null.
  testWidgets('Reset then Save clears stored goals with clearAll', (
    tester,
  ) async {
    final settingsBloc = _FakeSettingsBloc()
      ..today = TrackedDayEntity(
        day: DateTime(2026, 10, 14),
        calorieGoal: 2000,
        caloriesTracked: 0,
        fibreGoal: 32,
        ironGoal: 12.5,
      );
    await openScreen(tester, settingsBloc);

    await tester.tap(find.text(l10nEn.buttonResetLabel));
    await tester.pumpAndSettle();
    await tapSave(tester);

    expect(settingsBloc.setNutrientGoalsCalls, 1);
    expect(settingsBloc.savedClearAll, isTrue);
    expect(settingsBloc.savedGoals.values, everyElement(isNull));
  });

  // #1324: the iOS number pad has no return key. Once the keyboard is
  // dismissed, the slider has to show the typed value.
  testWidgets('applies a typed value when the field loses focus', (
    tester,
  ) async {
    final settingsBloc = _FakeSettingsBloc();
    await openScreen(tester, settingsBloc);

    final fibre = find.byType(TextField).at(0);
    await tester.tap(fibre);
    await tester.enterText(fibre, '32');
    await tester.pump();
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pump();

    expect(tester.widget<Slider>(find.byType(Slider).at(0)).value, 32);
  });

  testWidgets('an unedited field applies nothing when it loses focus', (
    tester,
  ) async {
    final settingsBloc = _FakeSettingsBloc();
    await openScreen(tester, settingsBloc);

    await tester.tap(find.byType(TextField).at(5));
    await tester.pump();
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pump();
    await tapSave(tester);

    expect(settingsBloc.savedGoals.values, everyElement(isNull));
  });
}
