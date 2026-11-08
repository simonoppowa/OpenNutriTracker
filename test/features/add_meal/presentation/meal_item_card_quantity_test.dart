import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:opennutritracker/core/utils/extensions.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_nutriments_entity.dart';
import 'package:opennutritracker/features/add_meal/presentation/add_meal_type.dart';
import 'package:opennutritracker/features/add_meal/presentation/bloc/favourite_toggle_bloc.dart';
import 'package:opennutritracker/features/add_meal/presentation/widgets/meal_item_card.dart';
import 'package:opennutritracker/generated/l10n.dart';

import '../../../helpers/fake_favourites.dart';

MealEntity _meal(String? quantity) => MealEntity(
  code: '1',
  name: 'Skyr',
  url: null,
  mealQuantity: quantity,
  mealUnit: 'g',
  servingQuantity: null,
  servingUnit: null,
  servingSize: null,
  nutriments: MealNutrimentsEntity.empty(),
  source: MealSourceEntity.custom,
);

void main() {
  final getIt = GetIt.instance;
  late FakeFavourites favourites;

  setUp(() {
    favourites = FakeFavourites();
    getIt.registerFactory<FavouriteToggleBloc>(
      () => FavouriteToggleBloc(favourites.get, favourites.toggle),
    );
  });

  tearDown(() async {
    await getIt.reset();
    await favourites.dispose();
  });

  Future<void> pumpCard(WidgetTester tester, String? quantity) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [
          S.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: S.supportedLocales,
        home: Scaffold(
          body: MealItemCard(
            day: DateTime(2026, 10, 4),
            mealEntity: _meal(quantity),
            addMealType: AddMealType.lunchType,
            usesImperialUnits: false,
          ),
        ),
      ),
    );
    await tester.pump();
  }

  // Sentry OPENNUTRITRACKER-6B: a quantity stored with a decimal comma threw
  // `FormatException: Invalid double "137,0"` out of the card's build.
  testWidgets('shows a comma-decimal quantity instead of throwing', (
    tester,
  ) async {
    await pumpCard(tester, '137,0');

    expect(tester.takeException(), isNull);
    expect(find.textContaining('137'), findsOneWidget);
  });

  testWidgets('falls back to zero on a quantity that is not a number', (
    tester,
  ) async {
    await pumpCard(tester, '10 oz/283 g');

    expect(tester.takeException(), isNull);
    expect(find.textContaining('0'), findsWidgets);
  });

  testWidgets('shows a dot-decimal quantity as before', (tester) async {
    await pumpCard(tester, '137.0');

    expect(tester.takeException(), isNull);
    expect(find.textContaining('137'), findsOneWidget);
  });

  group('lenient quantity parsing', () {
    test('toLenientDoubleOrNull accepts a decimal comma', () {
      expect('137,0'.toLenientDoubleOrNull(), 137.0);
      expect(' 1,5 '.toLenientDoubleOrNull(), 1.5);
      expect('137.0'.toLenientDoubleOrNull(), 137.0);
    });

    test('toLenientDoubleOrNull rejects garbage and non-finite words', () {
      expect(''.toLenientDoubleOrNull(), isNull);
      expect('abc'.toLenientDoubleOrNull(), isNull);
      expect('10 oz/283 g'.toLenientDoubleOrNull(), isNull);
      expect('NaN'.toLenientDoubleOrNull(), isNull);
      expect('Infinity'.toLenientDoubleOrNull(), isNull);
    });

    test('withDotDecimal rewrites only a numeric comma-decimal text', () {
      expect('137,0'.withDotDecimal(), '137.0');
      expect('137.0'.withDotDecimal(), '137.0');
      expect('100'.withDotDecimal(), '100');
      expect('a,b'.withDotDecimal(), 'a,b');
    });
  });
}
