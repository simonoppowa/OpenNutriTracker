import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/data/repository/config_repository.dart';
import 'package:opennutritracker/core/data/repository/user_repository.dart';
import 'package:opennutritracker/core/domain/entity/goal_targets.dart';
import 'package:opennutritracker/features/settings/domain/goal_settings_store.dart';
import 'package:opennutritracker/features/settings/presentation/widgets/goals_screen.dart';
import 'package:opennutritracker/generated/l10n.dart';

import '../../../../helpers/test_l10n.dart';

class _FakeStore extends GoalSettingsStore {
  GoalTargets targets;
  ({double carbs, double fat, double protein}) split = (
    carbs: 50,
    fat: 30,
    protein: 20,
  );
  final saved = <GoalTargets>[];
  var splitEdits = 0;

  _FakeStore([this.targets = const GoalTargets()])
    : super(_UnusedConfig(), _UnusedUser(), onSaved: () async {});

  @override
  Future<GoalTargets> loadTargets() async => targets;

  @override
  Future<({double carbs, double fat, double protein})> loadSplit() async =>
      split;

  @override
  Future<double> calculatedKcal() async => 2000;

  Object? saveError;

  @override
  Future<void> save(GoalTargets targets) async {
    if (saveError != null) throw saveError!;
    saved.add(targets);
  }
}

class _UnusedConfig extends Fake implements ConfigRepository {}

class _UnusedUser extends Fake implements UserRepository {}

void main() {
  Future<void> pumpScreen(WidgetTester tester, _FakeStore store) async {
    await tester.binding.setSurfaceSize(const Size(500, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [
          S.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en')],
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => GoalsScreen(
                  store: store,
                  onEditSplit: (_) async {
                    store.splitEdits++;
                    store.split = (carbs: 40, fat: 30, protein: 30);
                  },
                ),
              ),
            ),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  Finder field(String id) => find.descendant(
    of: find.bySemanticsIdentifier(id),
    matching: find.byType(TextField),
  );

  Future<void> save(WidgetTester tester) async {
    await tester.tap(find.bySemanticsIdentifier('goals-save'));
    await tester.pumpAndSettle();
  }

  testWidgets('an existing user sees the calculated goal and the split', (
    tester,
  ) async {
    await pumpScreen(tester, _FakeStore());

    expect(find.text(l10nEn.goalsKcalCalculatedHint(2000)), findsOneWidget);
    expect(find.text('50 % ≈ 250 g'), findsOneWidget);
    expect(find.text('20 % ≈ 100 g'), findsOneWidget);
  });

  testWidgets('a fixed goal is saved, the macros stay as they were', (
    tester,
  ) async {
    final store = _FakeStore();
    await pumpScreen(tester, store);

    await tester.tap(find.text(l10nEn.goalsKcalFixed));
    await tester.pumpAndSettle();
    await tester.enterText(field('goals-kcal-fixed'), '1800');
    await tester.pumpAndSettle();
    expect(find.text('50 % ≈ 225 g'), findsOneWidget);
    await save(tester);

    expect(
      store.saved.single,
      const GoalTargets(kcalMode: KcalGoalMode.fixed, fixedKcal: 1800),
    );
  });

  testWidgets('a fixed goal out of range is refused', (tester) async {
    final store = _FakeStore();
    await pumpScreen(tester, store);

    await tester.tap(find.text(l10nEn.goalsKcalFixed));
    await tester.pumpAndSettle();
    await tester.enterText(field('goals-kcal-fixed'), '300');
    await save(tester);

    expect(find.text(l10nEn.goalsKcalRangeError(800, 10000)), findsOneWidget);
    expect(store.saved, isEmpty);
  });

  testWidgets('switching to grams converts the split and keeps the grams', (
    tester,
  ) async {
    final store = _FakeStore();
    await pumpScreen(tester, store);

    await tester.tap(find.text(l10nEn.goalsMacroGrams));
    await tester.pumpAndSettle();
    expect(
      tester.widget<TextField>(field('goals-carbs-g')).controller!.text,
      '250',
    );
    expect(
      tester.widget<TextField>(field('goals-protein-g')).controller!.text,
      '100',
    );

    await tester.enterText(field('goals-protein-g'), '160');
    await tester.tap(find.text(l10nEn.goalsMacroPercent));
    await tester.pumpAndSettle();
    expect(find.text('50 % ≈ 250 g'), findsOneWidget);
    await tester.tap(find.text(l10nEn.goalsMacroGrams));
    await tester.pumpAndSettle();

    expect(
      tester.widget<TextField>(field('goals-protein-g')).controller!.text,
      '160',
    );
  });

  testWidgets('gram goals are saved and their kcal compared with the goal', (
    tester,
  ) async {
    final store = _FakeStore();
    await pumpScreen(tester, store);

    await tester.tap(find.text(l10nEn.goalsMacroGrams));
    await tester.pumpAndSettle();
    await tester.enterText(field('goals-carbs-g'), '300');
    await tester.enterText(field('goals-fat-g'), '70');
    await tester.enterText(field('goals-protein-g'), '160');
    await tester.pumpAndSettle();

    expect(find.text(l10nEn.goalsGramsKcalHint(2470, 2000)), findsOneWidget);
    await save(tester);

    expect(
      store.saved.single,
      const GoalTargets(
        macroMode: MacroGoalMode.grams,
        carbsG: 300,
        fatG: 70,
        proteinG: 160,
      ),
    );
  });

  testWidgets('grams that fit the goal show no hint', (tester) async {
    await pumpScreen(tester, _FakeStore());

    await tester.tap(find.text(l10nEn.goalsMacroGrams));
    await tester.pumpAndSettle();

    expect(find.textContaining('add up to'), findsNothing);
  });

  testWidgets('a missing gram value is refused', (tester) async {
    final store = _FakeStore();
    await pumpScreen(tester, store);

    await tester.tap(find.text(l10nEn.goalsMacroGrams));
    await tester.pumpAndSettle();
    await tester.enterText(field('goals-fat-g'), '');
    await save(tester);

    expect(find.text(l10nEn.goalsGramsMissing), findsOneWidget);
    expect(store.saved, isEmpty);
  });

  testWidgets('the split is changed in its own dialog and shown again', (
    tester,
  ) async {
    final store = _FakeStore();
    await pumpScreen(tester, store);

    await tester.tap(find.text(l10nEn.goalsSplitEdit));
    await tester.pumpAndSettle();

    expect(store.splitEdits, 1);
    expect(find.text('40 % ≈ 200 g'), findsOneWidget);
  });

  testWidgets('stored targets open in their modes', (tester) async {
    await pumpScreen(
      tester,
      _FakeStore(
        const GoalTargets(
          kcalMode: KcalGoalMode.fixed,
          fixedKcal: 2200,
          macroMode: MacroGoalMode.grams,
          carbsG: 220,
          fatG: 70,
          proteinG: 160,
        ),
      ),
    );

    expect(
      tester.widget<TextField>(field('goals-kcal-fixed')).controller!.text,
      '2200',
    );
    expect(
      tester.widget<TextField>(field('goals-carbs-g')).controller!.text,
      '220',
    );
  });

  testWidgets('a hidden invalid value does not block the save', (tester) async {
    final store = _FakeStore();
    await pumpScreen(tester, store);

    await tester.tap(find.text(l10nEn.goalsKcalFixed));
    await tester.pumpAndSettle();
    await tester.enterText(field('goals-kcal-fixed'), '300');
    await tester.tap(find.text(l10nEn.goalsKcalCalculated));
    await tester.pumpAndSettle();
    await save(tester);

    expect(store.saved.single, const GoalTargets());
  });

  testWidgets('a failed save says so and can be retried', (tester) async {
    final store = _FakeStore()..saveError = StateError('disk full');
    await pumpScreen(tester, store);

    await save(tester);
    expect(find.text(l10nEn.goalsSaveFailed), findsOneWidget);

    store.saveError = null;
    await save(tester);
    expect(store.saved, hasLength(1));
  });
}
