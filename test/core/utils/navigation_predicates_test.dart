import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/utils/navigation_predicates.dart';

/// Regression cover for the black screen after logging an intake.
///
/// `popUntil(ModalRoute.withName(x))` and `pushNamedAndRemoveUntil(...,
/// ModalRoute.withName(x))` remove *every* route when `x` is not on the
/// stack, leaving an empty navigator that renders as a black screen. Both
/// unwinds can run on a stack that never had the route they name — the
/// scanner reached from the home shortcut has no Add Meal route below it.
void main() {
  /// Pumps a navigator seeded with [routeNames] (first entry is the bottom
  /// route) and hands back its state. Each route renders its own name.
  Future<NavigatorState> pumpStack(
    WidgetTester tester,
    List<String> routeNames,
  ) async {
    final navigatorKey = GlobalKey<NavigatorState>();

    Route<void> routeFor(String name) => MaterialPageRoute<void>(
          settings: RouteSettings(name: name),
          builder: (_) => Scaffold(body: Text(name)),
        );

    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigatorKey,
        initialRoute: routeNames.first,
        onGenerateInitialRoutes: (_) => routeNames.map(routeFor).toList(),
        onGenerateRoute: (settings) => routeFor(settings.name ?? 'unnamed'),
      ),
    );
    await tester.pumpAndSettle();

    return navigatorKey.currentState!;
  }

  group('namedRouteOrFirst with popUntil', () {
    testWidgets('pops back to the named route when it is on the stack',
        (tester) async {
      final navigator =
          await pumpStack(tester, ['main', 'addMeal', 'mealDetail']);

      navigator.popUntil(namedRouteOrFirst('main'));
      await tester.pumpAndSettle();

      expect(find.text('main'), findsOneWidget);
      expect(find.text('mealDetail'), findsNothing);
    });

    testWidgets('stops at the first route when the named one is absent',
        (tester) async {
      // The home shortcut's scanner flow: no addMeal route was ever pushed,
      // and the unwind that wiped `main` left this stack behind.
      final navigator = await pumpStack(tester, ['scanner', 'mealDetail']);

      navigator.popUntil(namedRouteOrFirst('main'));
      await tester.pumpAndSettle();

      // The regression was an empty navigator here — a black screen.
      expect(find.text('scanner'), findsOneWidget);
      expect(navigator.canPop(), isFalse);
    });
  });

  testWidgets('ModalRoute.withName alone empties the stack — the bug',
      (tester) async {
    final navigator = await pumpStack(tester, ['scanner', 'mealDetail']);

    navigator.popUntil(ModalRoute.withName('main'));
    await tester.pumpAndSettle();

    // Nothing left to render: this is what put a black screen on the phone.
    expect(find.text('scanner'), findsNothing);
    expect(find.text('mealDetail'), findsNothing);
  });

  group('namedRouteOrFirst with pushNamedAndRemoveUntil', () {
    testWidgets('keeps the first route when the named one is absent',
        (tester) async {
      final navigator = await pumpStack(tester, ['main', 'editMeal']);

      navigator.pushNamedAndRemoveUntil<void>(
        'mealDetail',
        namedRouteOrFirst('addMeal'),
      );
      await tester.pumpAndSettle();

      expect(find.text('mealDetail'), findsOneWidget);
      // `main` has to survive: the intake screen unwinds to it next.
      navigator.popUntil(namedRouteOrFirst('main'));
      await tester.pumpAndSettle();
      expect(find.text('main'), findsOneWidget);
    });

    testWidgets('still unwinds to the named route when it is present',
        (tester) async {
      final navigator =
          await pumpStack(tester, ['main', 'addMeal', 'editMeal']);

      navigator.pushNamedAndRemoveUntil<void>(
        'mealDetail',
        namedRouteOrFirst('addMeal'),
      );
      await tester.pumpAndSettle();

      expect(find.text('mealDetail'), findsOneWidget);
      navigator.popUntil(namedRouteOrFirst('addMeal'));
      await tester.pumpAndSettle();
      expect(find.text('addMeal'), findsOneWidget);
    });
  });
}
