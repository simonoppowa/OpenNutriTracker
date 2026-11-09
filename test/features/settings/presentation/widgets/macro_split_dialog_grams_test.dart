import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/utils/calc/macro_calc.dart';
import 'package:opennutritracker/core/utils/energy_unit_provider.dart';
import 'package:opennutritracker/core/utils/locator.dart';
import 'package:opennutritracker/features/home/presentation/bloc/home_bloc.dart';
import 'package:opennutritracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:opennutritracker/features/settings/presentation/widgets/macro_split_dialog.dart';
import 'package:opennutritracker/generated/l10n.dart';
import 'package:provider/provider.dart';

import '../../../../helpers/fake_reload_blocs.dart';
import '../../../../helpers/test_l10n.dart';

class _FakeSettingsBloc extends Fake implements SettingsBloc {
  _FakeSettingsBloc({this.inGrams = false, this.grams});

  final bool inGrams;
  final MacroGrams? grams;

  MacroGrams? savedGrams;
  List<double>? savedPct;
  int trackedDayUpdates = 0;

  @override
  Future<double?> getUserCarbGoalPct() async => 0.6;

  @override
  Future<double?> getUserProteinGoalPct() async => 0.15;

  @override
  Future<double?> getUserFatGoalPct() async => 0.25;

  @override
  Future<({bool inGrams, MacroGrams? grams})> getMacroGramGoals() async =>
      (inGrams: inGrams, grams: grams);

  @override
  Future<double> getKcalGoalWithoutActivities() async => 2000;

  @override
  Future<void> setMacroGoals(
    double carbGoalPct,
    double proteinGoalPct,
    double fatGoalPct,
  ) async {
    savedPct = [carbGoalPct, proteinGoalPct, fatGoalPct];
  }

  @override
  Future<void> setMacroGramGoals(
    double carbGrams,
    double proteinGrams,
    double fatGrams,
  ) async {
    savedGrams = (carbs: carbGrams, protein: proteinGrams, fat: fatGrams);
  }

  @override
  Future<DateTime> getCurrentLogicalDay() async => DateTime(2026, 11, 8);

  @override
  Future<void> updateTrackedDay(DateTime day) async => trackedDayUpdates++;

  @override
  void add(SettingsEvent event) {}
}

class _FakeHomeBloc extends Fake implements HomeBloc {
  @override
  void add(HomeEvent event) {}
}

/// Absolute macro goals in the macro dialog (#642).
void main() {
  setUp(() => ReloadRecorder().register());
  tearDown(() async => locator.reset());

  Future<void> open(
    WidgetTester tester,
    _FakeSettingsBloc bloc, {
    bool usesKj = false,
  }) async {
    final energy = EnergyUnitProvider(usesKilojoules: usesKj);
    await tester.pumpWidget(
      ChangeNotifierProvider<EnergyUnitProvider>.value(
        value: energy,
        child: MaterialApp(
          localizationsDelegates: const [S.delegate],
          supportedLocales: S.supportedLocales,
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (_) => MacroSplitDialog(
                    settingsBloc: bloc,
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

  Finder gramField(String id) => find.descendant(
    of: find.bySemanticsIdentifier(id),
    matching: find.byType(TextField),
  );

  String text(WidgetTester tester, String id) =>
      tester.widget<TextField>(gramField(id)).controller!.text;

  Future<void> switchToGrams(WidgetTester tester) async {
    await tester.tap(find.text(l10nEn.macroGoalModeGramsLabel));
    await tester.pumpAndSettle();
  }

  Future<void> save(WidgetTester tester) async {
    await tester.tap(find.text(l10nEn.dialogOKLabel));
    await tester.pumpAndSettle();
  }

  testWidgets('switching to grams starts at the split of today\'s goal and '
      'hides the sliders', (tester) async {
    await open(tester, _FakeSettingsBloc());
    expect(find.byType(Slider), findsNWidgets(3));

    await switchToGrams(tester);

    expect(find.byType(Slider), findsNothing);
    expect(text(tester, 'macro-split-carbs-grams'), '300');
    expect(text(tester, 'macro-split-protein-grams'), '75');
    expect(text(tester, 'macro-split-fat-grams'), '56');
    expect(find.text(l10nEn.buttonResetLabel), findsNothing);
  });

  testWidgets('saves typed gram goals as they are, without rebalancing', (
    tester,
  ) async {
    final bloc = _FakeSettingsBloc();
    await open(tester, bloc);
    await switchToGrams(tester);

    await tester.enterText(gramField('macro-split-carbs-grams'), '20');
    await tester.enterText(gramField('macro-split-protein-grams'), '120');
    await tester.enterText(gramField('macro-split-fat-grams'), '140');
    await save(tester);

    expect(bloc.savedGrams, (carbs: 20.0, protein: 120.0, fat: 140.0));
    expect(bloc.savedPct, isNull);
    expect(bloc.trackedDayUpdates, 1);
    expect(find.byType(MacroSplitDialog), findsNothing);
  });

  testWidgets('says what the grams add up to next to the calorie goal', (
    tester,
  ) async {
    await open(tester, _FakeSettingsBloc());
    await switchToGrams(tester);

    await tester.enterText(gramField('macro-split-carbs-grams'), '20');
    await tester.enterText(gramField('macro-split-protein-grams'), '120');
    await tester.enterText(gramField('macro-split-fat-grams'), '140');
    await tester.pump();

    // 20 × 4 + 120 × 4 + 140 × 9 = 1820, which doesn't match 2000: shown,
    // not blocked.
    expect(
      find.text(l10nEn.macroGoalGramsEnergySum('1820', '2000', 'kcal')),
      findsOneWidget,
    );
  });

  testWidgets('the energy line uses kJ when the app does', (tester) async {
    await open(
      tester,
      _FakeSettingsBloc(
        inGrams: true,
        grams: (carbs: 20, protein: 120, fat: 140),
      ),
      usesKj: true,
    );

    // 1820 kcal = 7615 kJ, 2000 kcal = 8368 kJ.
    expect(
      find.text(l10nEn.macroGoalGramsEnergySum('7615', '8368', 'kJ')),
      findsOneWidget,
    );
  });

  testWidgets('an emptied field snaps back to its last value on save', (
    tester,
  ) async {
    final bloc = _FakeSettingsBloc(
      inGrams: true,
      grams: (carbs: 20, protein: 120, fat: 140),
    );
    await open(tester, bloc);
    expect(text(tester, 'macro-split-carbs-grams'), '20');

    await tester.enterText(gramField('macro-split-carbs-grams'), '');
    await save(tester);

    expect(bloc.savedGrams, (carbs: 20.0, protein: 120.0, fat: 140.0));
  });

  testWidgets('a value over the maximum is clamped to it', (tester) async {
    final bloc = _FakeSettingsBloc(
      inGrams: true,
      grams: (carbs: 20, protein: 120, fat: 140),
    );
    await open(tester, bloc);

    await tester.enterText(gramField('macro-split-protein-grams'), '5000');
    await save(tester);

    expect(bloc.savedGrams?.protein, MacroGramGoals.maxGrams);
  });

  testWidgets('all three at 0 g disables OK and says why', (tester) async {
    final bloc = _FakeSettingsBloc(
      inGrams: true,
      grams: (carbs: 20, protein: 120, fat: 140),
    );
    await open(tester, bloc);

    for (final id in [
      'macro-split-carbs-grams',
      'macro-split-protein-grams',
      'macro-split-fat-grams',
    ]) {
      await tester.enterText(gramField(id), '0');
    }
    await tester.pump();

    expect(find.text(l10nEn.macroGoalGramsAllZero), findsOneWidget);
    final ok = tester.widget<TextButton>(
      find.ancestor(
        of: find.text(l10nEn.dialogOKLabel),
        matching: find.byType(TextButton),
      ),
    );
    expect(ok.onPressed, isNull);
    expect(bloc.savedGrams, isNull);
  });

  testWidgets('0 g carbs on its own is a valid keto goal', (tester) async {
    final bloc = _FakeSettingsBloc(
      inGrams: true,
      grams: (carbs: 20, protein: 120, fat: 140),
    );
    await open(tester, bloc);

    await tester.enterText(gramField('macro-split-carbs-grams'), '0');
    await save(tester);

    expect(bloc.savedGrams, (carbs: 0.0, protein: 120.0, fat: 140.0));
  });

  testWidgets('switching back to percent and saving stores the split, which '
      'turns gram goals off', (tester) async {
    final bloc = _FakeSettingsBloc(
      inGrams: true,
      grams: (carbs: 20, protein: 120, fat: 140),
    );
    await open(tester, bloc);
    expect(find.byType(Slider), findsNothing);

    await tester.tap(find.text(l10nEn.macroGoalModePercentLabel));
    await tester.pumpAndSettle();
    expect(find.byType(Slider), findsNWidgets(3));
    await save(tester);

    expect(bloc.savedPct, [60, 15, 25]);
    expect(bloc.savedGrams, isNull);
  });

  testWidgets('stored grams are kept across a switch to percent and back', (
    tester,
  ) async {
    await open(
      tester,
      _FakeSettingsBloc(grams: (carbs: 20, protein: 120, fat: 140)),
    );

    await switchToGrams(tester);

    expect(text(tester, 'macro-split-carbs-grams'), '20');
    expect(text(tester, 'macro-split-fat-grams'), '140');
  });

  testWidgets('each gram field is named for screen readers', (tester) async {
    final semantics = tester.ensureSemantics();
    await open(tester, _FakeSettingsBloc());
    await switchToGrams(tester);

    for (final (id, label) in [
      ('macro-split-carbs-grams', l10nEn.carbsLabel),
      ('macro-split-protein-grams', l10nEn.proteinLabel),
      ('macro-split-fat-grams', l10nEn.fatLabel),
    ]) {
      final data = tester.getSemantics(gramField(id)).getSemanticsData();
      expect(data.label, contains(label), reason: id);
      expect(data.flagsCollection.isTextField, isTrue, reason: id);
    }
    semantics.dispose();
  });

  testWidgets('cancel saves nothing', (tester) async {
    final bloc = _FakeSettingsBloc();
    await open(tester, bloc);
    await switchToGrams(tester);
    await tester.enterText(gramField('macro-split-carbs-grams'), '20');

    await tester.tap(find.text(l10nEn.dialogCancelLabel));
    await tester.pumpAndSettle();

    expect(bloc.savedGrams, isNull);
    expect(bloc.savedPct, isNull);
  });
}
