import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/domain/entity/user_entity.dart';
import 'package:opennutritracker/core/utils/bounds/ranges_const.dart';
import 'package:opennutritracker/core/utils/calc/calorie_goal_calc.dart';
import 'package:opennutritracker/core/utils/energy_unit_provider.dart';
import 'package:opennutritracker/core/utils/locator.dart';
import 'package:opennutritracker/features/home/presentation/bloc/home_bloc.dart';
import 'package:opennutritracker/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:opennutritracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:opennutritracker/features/settings/presentation/widgets/kcal_adjustment_dialog.dart';
import 'package:opennutritracker/generated/l10n.dart';
import 'package:provider/provider.dart';

import '../../../../fixture/user_entity_fixtures.dart';
import '../../../../helpers/fake_reload_blocs.dart';
import '../../../../helpers/test_l10n.dart';

final _user = UserEntityFixtures.middleAgedActiveFemaleWantingToLoseWeight;

class _FakeSettingsBloc extends Fake implements SettingsBloc {
  double storedAdjustment = 0;
  double? storedFixedGoal;

  final List<double> savedAdjustments = [];
  final List<double?> savedFixedGoals = [];

  @override
  Future<double> getKcalAdjustment() async => storedAdjustment;

  @override
  Future<double?> getFixedKcalGoal() async => storedFixedGoal;

  @override
  Future<void> setKcalAdjustment(double kcalAdjustment) async {
    savedAdjustments.add(kcalAdjustment);
  }

  @override
  Future<void> setFixedKcalGoal(double? kcal) async {
    savedFixedGoals.add(kcal);
  }

  @override
  Future<DateTime> getCurrentLogicalDay() async => DateTime(2026, 10, 10);

  @override
  Future<void> updateTrackedDay(DateTime day) async {}

  @override
  void add(SettingsEvent event) {}
}

class _FakeProfileBloc extends Fake implements ProfileBloc {
  @override
  Future<UserEntity> getUser() async => _user;
}

class _FakeHomeBloc extends Fake implements HomeBloc {
  @override
  void add(HomeEvent event) {}
}

/// #671: the goal dialog sets either the calculated goal's offset or a fixed
/// daily goal that replaces the calculation.
void main() {
  late _FakeSettingsBloc settingsBloc;

  setUp(() {
    settingsBloc = _FakeSettingsBloc();
    ReloadRecorder().register();
  });

  tearDown(() async => locator.reset());

  Future<void> openDialog(
    WidgetTester tester, {
    bool usesKilojoules = false,
  }) async {
    await tester.pumpWidget(
      ChangeNotifierProvider<EnergyUnitProvider>(
        create: (_) => EnergyUnitProvider(usesKilojoules: usesKilojoules),
        child: MaterialApp(
          localizationsDelegates: const [S.delegate],
          supportedLocales: S.supportedLocales,
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (_) => KcalAdjustmentDialog(
                    settingsBloc: settingsBloc,
                    profileBloc: _FakeProfileBloc(),
                    homeBloc: _FakeHomeBloc(),
                  ),
                ),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
  }

  Future<void> chooseFixed(WidgetTester tester) async {
    await tester.tap(find.text(l10nEn.kcalGoalModeFixedLabel));
    await tester.pumpAndSettle();
  }

  Future<void> tapOk(WidgetTester tester) async {
    await tester.tap(find.text(l10nEn.dialogOKLabel));
    await tester.pumpAndSettle();
  }

  String fieldText(WidgetTester tester) =>
      tester.widget<TextField>(find.byType(TextField)).controller!.text;

  testWidgets('opens on the calculated goal when no fixed goal is set', (
    tester,
  ) async {
    await openDialog(tester);

    expect(find.byType(Slider), findsOneWidget);
    expect(
      find.bySemanticsIdentifier('kcal-goal-mode'),
      findsOneWidget,
      reason: 'the mode switch has a test handle',
    );

    await tapOk(tester);
    expect(settingsBloc.savedFixedGoals, [null]);
    expect(settingsBloc.savedAdjustments, [0]);
  });

  testWidgets('switching to fixed starts from the calculated goal and saves '
      'the typed value', (tester) async {
    settingsBloc.storedAdjustment = -100;
    await openDialog(tester);

    await chooseFixed(tester);

    expect(find.byType(Slider), findsNothing);
    expect(find.bySemanticsIdentifier('kcal-goal-fixed-input'), findsOneWidget);
    final calculated = CalorieGoalCalc.getTotalKcalGoal(
      _user,
      0,
      kcalUserAdjustment: -100,
    ).round();
    expect(fieldText(tester), '$calculated');

    await tester.enterText(find.byType(TextField), '1660');
    await tapOk(tester);

    expect(settingsBloc.savedFixedGoals, [1660]);
    expect(
      settingsBloc.savedAdjustments,
      [-100],
      reason: 'the offset is kept for when the user switches back',
    );
    expect(find.byType(KcalAdjustmentDialog), findsNothing);
  });

  testWidgets('opens on a stored fixed goal, and switching back to '
      'calculated clears it', (tester) async {
    settingsBloc
      ..storedFixedGoal = 1800
      ..storedAdjustment = 200;
    await openDialog(tester);

    expect(find.byType(Slider), findsNothing);
    expect(fieldText(tester), '1800');

    await tester.tap(find.text(l10nEn.kcalGoalModeCalculatedLabel));
    await tester.pumpAndSettle();
    expect(find.byType(Slider), findsOneWidget);
    expect(fieldText(tester), '200', reason: 'the offset is back');

    await tapOk(tester);

    expect(settingsBloc.savedFixedGoals, [null]);
    expect(settingsBloc.savedAdjustments, [200]);
  });

  testWidgets('an empty field snaps back to the last good value', (
    tester,
  ) async {
    settingsBloc.storedFixedGoal = 1800;
    await openDialog(tester);

    await tester.enterText(find.byType(TextField), '');
    await tapOk(tester);

    expect(settingsBloc.savedFixedGoals, [1800]);
  });

  testWidgets('a lone minus sign snaps back too', (tester) async {
    settingsBloc.storedFixedGoal = 1800;
    await openDialog(tester);

    await tester.enterText(find.byType(TextField), '-');
    await tapOk(tester);

    expect(settingsBloc.savedFixedGoals, [1800]);
  });

  testWidgets('a value below the range is raised to the minimum', (
    tester,
  ) async {
    settingsBloc.storedFixedGoal = 1800;
    await openDialog(tester);

    await tester.enterText(find.byType(TextField), '100');
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pump();
    expect(fieldText(tester), '${Ranges.minFixedDailyKcalGoal.round()}');

    await tapOk(tester);
    expect(settingsBloc.savedFixedGoals, [Ranges.minFixedDailyKcalGoal]);
  });

  testWidgets('a value above the range is lowered to the maximum', (
    tester,
  ) async {
    settingsBloc.storedFixedGoal = 1800;
    await openDialog(tester);

    await tester.enterText(find.byType(TextField), '99999');
    await tapOk(tester);

    expect(settingsBloc.savedFixedGoals, [Ranges.maxFixedDailyKcalGoal]);
  });

  group('in kJ', () {
    testWidgets('shows a stored fixed goal converted to kJ', (tester) async {
      settingsBloc.storedFixedGoal = 2000;
      await openDialog(tester, usesKilojoules: true);

      // 2000 kcal × 4.184 = 8368 kJ.
      expect(fieldText(tester), '8368');
      expect(find.text(l10nEn.kjLabel), findsOneWidget);
      expect(find.text(l10nEn.settingsKjGoalLabel), findsOneWidget);
    });

    testWidgets('stores a typed kJ goal in kcal', (tester) async {
      settingsBloc.storedFixedGoal = 2000;
      await openDialog(tester, usesKilojoules: true);

      await tester.enterText(find.byType(TextField), '7000');
      await tapOk(tester);

      // 7000 kJ / 4.184 = 1673.04 kcal, stored as a whole number.
      expect(settingsBloc.savedFixedGoals, [1673]);
    });

    testWidgets('keeps a stored goal when OK is tapped unedited', (
      tester,
    ) async {
      // 1999 kcal shows as 8364 kJ, which converts back to 1999.04 kcal.
      settingsBloc.storedFixedGoal = 1999;
      await openDialog(tester, usesKilojoules: true);

      await tapOk(tester);

      expect(settingsBloc.savedFixedGoals, [1999]);
    });

    testWidgets('clamps to the range in kJ', (tester) async {
      settingsBloc.storedFixedGoal = 2000;
      await openDialog(tester, usesKilojoules: true);

      await tester.enterText(find.byType(TextField), '100');
      await tapOk(tester);

      expect(settingsBloc.savedFixedGoals, [Ranges.minFixedDailyKcalGoal]);
    });
  });
}
