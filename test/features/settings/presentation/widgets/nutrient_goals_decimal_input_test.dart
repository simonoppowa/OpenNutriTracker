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
  double? savedSodium;
  double? savedIron;
  double? savedVitaminB12;

  @override
  Future<TrackedDayEntity?> getTodayTrackedDay(DateTime day) async => null;

  @override
  Future<DateTime> getCurrentLogicalDay() async => DateTime(2026, 10, 10);

  @override
  Future<void> updateTrackedDay(DateTime day) async {}

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
    savedSodium = sodiumGoal;
    savedIron = ironGoal;
    savedVitaminB12 = vitaminB12Goal;
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

// Rows run fibre, saturated fat, sugars, sodium, calcium, iron, potassium,
// magnesium, vitamin D, vitamin B12.
const _sodium = 3;
const _iron = 5;
const _vitaminB12 = 9;

void main() {
  Future<void> openScreen(
    WidgetTester tester,
    _FakeSettingsBloc settingsBloc,
  ) async {
    // Tall enough for the ListView to build every row.
    await tester.binding.setSurfaceSize(const Size(400, 3000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [S.delegate],
        supportedLocales: S.supportedLocales,
        home: NutrientGoalsScreen(
          settingsBloc: settingsBloc,
          profileBloc: _FakeProfileBloc(),
          diaryBloc: _FakeDiaryBloc(),
          calendarDayBloc: _FakeCalendarDayBloc(),
          homeBloc: _FakeHomeBloc(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Finder field(int row) => find.byType(TextField).at(row);

  String textOf(WidgetTester tester, int row) =>
      tester.widget<TextField>(field(row)).controller!.text;

  /// Clears the field, then types [keys] one at a time the way a keyboard
  /// does, so each keystroke goes through the input formatters on its own.
  Future<void> type(WidgetTester tester, int row, String keys) async {
    await tester.enterText(field(row), '');
    for (final key in keys.split('')) {
      await tester.enterText(field(row), textOf(tester, row) + key);
    }
  }

  Future<void> submitAndSave(WidgetTester tester) async {
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    await tester.tap(find.text(l10nEn.buttonSaveLabel));
    await tester.pumpAndSettle();
  }

  // #1387: comma-decimal keyboards (de, fr, pl, …) emit "," and the field
  // used to drop it, so "12,5" became "125" and was clamped to 30 mg.
  testWidgets('a comma decimal separator saves 12,5 as 12.5', (tester) async {
    final settingsBloc = _FakeSettingsBloc();
    await openScreen(tester, settingsBloc);

    await type(tester, _iron, '12,5');
    expect(textOf(tester, _iron), '12.5');
    await submitAndSave(tester);

    expect(settingsBloc.savedIron, 12.5);
  });

  testWidgets('a period decimal separator still saves 12.5', (tester) async {
    final settingsBloc = _FakeSettingsBloc();
    await openScreen(tester, settingsBloc);

    await type(tester, _iron, '12.5');
    expect(textOf(tester, _iron), '12.5');
    await submitAndSave(tester);

    expect(settingsBloc.savedIron, 12.5);
  });

  testWidgets('a second separator is rejected, either kind', (tester) async {
    final settingsBloc = _FakeSettingsBloc();
    await openScreen(tester, settingsBloc);

    await type(tester, _vitaminB12, '2,4,');
    expect(textOf(tester, _vitaminB12), '2.4');
    await type(tester, _vitaminB12, '2.,');
    expect(textOf(tester, _vitaminB12), '2.');
    // One decimal place, the precision the field displays.
    await type(tester, _vitaminB12, '2,45');
    expect(textOf(tester, _vitaminB12), '2.4');
    await type(tester, _vitaminB12, '2,.4');
    expect(textOf(tester, _vitaminB12), '2.4');
    await submitAndSave(tester);

    expect(settingsBloc.savedVitaminB12, 2.4);
  });

  testWidgets('whole-number rows still take digits only', (tester) async {
    final settingsBloc = _FakeSettingsBloc();
    await openScreen(tester, settingsBloc);

    await type(tester, _sodium, '15,0.0');
    expect(textOf(tester, _sodium), '1500');
    await submitAndSave(tester);

    expect(settingsBloc.savedSodium, 1500);
  });
}
