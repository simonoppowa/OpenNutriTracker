import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:opennutritracker/core/domain/entity/intake_entity.dart';
import 'package:opennutritracker/core/domain/entity/intake_type_entity.dart';
import 'package:opennutritracker/core/domain/usecase/get_intake_usecase.dart';
import 'package:opennutritracker/core/presentation/widgets/add_item_bottom_sheet.dart';
import 'package:opennutritracker/core/presentation/widgets/app_card.dart';
import 'package:opennutritracker/core/utils/navigation_options.dart';
import 'package:opennutritracker/core/utils/navigation_predicates.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_nutriments_entity.dart';
import 'package:opennutritracker/features/add_meal/presentation/bloc/favourite_toggle_bloc.dart';
import 'package:opennutritracker/generated/l10n.dart';

import '../../../helpers/fake_favourites.dart';
import '../../../helpers/test_l10n.dart';

// #812: the sheet the centre "+" opens. Its headline sat under the Dynamic
// Island, its Recently cards ran edge to edge, and it had no close button.
// These tests open it the way MainScreen does, through
// showAddItemBottomSheet, over a stand-in for MainScreen that keeps a
// selected tab, so "back to where you came from" can be checked.

const _width = 393.0;
const _height = 852.0;
const _dpr = 3.0;

/// The iPhone 15 Pro's insets: 59 pt above (Dynamic Island), 34 pt below.
const _islandTop = 59.0;
const _homeIndicator = 34.0;

class _FakeGetIntakeUsecase implements GetIntakeUsecase {
  _FakeGetIntakeUsecase(this.count);

  final int count;

  @override
  Future<List<IntakeEntity>> getRecentIntake() async => [
    for (var i = 0; i < count; i++)
      IntakeEntity(
        id: 'recent-$i',
        unit: 'g',
        amount: 100,
        type: IntakeTypeEntity.lunch,
        meal: MealEntity(
          code: 'recent-$i',
          name: 'Recent $i',
          url: null,
          mealQuantity: '100',
          mealUnit: 'g',
          servingQuantity: null,
          servingUnit: null,
          servingSize: null,
          nutriments: MealNutrimentsEntity.empty(),
          source: MealSourceEntity.custom,
        ),
        dateTime: DateTime(2026, 1, 1),
      ),
  ];

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('Unexpected call: ${invocation.memberName}');
}

/// Stands in for MainScreen: a tab index that survives the sheet, and the
/// same call its centre "+" makes.
class _Host extends StatefulWidget {
  const _Host();

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(child: Text('tab-$_tab')),
    floatingActionButton: FloatingActionButton(
      onPressed: () =>
          showAddItemBottomSheet(context, day: DateTime(2026, 1, 1)),
      child: const Icon(Icons.add),
    ),
    bottomNavigationBar: Row(
      children: [
        for (var i = 0; i < 4; i++)
          TextButton(
            onPressed: () => setState(() => _tab = i),
            child: Text('go-$i'),
          ),
      ],
    ),
  );
}

/// Stands in for the meal detail screen: a back button, and a Log button
/// that unwinds the way MealDetailBottomSheet does after logging.
class _StubMealDetail extends StatelessWidget {
  const _StubMealDetail();

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('meal-detail')),
    body: Center(
      child: TextButton(
        onPressed: () => Navigator.of(
          context,
        ).popUntil(namedRouteOrFirst(NavigationOptions.mainRoute)),
        child: const Text('log'),
      ),
    ),
  );
}

Widget _app() => MaterialApp(
  localizationsDelegates: const [
    S.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  supportedLocales: S.supportedLocales,
  initialRoute: NavigationOptions.mainRoute,
  routes: {
    NavigationOptions.mainRoute: (_) => const _Host(),
    NavigationOptions.mealDetailRoute: (_) => const _StubMealDetail(),
  },
);

Finder _withIdentifier(String identifier) => find.byWidgetPredicate(
  (widget) => widget is Semantics && widget.properties.identifier == identifier,
);

Finder get _closeButton => find.descendant(
  of: _withIdentifier('add-item-close'),
  matching: find.byType(IconButton),
);

Future<void> _setUp(
  WidgetTester tester, {
  required double top,
  required double bottom,
  int recentCount = 4,
}) async {
  tester.view.physicalSize = const Size(_width * _dpr, _height * _dpr);
  tester.view.devicePixelRatio = _dpr;
  tester.view.padding = FakeViewPadding(top: top * _dpr, bottom: bottom * _dpr);
  tester.view.viewPadding = FakeViewPadding(
    top: top * _dpr,
    bottom: bottom * _dpr,
  );
  addTearDown(tester.view.reset);

  final getIt = GetIt.instance;
  await getIt.reset();
  final favourites = FakeFavourites();
  getIt.registerSingleton<GetIntakeUsecase>(_FakeGetIntakeUsecase(recentCount));
  getIt.registerFactory<FavouriteToggleBloc>(
    () => FavouriteToggleBloc(favourites.get, favourites.toggle),
  );
  addTearDown(() async {
    await getIt.reset();
    await favourites.dispose();
  });

  await tester.pumpWidget(_app());
  await tester.pumpAndSettle();
}

Future<void> _openSheet(WidgetTester tester, {int fromTab = 2}) async {
  await tester.tap(find.text('go-$fromTab'));
  await tester.pumpAndSettle();
  await tester.tap(find.byType(FloatingActionButton));
  await tester.pumpAndSettle();
  expect(find.byType(BottomSheet), findsOneWidget);
}

void main() {
  group('layout', () {
    for (final (name, top, bottom) in [
      ('no insets', 0.0, 0.0),
      ('Dynamic Island insets', _islandTop, _homeIndicator),
    ]) {
      testWidgets('$name: headline and close button clear the status bar', (
        tester,
      ) async {
        await _setUp(tester, top: top, bottom: bottom);
        await _openSheet(tester);

        final sheet = tester.getRect(find.byType(BottomSheet));
        final headline = tester.getRect(find.text(l10nEn.addItemLabel));
        final close = tester.getRect(_closeButton);

        // Four recent foods make the sheet taller than the screen, so it
        // grows to its cap. That cap is the bottom of the status bar.
        expect(sheet.top, top);
        expect(headline.top, greaterThanOrEqualTo(top));
        expect(close.top, greaterThanOrEqualTo(top));
        expect(close.right, lessThanOrEqualTo(_width));
      });

      testWidgets('$name: Recently cards keep the 16 pt side margins', (
        tester,
      ) async {
        await _setUp(tester, top: top, bottom: bottom);
        await _openSheet(tester);

        expect(find.text(l10nEn.recentlyAddedLabel), findsOneWidget);
        final cards = find.byType(AppCard);
        expect(cards, findsWidgets);
        for (final card in cards.evaluate()) {
          final rect = tester.getRect(find.byWidget(card.widget));
          expect(rect.left, 16, reason: 'left margin');
          expect(rect.right, _width - 16, reason: 'right margin');
        }
      });
    }

    testWidgets('an empty Recently list hides the section, keeps the rest', (
      tester,
    ) async {
      await _setUp(
        tester,
        top: _islandTop,
        bottom: _homeIndicator,
        recentCount: 0,
      );
      await _openSheet(tester);

      expect(find.text(l10nEn.recentlyAddedLabel), findsNothing);
      expect(find.byType(AppCard), findsNothing);
      expect(find.text(l10nEn.addItemLabel), findsOneWidget);
      expect(_closeButton, findsOneWidget);
      expect(find.text(l10nEn.breakfastLabel), findsOneWidget);

      // A short sheet sits at the bottom, clear of the status bar.
      final headline = tester.getRect(find.text(l10nEn.addItemLabel));
      expect(headline.top, greaterThan(_islandTop));
    });
  });

  group('close', () {
    testWidgets('the close button has the platform Close tooltip', (
      tester,
    ) async {
      await _setUp(tester, top: _islandTop, bottom: _homeIndicator);
      await _openSheet(tester);

      final button = tester.widget<IconButton>(_closeButton);
      expect(
        button.tooltip,
        const DefaultMaterialLocalizations().closeButtonTooltip,
      );
    });

    testWidgets('the close button returns to the tab the sheet was opened on', (
      tester,
    ) async {
      await _setUp(tester, top: _islandTop, bottom: _homeIndicator);
      await _openSheet(tester, fromTab: 2);

      await tester.tap(_closeButton);
      await tester.pumpAndSettle();

      expect(find.byType(BottomSheet), findsNothing);
      expect(find.text('tab-2'), findsOneWidget);
    });

    testWidgets('system back (Android) still closes the sheet', (tester) async {
      await _setUp(tester, top: _islandTop, bottom: _homeIndicator);
      await _openSheet(tester, fromTab: 1);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(find.byType(BottomSheet), findsNothing);
      expect(find.text('tab-1'), findsOneWidget);
    });

    testWidgets('dragging the sheet down still closes it', (tester) async {
      await _setUp(
        tester,
        top: _islandTop,
        bottom: _homeIndicator,
        recentCount: 0,
      );
      await _openSheet(tester, fromTab: 3);

      await tester.drag(find.text(l10nEn.addItemLabel), const Offset(0, 600));
      await tester.pumpAndSettle();

      expect(find.byType(BottomSheet), findsNothing);
      expect(find.text('tab-3'), findsOneWidget);
    });
  });

  group('a Recently food', () {
    testWidgets('back from its detail returns to the sheet', (tester) async {
      await _setUp(tester, top: _islandTop, bottom: _homeIndicator);
      await _openSheet(tester);

      await tester.tap(find.textContaining('Recent 0'));
      await tester.pumpAndSettle();
      expect(find.text('meal-detail'), findsOneWidget);

      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      expect(find.text('meal-detail'), findsNothing);
      expect(find.byType(BottomSheet), findsOneWidget);
      expect(_closeButton, findsOneWidget);

      // And from the sheet, close goes back to the tab.
      await tester.tap(_closeButton);
      await tester.pumpAndSettle();
      expect(find.text('tab-2'), findsOneWidget);
    });

    testWidgets('logging it lands on the tab the sheet was opened on', (
      tester,
    ) async {
      await _setUp(tester, top: _islandTop, bottom: _homeIndicator);
      await _openSheet(tester, fromTab: 1);

      await tester.tap(find.textContaining('Recent 0'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('log'));
      await tester.pumpAndSettle();

      expect(find.text('meal-detail'), findsNothing);
      expect(find.byType(BottomSheet), findsNothing);
      expect(find.text('tab-1'), findsOneWidget);
    });
  });
}
