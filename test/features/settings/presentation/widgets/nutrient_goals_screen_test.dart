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
  bool saved = false;
  double? savedFibre;
  double? savedSatFat;

  @override
  Future<TrackedDayEntity?> getTodayTrackedDay(DateTime day) async => null;

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
  }) async {
    saved = true;
    savedFibre = fibreGoal;
    savedSatFat = satFatGoal;
  }

  @override
  void add(SettingsEvent event) {}
}

class _FakeProfileBloc extends Fake implements ProfileBloc {
  @override
  Future<UserEntity> getUser() async =>
      UserEntityFixtures.youngSedentaryMaleWantingToMaintainWeight;
}

class _FakeDiaryBloc extends Fake implements DiaryBloc {
  @override
  void add(DiaryEvent event) {}
}

class _FakeCalendarDayBloc extends Fake implements CalendarDayBloc {
  @override
  void add(CalendarDayEvent event) {}
}

class _FakeHomeBloc extends Fake implements HomeBloc {
  @override
  void add(HomeEvent event) {}
}

void main() {
  Future<_FakeSettingsBloc> openScreen(WidgetTester tester) async {
    final settingsBloc = _FakeSettingsBloc();
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [S.delegate],
        supportedLocales: S.supportedLocales,
        home: Builder(
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
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    return settingsBloc;
  }

  Finder fibreField() => find.byType(TextField).first;

  Future<void> save(WidgetTester tester) async {
    await tester.tap(find.text(l10nEn.buttonSaveLabel));
    await tester.pumpAndSettle();
  }

  testWidgets('saves a typed value without a submit', (tester) async {
    // #1324: the iOS number pad has no return key, so onSubmitted never
    // fires there. Typing and tapping Save has to be enough.
    final settingsBloc = await openScreen(tester);

    await tester.tap(fibreField());
    await tester.enterText(fibreField(), '40');
    await save(tester);

    expect(settingsBloc.saved, isTrue);
    expect(settingsBloc.savedFibre, 40);
    // Untouched rows keep following their defaults.
    expect(settingsBloc.savedSatFat, isNull);
  });

  testWidgets('applies a typed value when the field loses focus', (
    tester,
  ) async {
    await openScreen(tester);

    await tester.tap(fibreField());
    await tester.enterText(fibreField(), '40');
    await tester.pump();
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pump();

    expect(tester.widget<Slider>(find.byType(Slider).first).value, 40);
  });

  testWidgets('a slider move after typing wins over the typed text', (
    tester,
  ) async {
    final settingsBloc = await openScreen(tester);

    await tester.tap(fibreField());
    await tester.enterText(fibreField(), '40');
    tester.widget<Slider>(find.byType(Slider).first).onChanged!(20);
    await tester.pump();
    await save(tester);

    expect(settingsBloc.savedFibre, 20);
  });
}
