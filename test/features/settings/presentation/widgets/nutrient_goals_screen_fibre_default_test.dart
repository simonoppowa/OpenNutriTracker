import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/domain/entity/tracked_day_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_gender_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_pal_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_weight_goal_entity.dart';
import 'package:opennutritracker/features/diary/presentation/bloc/calendar_day_bloc.dart';
import 'package:opennutritracker/features/diary/presentation/bloc/diary_bloc.dart';
import 'package:opennutritracker/features/home/presentation/bloc/home_bloc.dart';
import 'package:opennutritracker/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:opennutritracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:opennutritracker/features/settings/presentation/widgets/nutrient_goals_screen.dart';
import 'package:opennutritracker/generated/l10n.dart';

// #1365: with no fibre goal set, Settings -> Nutrient goals must open at
// the same fibre reference the Diary panel applies (the IOM value for the
// user's age and gender), not a flat 30 g.

class _FakeSettingsBloc extends Fake implements SettingsBloc {
  TrackedDayEntity? today;

  @override
  Future<TrackedDayEntity?> getTodayTrackedDay(DateTime day) async => today;

  @override
  void add(SettingsEvent event) {}
}

class _FakeProfileBloc extends Fake implements ProfileBloc {
  final UserEntity user;

  _FakeProfileBloc(this.user);

  @override
  Future<UserEntity> getUser() async => user;
}

class _FakeHomeBloc extends Fake implements HomeBloc {}

class _FakeDiaryBloc extends Fake implements DiaryBloc {}

class _FakeCalendarDayBloc extends Fake implements CalendarDayBloc {}

UserEntity _user(int age, UserGenderEntity gender) {
  final now = DateTime.now();
  return UserEntity(
    birthday: DateTime(now.year - age, now.month, now.day),
    heightCM: 165,
    weightKG: 60,
    gender: gender,
    goal: UserWeightGoalEntity.maintainWeight,
    pal: UserPALEntity.sedentary,
  );
}

Future<void> _open(
  WidgetTester tester, {
  required UserEntity user,
  TrackedDayEntity? today,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: const [S.delegate],
      supportedLocales: S.supportedLocales,
      home: NutrientGoalsScreen(
        settingsBloc: _FakeSettingsBloc()..today = today,
        profileBloc: _FakeProfileBloc(user),
        diaryBloc: _FakeDiaryBloc(),
        calendarDayBloc: _FakeCalendarDayBloc(),
        homeBloc: _FakeHomeBloc(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// Fibre is the first row: its text field and slider come first.
String _fibreText(WidgetTester tester) =>
    tester.widget<TextField>(find.byType(TextField).first).controller!.text;

double _fibreSlider(WidgetTester tester) =>
    tester.widget<Slider>(find.byType(Slider).first).value;

void main() {
  testWidgets('a 30-year-old woman with no goal opens at 25 g', (tester) async {
    await _open(tester, user: _user(30, UserGenderEntity.female));

    expect(_fibreText(tester), '25');
    expect(_fibreSlider(tester), 25);
  });

  testWidgets('a 40-year-old man with no goal opens at 38 g', (tester) async {
    await _open(tester, user: _user(40, UserGenderEntity.male));

    expect(_fibreText(tester), '38');
    expect(_fibreSlider(tester), 38);
  });

  // The averaged non-binary reference is the midpoint of the binary rows,
  // so it can be fractional. The field must show it as-is, not rounded
  // away from the slider (Codex review on #1380).
  testWidgets('a 30-year-old non-binary user opens at 31.5 g', (tester) async {
    await _open(tester, user: _user(30, UserGenderEntity.nonBinary));

    expect(_fibreText(tester), '31.5');
    expect(_fibreSlider(tester), 31.5);
  });

  testWidgets('a 60-year-old non-binary user opens at 25.5 g', (tester) async {
    await _open(tester, user: _user(60, UserGenderEntity.nonBinary));

    expect(_fibreText(tester), '25.5');
    expect(_fibreSlider(tester), 25.5);
  });

  testWidgets('submitting the untouched fractional default keeps 31.5 g', (
    tester,
  ) async {
    await _open(tester, user: _user(30, UserGenderEntity.nonBinary));

    await tester.tap(find.byType(TextField).first);
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(_fibreText(tester), '31.5');
    expect(_fibreSlider(tester), 31.5);
  });

  testWidgets('a saved fibre goal still wins over the default', (tester) async {
    await _open(
      tester,
      user: _user(30, UserGenderEntity.female),
      today: TrackedDayEntity(
        day: DateTime.now(),
        calorieGoal: 2000,
        caloriesTracked: 0,
        fibreGoal: 40,
      ),
    );

    expect(_fibreText(tester), '40');
    expect(_fibreSlider(tester), 40);
  });
}
