import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/domain/entity/intake_entity.dart';
import 'package:opennutritracker/core/domain/usecase/explode_recipe_intake_usecase.dart';
import 'package:opennutritracker/core/presentation/widgets/intake_card.dart';
import 'package:opennutritracker/core/utils/locator.dart';
import 'package:opennutritracker/core/domain/entity/intake_type_entity.dart';
import 'package:opennutritracker/core/domain/entity/recipe_entity.dart';
import 'package:opennutritracker/core/domain/entity/recipe_ingredient_entity.dart';
import 'package:opennutritracker/core/utils/energy_unit_provider.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_nutriments_entity.dart';
import 'package:opennutritracker/features/home/presentation/widgets/explodable_intake_row.dart';
import 'package:opennutritracker/generated/l10n.dart';
import 'package:provider/provider.dart';
import 'package:opennutritracker/features/home/presentation/widgets/recipe_swipe_scope.dart';

IntakeEntity _recipeIntake({
  bool old = false,
  String id = 'intake-1',
  bool recipe = true,
}) {
  const nutrients = MealNutrimentsEntity(
    energyKcal100: 100,
    carbohydrates100: 10,
    fat100: 2,
    proteins100: 3,
    sugars100: null,
    saturatedFat100: null,
    fiber100: null,
  );
  const ingredient = MealEntity(
    code: 'oats',
    name: 'Oats',
    brands: null,
    thumbnailImageUrl: null,
    mainImageUrl: null,
    url: null,
    mealQuantity: '100',
    mealUnit: 'g',
    servingQuantity: null,
    servingUnit: null,
    servingSize: null,
    nutriments: nutrients,
    source: MealSourceEntity.custom,
  );
  final snapshot = RecipeEntity(
    id: 'recipe-1',
    name: 'Morning oats',
    description: null,
    ingredients: const [
      RecipeIngredientEntity(
        snapshotMeal: ingredient,
        amount: 100,
        unit: 'g',
        convertedAmountG: 100,
      ),
    ],
    totalWeightG: 100,
    aggregatedNutrimentsPer100: nutrients,
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
    servingsCount: null,
  );
  return IntakeEntity(
    id: id,
    unit: 'g',
    amount: 100,
    type: IntakeTypeEntity.breakfast,
    meal: recipe ? snapshot.toMealEntity() : ingredient,
    dateTime: DateTime(2026, 9, 26, 8),
    recipeSnapshot: old || !recipe ? null : snapshot,
  );
}

Widget _app(
  IntakeEntity intake,
  VoidCallback onDaySwipe, {
  List<IntakeEntity> others = const [],
  VoidCallback? onTap,
  VoidCallback? onOutsideTap,
  bool active = true,
  bool reducedMotion = false,
  GlobalKey<NavigatorState>? navigatorKey,
}) => ChangeNotifierProvider(
  create: (_) => EnergyUnitProvider(),
  child: MaterialApp(
    navigatorKey: navigatorKey,
    localizationsDelegates: const [S.delegate],
    supportedLocales: S.supportedLocales,
    home: MediaQuery(
      data: MediaQueryData(disableAnimations: reducedMotion),
      child: Scaffold(
        body: RecipeSwipeScope(
          active: active,
          child: GestureDetector(
            onHorizontalDragEnd: (_) => onDaySwipe(),
            child: ListView(
              children: [
                for (final entry in [intake, ...others])
                  Column(
                    key: ValueKey('section-${entry.id}'),
                    children: [
                      ExplodableIntakeRow(
                        key: ValueKey(entry.id),
                        intake: entry,
                        usesImperialUnits: false,
                        onItemTapped: (_, _, _) => onTap?.call(),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                TextButton(
                  key: const ValueKey('outside'),
                  onPressed: onOutsideTap ?? () {},
                  child: const Text('Outside'),
                ),
                Container(
                  key: const ValueKey('day-swipe'),
                  height: 1000,
                  color: Colors.white,
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  ),
);

Finder _row([String id = 'intake-1']) => find.byKey(ValueKey(id));
Finder _card([String id = 'intake-1']) =>
    find.descendant(of: _row(id), matching: find.byType(IntakeCard));
Finder _action([String id = 'intake-1']) =>
    find.descendant(of: _row(id), matching: find.text('Explode'));

Future<void> _open(WidgetTester tester, [String id = 'intake-1']) async {
  await tester.drag(_card(id), const Offset(-140, 0));
  await tester.pumpAndSettle();
}

class _FailingExplode extends Fake implements ExplodeRecipeIntakeUsecase {
  @override
  Future<void> explode(String intakeId) async =>
      throw StateError('disk failure');
}

void main() {
  testWidgets('row swipe wins over diary day swipe and opens confirmation', (
    tester,
  ) async {
    var daySwipes = 0;
    await tester.pumpWidget(_app(_recipeIntake(), () => daySwipes++));
    await tester.pumpAndSettle();

    await tester.drag(find.text('Morning oats'), const Offset(-140, 0));
    await tester.pumpAndSettle();
    expect(daySwipes, 0);
    expect(find.text('Explode'), findsOneWidget);

    await tester.tap(find.text('Explode'));
    await tester.pumpAndSettle();
    expect(find.text('Explode recipe?'), findsOneWidget);
    expect(
      find.text(
        'This replaces the recipe row with editable ingredients and '
        'cannot be undone.',
      ),
      findsOneWidget,
    );
    expect(find.text('Oats'), findsNothing);
    await tester.tap(find.text('CANCEL'));
    await tester.pumpAndSettle();
    expect(find.text('Morning oats'), findsOneWidget);
    expect(tester.getTopLeft(_card()).dx, 0);
  });

  testWidgets('old entry explains why Explode is unavailable', (tester) async {
    await tester.pumpWidget(_app(_recipeIntake(old: true), () {}));
    await tester.pumpAndSettle();

    await tester.drag(find.text('Morning oats'), const Offset(-140, 0));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Explode'));
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(_card()).dx, 0);

    expect(
      find.text(
        'This older entry has no saved ingredients. '
        'Log the recipe again to use Explode.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('settles smoothly, stays open, and reverses or cancels a drag', (
    tester,
  ) async {
    await tester.pumpWidget(_app(_recipeIntake(), () {}));
    await tester.pumpAndSettle();
    final start = tester.getCenter(_card());
    final drag = await tester.startGesture(start);
    await drag.moveBy(const Offset(-25, 0));
    await drag.moveBy(const Offset(-25, 0));
    await tester.pump(const Duration(milliseconds: 300));
    await drag.up();
    await tester.pump();
    final before = tester.getTopLeft(_card()).dx;
    await tester.pump(const Duration(milliseconds: 20));
    final during = tester.getTopLeft(_card()).dx;
    expect(before, lessThan(during));
    expect(during, lessThan(0));
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(_card()).dx, 0);

    await _open(tester);
    final opened = tester.getTopLeft(_card()).dx;
    expect(opened, lessThan(0));
    await tester.pump(const Duration(seconds: 10));
    expect(tester.getTopLeft(_card()).dx, opened);
    await tester.drag(_card(), const Offset(140, 0));
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(_card()).dx, 0);

    final cancelled = await tester.startGesture(start);
    await cancelled.moveBy(const Offset(-80, 0));
    await cancelled.moveBy(const Offset(-30, 0));
    await cancelled.cancel();
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(_card()).dx, 0);
  });

  testWidgets('card tap closes first and navigates on the next tap', (
    tester,
  ) async {
    var taps = 0;
    await tester.pumpWidget(_app(_recipeIntake(), () {}, onTap: () => taps++));
    await _open(tester);
    await tester.tap(_card());
    await tester.pumpAndSettle();
    expect(taps, 0);
    expect(tester.getTopLeft(_card()).dx, 0);
    await tester.tap(_card());
    expect(taps, 1);
  });

  testWidgets('outside tap closes and still activates the outside control', (
    tester,
  ) async {
    var taps = 0;
    await tester.pumpWidget(
      _app(_recipeIntake(), () {}, onOutsideTap: () => taps++),
    );
    await _open(tester);
    await tester.tap(find.byKey(const ValueKey('outside')));
    await tester.pumpAndSettle();
    expect(taps, 1);
    expect(tester.getTopLeft(_card()).dx, 0);
  });

  testWidgets('scroll starting on the open card closes it', (tester) async {
    await tester.pumpWidget(_app(_recipeIntake(), () {}));
    await _open(tester);
    await tester.drag(_card(), const Offset(0, -40));
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(_card()).dx, 0);
  });

  testWidgets('only one recipe opens across sections', (tester) async {
    await tester.pumpWidget(
      _app(_recipeIntake(), () {}, others: [_recipeIntake(id: 'second')]),
    );
    await _open(tester);
    await _open(tester, 'second');
    expect(tester.getTopLeft(_card()).dx, 0);
    expect(tester.getTopLeft(_card('second')).dx, lessThan(0));
  });

  testWidgets('hidden action is absent from semantics and cannot be tapped', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(_app(_recipeIntake(), () {}));
    await tester.pumpAndSettle();
    expect(
      find.semantics.byPredicate(
        (node) => node.getSemanticsData().identifier == 'explode-recipe-action',
      ),
      findsNothing,
    );
    await tester.tapAt(tester.getCenter(_action()));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
    await _open(tester);
    expect(
      find.semantics.byPredicate(
        (node) => node.getSemanticsData().identifier == 'explode-recipe-action',
      ),
      findsOneWidget,
    );
    await tester.tap(_card());
    await tester.pumpAndSettle();
    expect(
      find.semantics.byPredicate(
        (node) => node.getSemanticsData().identifier == 'explode-recipe-action',
      ),
      findsNothing,
    );
    semantics.dispose();
  });

  testWidgets('dismissal and failure leave the row closed', (tester) async {
    await tester.pumpWidget(_app(_recipeIntake(), () {}));
    await _open(tester);
    await tester.tap(_action());
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
    expect(tester.getTopLeft(_card()).dx, 0);

    locator.registerSingleton<ExplodeRecipeIntakeUsecase>(_FailingExplode());
    addTearDown(() => locator.reset());
    await _open(tester);
    await tester.tap(_action());
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Explode'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Could not finish exploding'), findsOneWidget);
    expect(tester.getTopLeft(_card()).dx, 0);
  });

  testWidgets('outside and non-recipe swipes retain day navigation', (
    tester,
  ) async {
    var days = 0;
    var taps = 0;
    await tester.pumpWidget(
      _app(_recipeIntake(recipe: false), () => days++, onTap: () => taps++),
    );
    await tester.drag(_card(), const Offset(-140, 0));
    await tester.pumpAndSettle();
    expect(days, 1);
    expect(find.text('Explode'), findsNothing);
    await tester.tap(_card());
    expect(taps, 1);
    await tester.dragFrom(const Offset(300, 350), const Offset(-140, 0));
    expect(days, 2);
  });

  testWidgets('tab changes, navigation and replaced intakes reset the row', (
    tester,
  ) async {
    final navigator = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      _app(_recipeIntake(), () {}, navigatorKey: navigator),
    );
    await _open(tester);
    navigator.currentState!.push(
      MaterialPageRoute<void>(
        builder: (_) => const Scaffold(body: Text('Details')),
      ),
    );
    await tester.pumpAndSettle();
    navigator.currentState!.pop();
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(_card()).dx, 0);
    await _open(tester);
    await tester.pumpWidget(
      _app(_recipeIntake(), () {}, active: false, navigatorKey: navigator),
    );
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(_card()).dx, 0);
    await tester.pumpWidget(
      _app(_recipeIntake(), () {}, navigatorKey: navigator),
    );
    await _open(tester);
    await tester.pumpWidget(
      _app(_recipeIntake(id: 'new-day'), () {}, navigatorKey: navigator),
    );
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(_card('new-day')).dx, 0);
  });

  testWidgets(
    'reduced motion closes immediately; disposal during settling is safe',
    (tester) async {
      await tester.pumpWidget(
        _app(_recipeIntake(), () {}, reducedMotion: true),
      );
      await _open(tester);
      await tester.tap(_card());
      await tester.pump();
      expect(tester.getTopLeft(_card()).dx, 0);
      await tester.pumpWidget(_app(_recipeIntake(), () {}));
      await _open(tester);
      await tester.tap(_card());
      await tester.pump(const Duration(milliseconds: 20));
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );
}
