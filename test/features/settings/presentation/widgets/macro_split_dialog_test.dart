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
  testWidgets('saves typed macro values even without submitting the field', (
    tester,
  ) async {
    final settingsBloc = _FakeSettingsBloc();
    final homeBloc = _FakeHomeBloc();

    await tester.pumpWidget(
      _wrap(
        Builder(
          builder: (context) {
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
          },
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    final fields = find.byType(TextField);
    await tester.enterText(fields.first, '50');

    await tester.tap(find.text(l10nEn.dialogOKLabel));
    await tester.pumpAndSettle();

    // 50 / residual 50 split 15:25 → 18.75 / 31.25. Largest-remainder
    // floors to 50/18/31 then awards the leftover point to protein → 50/19/31.
    expect(settingsBloc.savedCarbs, 50);
    expect(settingsBloc.savedProtein, 19);
    expect(settingsBloc.savedFat, 31);
    expect(
      (settingsBloc.savedCarbs ?? 0) +
          (settingsBloc.savedProtein ?? 0) +
          (settingsBloc.savedFat ?? 0),
      100,
    );
  });

  testWidgets('ignores invalid typed macro values on save', (tester) async {
    final settingsBloc = _FakeSettingsBloc();
    final homeBloc = _FakeHomeBloc();

    await tester.pumpWidget(
      _wrap(
        Builder(
          builder: (context) {
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
          },
        ),
      ),
    );

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

  testWidgets(
    'saves typed value from a non-first field and rebalances the rest',
    (tester) async {
      final settingsBloc = _FakeSettingsBloc();
      final homeBloc = _FakeHomeBloc();

      await tester.pumpWidget(
        _wrap(
          Builder(
            builder: (context) {
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
            },
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // Second field is protein; typing here exercises the otherA/otherB wiring
      // that differs per macro, guarding against a copy-paste mistake.
      final fields = find.byType(TextField);
      await tester.enterText(fields.at(1), '25');

      await tester.tap(find.text(l10nEn.dialogOKLabel));
      await tester.pumpAndSettle();

      // protein 25 / residual 75 split 60:25 → ~52.941 / ~22.059. Floors
      // 52/25/22, leftover goes to carbs → 53/25/22.
      expect(settingsBloc.savedProtein, 25);
      expect(settingsBloc.savedCarbs, 53);
      expect(settingsBloc.savedFat, 22);
      expect(
        (settingsBloc.savedCarbs ?? 0) +
            (settingsBloc.savedProtein ?? 0) +
            (settingsBloc.savedFat ?? 0),
        100,
      );
    },
  );

  test('roundMacroPercentsToHundred always sums to 100', () {
    // Typical redistribute leftovers.
    expect(roundMacroPercentsToHundred(50, 18.75, 31.25), (50, 19, 31));
    expect(roundMacroPercentsToHundred(52.941, 25, 22.059), (53, 25, 22));

    // Independent .round() on 55/22.5/22.5 is 55+23+23=101 (Dart half-away-
    // from-zero); largest-remainder must still land on 100.
    final halfUp = roundMacroPercentsToHundred(55, 22.5, 22.5);
    expect(halfUp.$1 + halfUp.$2 + halfUp.$3, 100);
    expect(halfUp, (55, 23, 22));

    // Already-integers and the defaults.
    expect(roundMacroPercentsToHundred(60, 15, 25), (60, 15, 25));
    expect(roundMacroPercentsToHundred(0, 0, 0), (60, 15, 25));
  });
}
