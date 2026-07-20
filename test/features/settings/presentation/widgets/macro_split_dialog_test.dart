import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/features/home/presentation/bloc/home_bloc.dart';
import 'package:opennutritracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:opennutritracker/features/settings/presentation/widgets/macro_split_dialog.dart';
import 'package:opennutritracker/generated/l10n.dart';
import '../../../../helpers/test_l10n.dart';

class _FakeSettingsBloc extends Fake implements SettingsBloc {
  double? savedCarbs;
  double? savedProtein;
  double? savedFat;

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
  ) async {
    savedCarbs = carbGoalPct;
    savedProtein = proteinGoalPct;
    savedFat = fatGoalPct;
  }

  @override
  Future<void> updateTrackedDay(DateTime day) async {}

  @override
  void add(SettingsEvent event) {}
}

class _FakeHomeBloc extends Fake implements HomeBloc {
  @override
  void add(HomeEvent event) {}
}

Widget _wrap(Widget child) {
  return MaterialApp(
    localizationsDelegates: const [S.delegate],
    supportedLocales: S.supportedLocales,
    home: Scaffold(body: child),
  );
}

void main() {
  testWidgets('saves typed macro values even without submitting the field', (tester) async {
    final settingsBloc = _FakeSettingsBloc();
    final homeBloc = _FakeHomeBloc();

    await tester.pumpWidget(_wrap(Builder(builder: (context) {
      return ElevatedButton(
        onPressed: () => showDialog<void>(
          context: context,
          builder: (_) => MacroSplitDialog(
            settingsBloc: settingsBloc,
            homeBloc: homeBloc,
          ),
        ),
        child: const Text('Open'),
      );
    })));

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    final fields = find.byType(TextField);
    await tester.enterText(fields.first, '50');

    await tester.tap(find.text(l10nEn.dialogOKLabel));
    await tester.pumpAndSettle();

    expect(settingsBloc.savedCarbs, 50);
    expect(settingsBloc.savedProtein, closeTo(18.75, 0.001));
    expect(settingsBloc.savedFat, closeTo(31.25, 0.001));
    expect(
      (settingsBloc.savedCarbs ?? 0) +
          (settingsBloc.savedProtein ?? 0) +
          (settingsBloc.savedFat ?? 0),
      closeTo(100, 0.001),
    );
  });

  testWidgets('ignores invalid typed macro values on save', (tester) async {
    final settingsBloc = _FakeSettingsBloc();
    final homeBloc = _FakeHomeBloc();

    await tester.pumpWidget(_wrap(Builder(builder: (context) {
      return ElevatedButton(
        onPressed: () => showDialog<void>(
          context: context,
          builder: (_) => MacroSplitDialog(
            settingsBloc: settingsBloc,
            homeBloc: homeBloc,
          ),
        ),
        child: const Text('Open'),
      );
    })));

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    final fields = find.byType(TextField);
    await tester.enterText(fields.first, '95');

    await tester.tap(find.text(l10nEn.dialogOKLabel));
    await tester.pumpAndSettle();

    expect(settingsBloc.savedCarbs, 60);
    expect(settingsBloc.savedProtein, 15);
    expect(settingsBloc.savedFat, 25);
  });

  testWidgets('saves typed value from a non-first field and rebalances the rest',
      (tester) async {
    final settingsBloc = _FakeSettingsBloc();
    final homeBloc = _FakeHomeBloc();

    await tester.pumpWidget(_wrap(Builder(builder: (context) {
      return ElevatedButton(
        onPressed: () => showDialog<void>(
          context: context,
          builder: (_) => MacroSplitDialog(
            settingsBloc: settingsBloc,
            homeBloc: homeBloc,
          ),
        ),
        child: const Text('Open'),
      );
    })));

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    // Second field is protein; typing here exercises the otherA/otherB wiring
    // that differs per macro, guarding against a copy-paste mistake.
    final fields = find.byType(TextField);
    await tester.enterText(fields.at(1), '25');

    await tester.tap(find.text(l10nEn.dialogOKLabel));
    await tester.pumpAndSettle();

    expect(settingsBloc.savedProtein, 25);
    expect(settingsBloc.savedCarbs, closeTo(52.941, 0.001));
    expect(settingsBloc.savedFat, closeTo(22.059, 0.001));
    expect(
      (settingsBloc.savedCarbs ?? 0) +
          (settingsBloc.savedProtein ?? 0) +
          (settingsBloc.savedFat ?? 0),
      closeTo(100, 0.001),
    );
  });
}
