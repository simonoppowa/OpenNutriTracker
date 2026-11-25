import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:opennutritracker/core/utils/energy_unit_provider.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_nutriments_entity.dart';
import 'package:opennutritracker/features/add_meal/presentation/add_meal_type.dart';
import 'package:opennutritracker/features/add_meal/presentation/bloc/favourite_toggle_bloc.dart';
import 'package:opennutritracker/features/add_meal/presentation/widgets/meal_item_card.dart';
import 'package:opennutritracker/features/add_meal/presentation/widgets/meal_macros_line.dart';
import 'package:opennutritracker/features/recipes/presentation/widgets/food_search_tab_view.dart';
import 'package:opennutritracker/generated/l10n.dart';
import 'package:provider/provider.dart';

import '../../../../helpers/fake_favourites.dart';

MealNutrimentsEntity _nutriments({
  double? kcal,
  double? protein,
  double? carbs,
  double? fat,
}) => MealNutrimentsEntity(
  energyKcal100: kcal,
  carbohydrates100: carbs,
  fat100: fat,
  proteins100: protein,
  sugars100: null,
  saturatedFat100: null,
  fiber100: null,
);

MealEntity _meal({
  String name = 'Skyr',
  String? brands,
  MealSourceEntity source = MealSourceEntity.off,
  MealNutrimentsEntity? nutriments,
  String? mealQuantity = '450',
  String? mealUnit = 'g',
}) => MealEntity(
  code: '1',
  name: name,
  brands: brands,
  url: null,
  mealQuantity: mealQuantity,
  mealUnit: mealUnit,
  servingQuantity: null,
  servingUnit: null,
  servingSize: null,
  nutriments: nutriments ?? MealNutrimentsEntity.empty(),
  source: source,
);

final _full = _nutriments(kcal: 250, protein: 30, carbs: 12, fat: 14);

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

  Future<void> pump(
    WidgetTester tester,
    Widget child, {
    double textScale = 1.0,
    bool kilojoules = false,
    double width = 400,
  }) async {
    tester.view.physicalSize = Size(width, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => EnergyUnitProvider(usesKilojoules: kilojoules),
        child: MaterialApp(
          localizationsDelegates: const [
            S.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: S.supportedLocales,
          builder: (context, app) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(textScale)),
            child: app!,
          ),
          home: Scaffold(body: ListView(children: [child])),
        ),
      ),
    );
    await tester.pump();
  }

  Widget card(MealEntity meal) => MealItemCard(
    day: DateTime(2026, 11, 9),
    mealEntity: meal,
    addMealType: AddMealType.lunchType,
    usesImperialUnits: false,
  );

  Widget pickable(MealEntity meal) =>
      PickableMealCard(meal: meal, onTap: (_) {});

  group('MealMacrosLine text', () {
    testWidgets('a full set reads kcal then P / C / F per 100 g/ml', (
      tester,
    ) async {
      await pump(tester, MealMacrosLine(meal: _meal(nutriments: _full)));

      expect(
        find.text('100 g/ml · 250 kcal · P 30 · C 12 · F 14'),
        findsOneWidget,
      );
    });

    testWidgets('only kcal shows only kcal, never a 0 for the rest', (
      tester,
    ) async {
      await pump(
        tester,
        MealMacrosLine(meal: _meal(nutriments: _nutriments(kcal: 250))),
      );

      expect(find.text('100 g/ml · 250 kcal'), findsOneWidget);
      expect(find.textContaining(' 0'), findsNothing);
    });

    testWidgets('macros without energy leave the energy out', (tester) async {
      await pump(
        tester,
        MealMacrosLine(meal: _meal(nutriments: _nutriments(fat: 0.4))),
      );

      expect(find.text('100 g/ml · F 0.4'), findsOneWidget);
      expect(find.textContaining('kcal'), findsNothing);
    });

    testWidgets('a real zero is shown, because the food has the value', (
      tester,
    ) async {
      await pump(
        tester,
        MealMacrosLine(
          meal: _meal(
            nutriments: _nutriments(kcal: 42, protein: 0, carbs: 10.5, fat: 0),
          ),
        ),
      );

      expect(
        find.text('100 g/ml · 42 kcal · P 0 · C 10.5 · F 0'),
        findsOneWidget,
      );
    });

    testWidgets('no nutrition data hides the line', (tester) async {
      await pump(tester, MealMacrosLine(meal: _meal()));

      expect(find.byType(Text), findsNothing);
      expect(find.textContaining('100 g/ml'), findsNothing);
    });

    testWidgets('non-finite values count as missing', (tester) async {
      await pump(
        tester,
        MealMacrosLine(
          meal: _meal(
            nutriments: _nutriments(
              kcal: double.nan,
              protein: double.infinity,
              carbs: 5,
            ),
          ),
        ),
      );

      expect(find.text('100 g/ml · C 5'), findsOneWidget);
    });

    testWidgets('very large numbers are shown in full, rounded', (
      tester,
    ) async {
      await pump(
        tester,
        MealMacrosLine(
          meal: _meal(
            nutriments: _nutriments(
              kcal: 123456.7,
              protein: 98765.43,
              carbs: 1000000,
              fat: 12.349,
            ),
          ),
        ),
      );

      expect(
        find.text('100 g/ml · 123457 kcal · P 98765.4 · C 1000000 · F 12.3'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('energy follows the kJ setting', (tester) async {
      await pump(
        tester,
        MealMacrosLine(meal: _meal(nutriments: _nutriments(kcal: 100))),
        kilojoules: true,
      );

      expect(find.text('100 g/ml · 418 kJ'), findsOneWidget);
    });

    testWidgets('screen readers hear whole words, not letters', (tester) async {
      final handle = tester.ensureSemantics();
      await pump(tester, MealMacrosLine(meal: _meal(nutriments: _full)));

      expect(
        find.bySemanticsLabel(
          '100 g/ml: 250 kcal, protein 30 g, carbs 12 g, fat 14 g',
        ),
        findsOneWidget,
      );
      expect(find.bySemanticsLabel(RegExp(r'P 30')), findsNothing);
      handle.dispose();
    });

    testWidgets('screen readers skip missing values too', (tester) async {
      final handle = tester.ensureSemantics();
      await pump(
        tester,
        MealMacrosLine(meal: _meal(nutriments: _nutriments(kcal: 250))),
      );

      expect(find.bySemanticsLabel('100 g/ml: 250 kcal'), findsOneWidget);
      handle.dispose();
    });
  });

  group('add-meal search row (MealItemCard)', () {
    testWidgets('an Open Food Facts row keeps its package size and adds '
        'the per-100 line', (tester) async {
      await pump(tester, card(_meal(nutriments: _full)));

      expect(find.text('450 g'), findsOneWidget);
      expect(
        find.text('100 g/ml · 250 kcal · P 30 · C 12 · F 14'),
        findsOneWidget,
      );
    });

    testWidgets('a row without nutrition data shows no macro line', (
      tester,
    ) async {
      await pump(tester, card(_meal()));

      expect(find.textContaining('100 g/ml'), findsNothing);
      expect(find.textContaining('kcal'), findsNothing);
    });

    testWidgets('a recipe row shows its per-100 g line under the chip', (
      tester,
    ) async {
      await pump(
        tester,
        card(
          _meal(
            name: 'Lasagne',
            source: MealSourceEntity.recipe,
            mealQuantity: '1200',
            nutriments: _nutriments(kcal: 180, protein: 9.2, carbs: 14, fat: 9),
          ),
        ),
      );

      expect(find.text('Custom Recipe'), findsOneWidget);
      expect(
        find.text('100 g/ml · 180 kcal · P 9.2 · C 14 · F 9'),
        findsOneWidget,
      );
    });

    testWidgets('a Quick Add row shows the values the user typed', (
      tester,
    ) async {
      // Quick Add stores its totals as per-100 values on a 100 g/ml meal
      // (quick_add_bottom_sheet.dart), so the line repeats what was typed.
      await pump(
        tester,
        card(
          _meal(
            name: 'Lunch out',
            source: MealSourceEntity.custom,
            mealQuantity: '100',
            mealUnit: 'gml',
            nutriments: _nutriments(kcal: 650, protein: 35, carbs: 70, fat: 22),
          ),
        ),
      );

      expect(
        find.text('100 g/ml · 650 kcal · P 35 · C 70 · F 22'),
        findsOneWidget,
      );
    });

    testWidgets('a custom meal with only kcal shows only kcal', (tester) async {
      await pump(
        tester,
        card(
          _meal(
            name: 'Grandma soup',
            source: MealSourceEntity.custom,
            mealQuantity: null,
            nutriments: _nutriments(kcal: 75),
          ),
        ),
      );

      expect(find.text('100 g/ml · 75 kcal'), findsOneWidget);
    });

    testWidgets('text scale 2.0 on a narrow phone: no overflow, title kept', (
      tester,
    ) async {
      await pump(
        tester,
        card(
          _meal(
            name: 'Organic Greek-style strained yoghurt natural',
            brands: 'Some Very Long Brand Name GmbH',
            nutriments: _nutriments(
              kcal: 123456.7,
              protein: 98765.43,
              carbs: 1000000,
              fat: 12.349,
            ),
          ),
        ),
        textScale: 2.0,
        width: 320,
      );

      expect(tester.takeException(), isNull);
      expect(
        find.textContaining('Organic Greek', findRichText: true),
        findsOneWidget,
      );
      final line = tester.widget<Text>(
        find.descendant(
          of: find.byType(MealMacrosLine),
          matching: find.byType(Text),
        ),
      );
      expect(line.maxLines, 2);
      expect(line.overflow, TextOverflow.ellipsis);
    });
  });

  group('recipe ingredient picker row', () {
    testWidgets('shows the same per-100 line', (tester) async {
      await pump(tester, pickable(_meal(nutriments: _full)));

      expect(
        find.text('100 g/ml · 250 kcal · P 30 · C 12 · F 14'),
        findsOneWidget,
      );
    });

    testWidgets('hides the line without nutrition data', (tester) async {
      await pump(tester, pickable(_meal()));

      expect(find.textContaining('100 g/ml'), findsNothing);
    });

    testWidgets('a recipe used as an ingredient shows its line', (
      tester,
    ) async {
      await pump(
        tester,
        pickable(
          _meal(
            name: 'Pesto',
            source: MealSourceEntity.recipe,
            nutriments: _nutriments(kcal: 450, fat: 45),
          ),
        ),
      );

      expect(find.text('100 g/ml · 450 kcal · F 45'), findsOneWidget);
    });

    testWidgets('text scale 2.0 on a narrow phone: no overflow', (
      tester,
    ) async {
      await pump(
        tester,
        pickable(
          _meal(
            name: 'Organic Greek-style strained yoghurt natural',
            brands: 'Some Very Long Brand Name GmbH',
            nutriments: _nutriments(
              kcal: 123456.7,
              protein: 98765.43,
              carbs: 1000000,
              fat: 12.349,
            ),
          ),
        ),
        textScale: 2.0,
        width: 320,
      );

      expect(tester.takeException(), isNull);
      expect(
        find.textContaining('Organic Greek', findRichText: true),
        findsOneWidget,
      );
    });

    testWidgets('a tap still picks the meal', (tester) async {
      MealEntity? picked;
      final meal = _meal(nutriments: _full);
      await pump(
        tester,
        PickableMealCard(meal: meal, onTap: (m) => picked = m),
      );

      await tester.tap(find.text('100 g/ml · 250 kcal · P 30 · C 12 · F 14'));
      expect(picked, meal);
    });
  });
}
