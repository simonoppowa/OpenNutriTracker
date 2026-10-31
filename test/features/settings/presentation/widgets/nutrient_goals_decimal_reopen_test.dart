// Covers #1444: a saved decimal nutrient goal (12.5) was rounded to a whole
// number (13) on reopen for rows that use decimal steps (iron, magnesium,
// vitamin D, vitamin B12). The screen's own formatter used a `value >= 10 ?
// round : one-decimal` rule, so any value at or above 10 lost its fraction
// on display even though the goal on disk was unchanged (#1371 kept the
// stored value from being re-parsed on Save).
//
// The field should reopen with exactly what the user typed, so `12.5`
// stays `12.5`.

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

class _FakeSettingsBloc extends Fake implements SettingsBloc {
  _FakeSettingsBloc(this._stored);

  final TrackedDayEntity? _stored;

  @override
  Future<TrackedDayEntity?> getTodayTrackedDay(DateTime day) async => _stored;

  @override
  Future<DateTime> getCurrentLogicalDay() async => DateTime(2026, 10, 10);

  @override
  Future<void> updateTrackedDay(DateTime day) async {}

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

// Rows: fibre, satFat, sugars, sodium, calcium, iron, potassium, magnesium,
// vitamin D, vitamin B12.
const _iron = 5;
const _magnesium = 7;

void main() {
  Future<void> openScreen(
    WidgetTester tester,
    _FakeSettingsBloc settingsBloc,
  ) async {
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

  TrackedDayEntity storedWith({double? ironGoal, double? magnesiumGoal}) =>
      TrackedDayEntity(
        day: DateTime(2026, 10, 10),
        calorieGoal: 2000,
        caloriesTracked: 0,
        ironGoal: ironGoal,
        magnesiumGoal: magnesiumGoal,
      );

  String textOf(WidgetTester tester, int row) => tester
      .widget<TextField>(find.byType(TextField).at(row))
      .controller!
      .text;

  testWidgets('a saved iron goal of 12.5 reopens as "12.5"', (tester) async {
    await openScreen(tester, _FakeSettingsBloc(storedWith(ironGoal: 12.5)));

    expect(textOf(tester, _iron), '12.5');
  });

  // The default is a whole number; it should not drag a cosmetic ".0" into
  // the field just because the formatter now understands fractions.
  testWidgets('a saved iron goal of 13 reopens as "13"', (tester) async {
    await openScreen(tester, _FakeSettingsBloc(storedWith(ironGoal: 13)));

    expect(textOf(tester, _iron), '13');
  });

  testWidgets('a saved magnesium goal of 310.5 reopens as "310.5"', (
    tester,
  ) async {
    await openScreen(
      tester,
      _FakeSettingsBloc(storedWith(magnesiumGoal: 310.5)),
    );

    expect(textOf(tester, _magnesium), '310.5');
  });
}
