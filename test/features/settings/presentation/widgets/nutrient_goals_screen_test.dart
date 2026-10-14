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

  @override
  Future<TrackedDayEntity?> getTodayTrackedDay(DateTime day) async => null;

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
  }) async {
    setNutrientGoalsCalls++;
    savedFibre = fibreGoal;
    savedIron = ironGoal;
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
  // #1347: typing a value and tapping Save without the keyboard's Done key
  // used to drop the typed value, saving nothing for an untouched slider.
  testWidgets('saves typed nutrient goals when Save is tapped without Done', (
    tester,
  ) async {
    // Tall enough for the ListView to build every row, iron included.
    await tester.binding.setSurfaceSize(const Size(400, 3000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final settingsBloc = _FakeSettingsBloc();
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
}
