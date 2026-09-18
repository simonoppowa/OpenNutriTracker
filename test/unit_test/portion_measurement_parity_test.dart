// The #1160 harnesses under `tool/portion_measurement/` run with `dart run`,
// which cannot compile `meal_entity.dart` (Hive and `dart:ui` through its
// imports) and so nothing that takes a `MealEntity`: the resolver's two
// rankers, the data source's cut, the consistency filter, the review row's
// flags and the bloc's unit choice. The harness imports every scorer that
// does compile — `scoreText`, `tokenize`, `deriveTitle`, `deriveQualifiers`,
// `matchPortionToKey`, `matchPortionToQuery`, `SpFoodDTO` — and restates
// the wrappers around them. This test is what keeps a restatement honest:
// change the original and the harness measures against the wrong ranking,
// the wrong cut or the wrong flag.
//
// Pinned, over the repo's real backend pools (`BackendPoolFixtures`, copied
// from the live backend on 2026-09-13) with `has_portion` and without: the
// English cut and the translation cut, row for row; both scorers, row for
// row, with portions, without, machine-translated, branded and marked
// unavailable; the whole ranked order of the page the resolver is handed;
// the translation page's decoration; the consistency filter; the matcher's
// restated score against its answers, on ties and the middle rung;
// `portionKeyMissed` conjunct for conjunct; the bloc's own `_initialUnit`
// against the harness's reading of it; the photo guard against the shipped
// interpreter; and the model ids against the catalogue.

import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/utils/ai_credential_storage.dart';
import 'package:opennutritracker/core/utils/ai_model_catalogue.dart';
import 'package:opennutritracker/features/add_meal/data/data_sources/sp_food_data_source.dart';
import 'package:opennutritracker/features/add_meal/data/dto/sp/sp_const.dart';
import 'package:opennutritracker/features/add_meal/data/dto/sp/sp_food_dto.dart';
import 'package:opennutritracker/features/add_meal/data/model_meal_photo_interpreter.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_nutriments_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_portion_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/meal_items_api.dart';
import 'package:opennutritracker/features/add_meal/domain/meal_photo_interpreter.dart';
import 'package:opennutritracker/features/add_meal/domain/usecase/read_meal_photo_usecase.dart';
import 'package:opennutritracker/features/add_meal/domain/usecase/read_meal_text_usecase.dart';
import 'package:opennutritracker/features/add_meal/domain/usecase/resolve_parsed_meals_usecase.dart';
import 'package:opennutritracker/features/add_meal/domain/usecase/search_products_usecase.dart';
import 'package:opennutritracker/features/add_meal/presentation/bloc/bulk_add_bloc.dart';
import 'package:opennutritracker/features/add_meal/util/meal_relevance_ranker.dart'
    as app;
import 'package:opennutritracker/features/add_meal/util/meal_text_parser.dart';
import 'package:opennutritracker/features/add_meal/util/portion_match.dart';
import 'package:opennutritracker/features/add_meal/util/portion_unit.dart';
import 'package:opennutritracker/features/add_meal/util/resolver_relevance.dart'
    as app;

import '../../tool/portion_measurement/metrics.dart' as tool;
import '../../tool/portion_measurement/providers.dart' as tool;
import '../../tool/portion_measurement/resolver.dart' as tool;
import '../fixture/backend_pool_fixtures.dart';

/// The English pools, each with the query it was fetched for and the
/// portion counts the backend delivers.
final _englishPools = <(String, List<SpFoodDTO>, Map<int, int>)>[
  ('potato', BackendPoolFixtures.potato, BackendPoolFixtures.potatoPortions),
  ('bread', BackendPoolFixtures.bread, BackendPoolFixtures.breadPortions),
  (
    'chicken breast',
    BackendPoolFixtures.chickenBreast,
    BackendPoolFixtures.chickenBreastPortions,
  ),
  ('egg', BackendPoolFixtures.egg, BackendPoolFixtures.eggPortions),
  ('eggs', BackendPoolFixtures.eggs, BackendPoolFixtures.eggsPortions),
  ('milk', BackendPoolFixtures.milk, BackendPoolFixtures.milkPortions),
  ('apple', BackendPoolFixtures.apple, BackendPoolFixtures.applePortions),
  ('dried apple', BackendPoolFixtures.apple, BackendPoolFixtures.applePortions),
  (
    'orange juice',
    BackendPoolFixtures.orangeJuice,
    BackendPoolFixtures.orangeJuicePortions,
  ),
  ('rice', BackendPoolFixtures.rice, BackendPoolFixtures.ricePortions),
  ('carrots', BackendPoolFixtures.carrots, BackendPoolFixtures.carrotsPortions),
  ('muffins', BackendPoolFixtures.muffins, BackendPoolFixtures.muffinsPortions),
];

final _translationPools = <(String, List<Map<String, dynamic>>, Map<int, int>)>[
  ('Milch', BackendPoolFixtures.milch, BackendPoolFixtures.milchPortions),
  (
    'Kartoffel',
    BackendPoolFixtures.kartoffel,
    BackendPoolFixtures.kartoffelPortions,
  ),
];

/// [count] portions, English labels, as many as the backend delivers.
List<MealPortionEntity> _portions(int count) => [
  for (var i = 0; i < count; i++)
    MealPortionEntity(label: '1 portion $i', gramWeight: 100, localized: false),
];

List<int> _ids(List<SpFoodDTO> dtos) => [for (final d in dtos) d.foodId!];

List<int> _mealIds(List<MealEntity> meals) => [
  for (final m in meals) int.parse(m.code!),
];

List<int> _toolIds(List<tool.ResolverMeal> meals) => [
  for (final m in meals) m.foodId!,
];

/// The app's pipeline from a cut page on: `fromSpFood`, `withPortions`,
/// `mergeAndRankMeals` with OFF empty, `rankForResolution` — as
/// `ProductsRepository` and `ResolveParsedMealsUseCase` run it.
List<MealEntity> _appRanked(
  List<SpFoodDTO> page,
  Map<int, int> portions,
  String query,
) {
  final meals = [
    for (final dto in page)
      MealEntity.fromSpFood(dto).withPortions(_portions(portions[dto.foodId]!)),
  ];
  return app.rankForResolution(
    app.mergeAndRankMeals(const [], meals, query),
    query,
  );
}

List<tool.ResolverMeal> _toolRanked(
  List<SpFoodDTO> page,
  Map<int, int> portions,
  String query,
) {
  final meals = [
    for (final dto in page)
      tool.ResolverMeal(dto, portions: _portions(portions[dto.foodId]!)),
  ];
  return tool.rankForResolution(tool.mergeAndRank(meals, query), query);
}

/// A `food_summary_by_ids` row for a translation row, in the shape the RPC
/// returns — `setof food_summary`, `has_portion` included — with a name
/// that says nothing about the query, as the English description of a
/// German hit usually does not.
Map<String, dynamic> _summaryFor(Map<String, dynamic> translation) => {
  'food_id': translation[SPConst.translationFoodId],
  'source': 'fdc_survey',
  'source_code': '${translation[SPConst.translationFoodId]}',
  'name': 'Food ${translation[SPConst.translationFoodId]}',
  'has_portion': translation[SPConst.translationHasPortion],
};

MealEntity _backendFood(
  String name, {
  String? brands,
  bool machineTranslated = false,
  int portions = 0,
  bool unavailable = false,
}) {
  final dto = SpFoodDTO(
    foodId: name.hashCode,
    source: 'fdc_survey',
    sourceCode: '1',
    name: machineTranslated ? 'English $name' : name,
    brands: brands,
  );
  if (machineTranslated) {
    dto.localizedName = name;
    dto.localizedNameIsMachineTranslated = true;
  }
  var meal = MealEntity.fromSpFood(dto).withPortions(_portions(portions));
  if (unavailable) meal = meal.withPortionsUnavailable();
  return meal;
}

tool.ResolverMeal _toolFood(
  String name, {
  String? brands,
  bool machineTranslated = false,
  int portions = 0,
  bool unavailable = false,
}) {
  final dto = SpFoodDTO(
    foodId: name.hashCode,
    source: 'fdc_survey',
    sourceCode: '1',
    name: machineTranslated ? 'English $name' : name,
    brands: brands,
  );
  if (machineTranslated) {
    dto.localizedName = name;
    dto.localizedNameIsMachineTranslated = true;
  }
  return tool.ResolverMeal(
    dto,
    portions: _portions(portions),
    portionsUnavailable: unavailable,
  );
}

const _pairs = <(String, String)>[
  ('Banana, raw', 'banana'),
  ('Banana split', 'banana'),
  ('Banana', 'banana'),
  ('Bread, white', 'white bread'),
  ('White bread/wheat bread', 'white bread'),
  ('Chicken breast, rotisserie, skin eaten', 'chicken breast'),
  ('Milk & hazelnut', 'milk'),
  ('Salmon salad', 'salad'),
  ('Lettuce, raw', 'salad'),
  ('Apple, dried', 'dried apple'),
  ('Apple, raw', 'dried apple'),
  ('Potato, french fries, with cheese', 'cheesy potato'),
  ('Egg, yolk only, raw', 'egg yolks'),
  ('意大利面', '意大利面'),
  ('Spaghetti', '意大利面'),
  ('Egg, creamed', ''),
  ('  Egg,   whole, raw  ', 'EGG'),
];

/// Name, brand, query — the brand paths of both scorers.
const _branded = <(String, String?, String)>[
  ('Whole milk', 'Horizon', 'milk'),
  ('Cereal bar', 'Milka', 'milk'),
  ('Cereal bar', 'milk', 'milk'),
  ('Chocolate', 'Milk Chocolate Co', 'milk chocolate'),
  ('Yogurt', '', 'yogurt'),
  ('Yogurt', null, 'yogurt'),
];

SpFoodDTO _nutriments({
  double? carbs,
  double? sugars,
  double? fat,
  double? satFat,
  double? protein,
}) => SpFoodDTO(
  foodId: 1,
  source: 'fdc_survey',
  sourceCode: '1',
  name: 'x',
  carbohydrates100: carbs,
  sugars100: sugars,
  fat100: fat,
  saturatedFat100: satFat,
  proteins100: protein,
);

MealPortionEntity _p(String label, {String? en, double grams = 30}) =>
    MealPortionEntity(
      label: label,
      gramWeight: grams,
      localized: en != null,
      englishLabel: en,
    );

/// A bread ladder as the backend delivers it to a German reader: FDC's
/// small-first order, the middle rung in the middle, a cup row behind.
final _breadDe = [
  _p('1 dünne Scheibe', en: '1 thin slice', grams: 24),
  _p(
    '1 mittlere oder normale Scheibe',
    en: '1 medium or regular slice',
    grams: 28,
  ),
  _p('1 dicke Scheibe', en: '1 thick slice', grams: 38),
  _p('1 Tasse, Würfel', en: '1 cup, cubes', grams: 35),
];

/// The same ladder in English, where `label_en` equals the label.
final _breadEn = [
  _p('1 thin slice', en: '1 thin slice', grams: 24),
  _p('1 medium or regular slice', en: '1 medium or regular slice', grams: 28),
  _p('1 thick slice', en: '1 thick slice', grams: 38),
  _p('1 cup, cubes', en: '1 cup, cubes', grams: 35),
];

/// Rows with no middle rung, so a tie falls to the earlier row.
final _melon = [
  _p('1 small wedge', en: '1 small wedge', grams: 200),
  _p('1 small melon', en: '1 small melon', grams: 900),
  _p('1 cup, diced', en: '1 cup, diced', grams: 152),
];

MealEntity _foodWith(List<MealPortionEntity> portions, {double? serving}) =>
    MealEntity(
      code: '1',
      name: 'Bread, white',
      url: null,
      mealQuantity: null,
      mealUnit: 'g',
      servingQuantity: serving,
      servingUnit: 'g',
      servingSize: '1 slice',
      nutriments: MealNutrimentsEntity.empty(),
      source: MealSourceEntity.fdc,
      backendSource: 'fdc_survey',
    ).withPortions(portions);

BulkAddRow _row({
  required MealEntity? food,
  required ParsedMealItem parsed,
  bool fromPhoto = false,
  bool unavailable = false,
}) => BulkAddRow(
  resolved: ResolvedMealItem(
    parsed: parsed,
    candidates: food == null
        ? const []
        : [unavailable ? food.withPortionsUnavailable() : food],
    selectedIndex: 0,
    confidence: 1,
  ),
  selectedIndex: 0,
  amountText: '1',
  unit: 'g',
  fromPhoto: fromPhoto,
);

/// The bloc as the review screen drives it, with one resolved food per
/// query and a reader that answers with exactly these items — the only
/// way to reach the private `_initialUnit`.
class _FixedReader implements ReadMealTextUseCase {
  final List<ParsedMealItem> items;

  _FixedReader(this.items);

  @override
  Future<MealTextReading> read(String input, {String? localeCode}) async =>
      MealTextReading(
        MealTextParseResult(items: items, errors: const []),
        usedModel: true,
      );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _NoPhotoReader implements ReadMealPhotoUseCase {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FixedSearch implements SearchProductsUseCase {
  final Map<String, List<MealEntity>> results;

  _FixedSearch(this.results);

  @override
  Future<SearchProductsResult> searchOFFProductsByString(
    String searchString, {
    bool skipRemote = false,
  }) async => const SearchProductsResult(meals: [], remoteSourceEmpty: true);

  @override
  Future<SearchProductsResult> searchFDCFoodByString(
    String searchString, {
    bool skipRemote = false,
    bool forResolution = false,
  }) async => SearchProductsResult(
    meals: results[searchString] ?? const [],
    remoteSourceEmpty: false,
  );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<String> _blocUnit(MealEntity food, ParsedMealItem item) async {
  final bloc = BulkAddBloc(
    ResolveParsedMealsUseCase(
      _FixedSearch({
        item.query: [food],
      }),
    ),
    _FixedReader([item]),
    _NoPhotoReader(),
  );
  final loaded = bloc.stream.firstWhere((s) => s is BulkAddLoadedState);
  bloc.add(const ParseBulkTextEvent(text: 'x', usesImperialUnits: false));
  final state = await loaded as BulkAddLoadedState;
  await bloc.close();
  return state.rows.single.unit;
}

/// The unit the harness's reading of `_initialUnit` implies.
String _toolUnit(MealEntity food, ParsedMealItem item) {
  final step = tool.initialUnitStep(
    unit: item.unit,
    quantity: item.quantity,
    key: item.portion,
    query: item.query,
    portions: food.portions,
    servingQuantity: food.servingQuantity,
  );
  return switch (step) {
    tool.InitialUnitStep.statedUnit => item.unit!,
    tool.InitialUnitStep.key => portionUnit(
      matchPortionToKey(item.portion, food.portions)!,
    ),
    tool.InitialUnitStep.queryWords => portionUnit(
      matchPortionToQuery(item.query, food.portions)!,
    ),
    tool.InitialUnitStep.serving => 'serving',
    tool.InitialUnitStep.fallback => food.servingUnit!,
  };
}

class _FixedApi implements MealItemsApi {
  final List<Map<String, Object?>> items;

  _FixedApi(this.items);

  @override
  Future<MealTextParseResult> requestItems({
    required MealContent content,
    required String system,
  }) async => validateParsedMealItems(mealItemsFromJson(items));
}

void main() {
  group('the constants', () {
    test('noPortionsPenalty', () {
      expect(tool.noPortionsPenalty, app.noPortionsPenalty);
    });

    test('the confidence floor', () {
      expect(tool.resolutionConfidenceFloor, kResolutionConfidenceFloor);
    });

    test('the page size', () {
      expect(tool.maxNumberOfItems, SPConst.maxNumberOfItems);
      expect(tool.candidatePoolSize, SPConst.maxNumberOfItems * 5);
    });
  });

  group('the cut agrees with rankAndTruncateFoodsByName', () {
    for (final (query, pool, portions) in _englishPools) {
      test('$query, with the flag', () {
        final flagged = BackendPoolFixtures.flagged(pool, portions);
        expect(
          _ids(tool.cutEnglishPage(flagged, query)),
          _ids(rankAndTruncateFoodsByName(flagged, query, forResolution: true)),
        );
      });

      test('$query, without the flag', () {
        expect(
          _ids(tool.cutEnglishPage(pool, query)),
          _ids(rankAndTruncateFoodsByName(pool, query, forResolution: true)),
        );
      });
    }
  });

  group('the cut agrees with rankAndTruncateTranslationRows', () {
    for (final (query, pool, portions) in _translationPools) {
      test('$query, with the flag', () {
        final flagged = BackendPoolFixtures.flaggedTranslations(pool, portions);
        expect(
          [
            for (final r in tool.cutTranslationRows([...flagged], query))
              r[SPConst.translationFoodId],
          ],
          [
            for (final r in rankAndTruncateTranslationRows(
              [...flagged],
              query,
              forResolution: true,
            ))
              r[SPConst.translationFoodId],
          ],
        );
      });

      test('$query, without the flag', () {
        expect(
          [
            for (final r in tool.cutTranslationRows([...pool], query))
              r[SPConst.translationFoodId],
          ],
          [
            for (final r in rankAndTruncateTranslationRows(
              [...pool],
              query,
              forResolution: true,
            ))
              r[SPConst.translationFoodId],
          ],
        );
      });
    }

    test('a flag that is not a boolean reads as null', () {
      final rows = [
        {
          SPConst.translationFoodId: 1,
          SPConst.translationDescription: 'Milch',
          SPConst.translationSource: 'machine',
          SPConst.translationHasPortion: 'yes',
        },
        {
          SPConst.translationFoodId: 2,
          SPConst.translationDescription: 'Milch',
          SPConst.translationSource: 'machine',
          SPConst.translationHasPortion: false,
        },
      ];
      expect(
        [
          for (final r in tool.cutTranslationRows([...rows], 'Milch'))
            r['food_id'],
        ],
        [
          for (final r in rankAndTruncateTranslationRows(
            [...rows],
            'Milch',
            forResolution: true,
          ))
            r['food_id'],
        ],
      );
    });
  });

  group('the scorers agree with the app on a backend record', () {
    test('scoreMealForResolution, with and without portions', () {
      for (final (name, query) in _pairs) {
        for (final n in [0, 1, 3]) {
          expect(
            tool.resolutionScore(_toolFood(name, portions: n), query),
            app.scoreMealForResolution(_backendFood(name, portions: n), query),
            reason: '"$name" against "$query" with $n portions',
          );
        }
      }
    });

    test('scoreMealForResolution on a record marked unavailable', () {
      for (final (name, query) in _pairs) {
        expect(
          tool.resolutionScore(_toolFood(name, unavailable: true), query),
          app.scoreMealForResolution(
            _backendFood(name, unavailable: true),
            query,
          ),
          reason: '"$name" against "$query"',
        );
      }
    });

    test('both scorers on a machine-translated record', () {
      for (final (name, query) in _pairs) {
        expect(
          tool.resolutionScore(
            _toolFood(name, machineTranslated: true, portions: 2),
            query,
          ),
          app.scoreMealForResolution(
            _backendFood(name, machineTranslated: true, portions: 2),
            query,
          ),
          reason: 'resolution of "$name" against "$query"',
        );
        expect(
          tool.relevanceScore(_toolFood(name, machineTranslated: true), query),
          app.scoreMealRelevance(
            _backendFood(name, machineTranslated: true),
            query,
          ),
          reason: 'relevance of "$name" against "$query"',
        );
      }
    });

    test('both scorers on a branded record', () {
      for (final (name, brand, query) in _branded) {
        expect(
          tool.resolutionScore(
            _toolFood(name, brands: brand, portions: 1),
            query,
          ),
          app.scoreMealForResolution(
            _backendFood(name, brands: brand, portions: 1),
            query,
          ),
          reason: 'resolution of "$name" / "$brand" against "$query"',
        );
        expect(
          tool.relevanceScore(_toolFood(name, brands: brand), query),
          app.scoreMealRelevance(_backendFood(name, brands: brand), query),
          reason: 'relevance of "$name" / "$brand" against "$query"',
        );
      }
    });

    test('scoreMealRelevance', () {
      for (final (name, query) in _pairs) {
        expect(
          tool.relevanceScore(_toolFood(name), query),
          app.scoreMealRelevance(_backendFood(name), query),
          reason: '"$name" against "$query"',
        );
      }
    });
  });

  group(
    'the ranked page agrees with mergeAndRankMeals then rankForResolution',
    () {
      for (final (query, pool, portions) in _englishPools) {
        test('$query, the whole order over the cut page', () {
          final page = rankAndTruncateFoodsByName(
            BackendPoolFixtures.flagged(pool, portions),
            query,
            forResolution: true,
          );
          expect(
            _toolIds(_toolRanked(page, portions, query)),
            _mealIds(_appRanked(page, portions, query)),
          );
        });
      }

      test('a food id listed twice keeps its first entry', () {
        final page = rankAndTruncateFoodsByName(
          BackendPoolFixtures.flagged(
            BackendPoolFixtures.egg,
            BackendPoolFixtures.eggPortions,
          ),
          'egg',
          forResolution: true,
        );
        final doubled = [...page, page[3], page.first];
        expect(
          _toolIds(
            _toolRanked(doubled, BackendPoolFixtures.eggPortions, 'egg'),
          ),
          _mealIds(_appRanked(doubled, BackendPoolFixtures.eggPortions, 'egg')),
        );
      });

      test('landOn names the winner, its confidence and its score ties', () {
        final portions = BackendPoolFixtures.milkPortions;
        final page = rankAndTruncateFoodsByName(
          BackendPoolFixtures.flagged(BackendPoolFixtures.milk, portions),
          'milk',
          forResolution: true,
        );
        final landed = tool.landOn([
          for (final dto in page)
            tool.ResolverMeal(dto, portions: _portions(portions[dto.foodId]!)),
        ], 'milk')!;
        final ranked = _appRanked(page, portions, 'milk');
        expect(landed.winner.foodId, int.parse(ranked.first.code!));
        expect(
          landed.confidence,
          app.scoreMealForResolution(ranked.first, 'milk'),
        );
        expect(
          landed.scoreTies,
          ranked
              .skip(1)
              .where(
                (m) =>
                    app.scoreMealForResolution(m, 'milk') ==
                    app.scoreMealForResolution(ranked.first, 'milk'),
              )
              .length,
        );
        expect(landed.winner.foodId, BackendPoolFixtures.milkNfs);
      });
    },
  );

  group('the translation page', () {
    for (final (query, pool, portions) in _translationPools) {
      test('$query: the summary rows re-sorted onto the cut, then ranked', () {
        final flagged = BackendPoolFixtures.flaggedTranslations(pool, portions);
        final cut = rankAndTruncateTranslationRows(
          [...flagged],
          query,
          forResolution: true,
        );
        // The ids `_searchByTranslation` asks for: distinct, first
        // position kept.
        final nameByFoodId = {
          for (final row in cut)
            row[SPConst.translationFoodId] as int:
                row[SPConst.translationDescription] as String?,
        };
        expect(tool.translationIds(cut), nameByFoodId.keys.toList());

        // The summary rows in an order a WHERE-IN fetch might return.
        final summaries = [for (final row in cut) _summaryFor(row)]..shuffle();
        final page = tool.translationPage(cut, summaries);

        // `_searchByTranslation`'s decoration and re-sort
        // (sp_food_data_source.dart:342-389), restated here because the
        // method is private and needs a client.
        final machine = {
          for (final row in cut)
            if (row[SPConst.translationSource] ==
                SPConst.translationSourceMachine)
              row[SPConst.translationFoodId] as int,
        };
        final rankByFoodId = {
          for (final (rank, id) in nameByFoodId.keys.indexed) id: rank,
        };
        final expected =
            summaries.map((food) {
              final dto = SpFoodDTO.fromJson(food);
              dto.localizedName = nameByFoodId[dto.foodId];
              dto.localizedNameIsMachineTranslated = machine.contains(
                dto.foodId,
              );
              return dto;
            }).toList()..sort(
              (a, b) => (rankByFoodId[a.foodId] ?? rankByFoodId.length)
                  .compareTo(rankByFoodId[b.foodId] ?? rankByFoodId.length),
            );
        expect(_ids(page), _ids(expected));
        for (final (i, dto) in page.indexed) {
          expect(dto.localizedName, expected[i].localizedName);
          expect(
            dto.localizedNameIsMachineTranslated,
            expected[i].localizedNameIsMachineTranslated,
          );
          expect(dto.hasPortion, expected[i].hasPortion);
        }

        // And the rankers over that page, as on the English path.
        expect(
          _toolIds(_toolRanked(page, portions, query)),
          _mealIds(_appRanked(page, portions, query)),
        );
      });
    }
  });

  group('the consistency filter agrees with validateNutriments', () {
    final cases = [
      _nutriments(carbs: 10, sugars: 5, fat: 5, satFat: 2, protein: 10),
      _nutriments(carbs: 10, sugars: 12),
      _nutriments(carbs: 10, sugars: 10.9),
      _nutriments(fat: 5, satFat: 7),
      _nutriments(carbs: 50, fat: 30, protein: 25),
      _nutriments(carbs: 50, fat: 30, protein: 20.9),
      _nutriments(sugars: 12),
      _nutriments(),
    ];
    for (final (i, dto) in cases.indexed) {
      test('case $i', () {
        expect(
          tool.nutrimentsConsistent(dto),
          validateNutriments(
            MealNutrimentsEntity.fromSpFoodSummary(dto),
          ).isConsistent,
        );
      });
    }
  });

  group('the matcher, read through the app', () {
    test('the key path goes against the English label', () {
      final m = tool.matchKey('slice', _breadDe)!;
      expect(m.index, matchPortionToKey('slice', _breadDe));
      expect(m.tie, isTrue);
      expect(m.middleRung, isTrue);
      expect(m.movedByMiddleRung, isTrue);
      expect(m.portion.label, '1 mittlere oder normale Scheibe');
      expect(m.tiedWith.map((p) => p.label), [
        '1 dünne Scheibe',
        '1 dicke Scheibe',
      ]);
      expect(m.literal, isTrue);
    });

    test('the query path goes against the label as it arrived', () {
      expect(tool.matchQueryWords('slice', _breadDe), isNull);
      expect(matchPortionToQuery('slice', _breadDe), isNull);
      final m = tool.matchQueryWords('3 Scheiben Brot', _breadDe)!;
      expect(m.index, matchPortionToQuery('3 Scheiben Brot', _breadDe));
      expect(m.tie, isTrue);
      expect(m.middleRung, isTrue);
      expect(m.literal, isFalse);
    });

    test('a size word beside the noun outscores the ladder', () {
      final m = tool.matchKey('thick slice', _breadEn)!;
      expect(m.index, 2);
      expect(m.tie, isFalse);
      expect(m.middleRung, isFalse);
    });

    test('a tie with no middle rung falls to the earlier row', () {
      final m = tool.matchKey('small', _melon)!;
      expect(m.index, matchPortionToKey('small', _melon));
      expect(m.index, 0);
      expect(m.tie, isTrue);
      expect(m.middleRung, isFalse);
      expect(m.movedByMiddleRung, isFalse);
    });

    test('the middle rung that is the first row anyway', () {
      final rows = [_breadEn[1], _breadEn[0], _breadEn[2]];
      final m = tool.matchKey('slice', rows)!;
      expect(m.index, 0);
      expect(m.middleRung, isTrue);
      expect(m.movedByMiddleRung, isFalse);
    });

    test('a miss, a two-letter key, an empty list', () {
      expect(tool.matchKey('handful', _breadEn), isNull);
      expect(tool.matchKey('oz', _breadEn), isNull);
      expect(tool.matchKey('slice', const []), isNull);
      expect(tool.matchQueryWords('', _breadEn), isNull);
    });

    test('an inflected hit is not literal', () {
      final rows = [_p('2 slices', en: '2 slices')];
      final m = tool.matchKey('slice', rows)!;
      expect(m.literal, isFalse);
    });
  });

  group('portionKeyMissed agrees with BulkAddRow', () {
    final food = _foodWith(_breadDe, serving: 28);
    final bare = _foodWith(const [], serving: 28);
    final cases = <(String, MealEntity?, ParsedMealItem, bool, bool)>[
      (
        'key hits',
        food,
        const ParsedMealItem(query: 'Brot', quantity: 3, portion: 'slice'),
        false,
        false,
      ),
      (
        'key misses, query words hit',
        food,
        const ParsedMealItem(
          query: 'Scheiben Brot',
          quantity: 3,
          portion: 'handful',
        ),
        false,
        false,
      ),
      (
        'key and query both miss',
        food,
        const ParsedMealItem(query: 'Brot', quantity: 3, portion: 'handful'),
        false,
        false,
      ),
      (
        'no count',
        food,
        const ParsedMealItem(query: 'Brot', portion: 'handful'),
        false,
        false,
      ),
      (
        'no key',
        food,
        const ParsedMealItem(query: 'Brot', quantity: 3),
        false,
        false,
      ),
      (
        'food has no rows',
        bare,
        const ParsedMealItem(query: 'Brot', quantity: 3, portion: 'handful'),
        false,
        false,
      ),
      (
        'lookup failed',
        food,
        const ParsedMealItem(query: 'Brot', quantity: 3, portion: 'handful'),
        false,
        true,
      ),
      (
        'photo',
        food,
        const ParsedMealItem(query: 'Brot', quantity: 3, portion: 'handful'),
        true,
        false,
      ),
      (
        'unresolved',
        null,
        const ParsedMealItem(query: 'Brot', quantity: 3, portion: 'handful'),
        false,
        false,
      ),
    ];
    for (final (name, meal, parsed, fromPhoto, unavailable) in cases) {
      test(name, () {
        final row = _row(
          food: meal,
          parsed: parsed,
          fromPhoto: fromPhoto,
          unavailable: unavailable,
        );
        expect(
          tool.rowPortionKeyMissed(
            key: parsed.portion,
            query: parsed.query,
            quantity: parsed.quantity,
            fromPhoto: fromPhoto,
            food: row.meal?.portions,
            portionsUnavailable: row.meal?.portionsUnavailable ?? false,
          ),
          row.portionKeyMissed,
        );
      });
    }

    test('the one case that fires', () {
      final row = _row(
        food: food,
        parsed: const ParsedMealItem(
          query: 'Brot',
          quantity: 3,
          portion: 'handful',
        ),
      );
      expect(row.portionKeyMissed, isTrue);
      expect(row.amountNeedsCheck, isTrue);
    });
  });

  group('initialUnitStep agrees with the bloc', () {
    final food = _foodWith(_breadDe, serving: 28);
    final cases = <(String, ParsedMealItem)>[
      (
        'a stated unit',
        const ParsedMealItem(
          query: 'Brot',
          quantity: 50,
          unit: 'g',
          portion: 'slice',
        ),
      ),
      (
        'the key',
        const ParsedMealItem(query: 'Brot', quantity: 3, portion: 'slice'),
      ),
      (
        'the key before the query words',
        const ParsedMealItem(
          query: 'Tasse Brot',
          quantity: 3,
          portion: 'slice',
        ),
      ),
      (
        'the query words after a missed key',
        const ParsedMealItem(
          query: 'Tasse Brot',
          quantity: 3,
          portion: 'handful',
        ),
      ),
      (
        'the query words with no key',
        const ParsedMealItem(query: 'dicke Scheibe Brot', quantity: 3),
      ),
      (
        'serving on a bare count',
        const ParsedMealItem(query: 'Brot', quantity: 3, portion: 'handful'),
      ),
      (
        'the fallback with no count',
        const ParsedMealItem(query: 'Brot', portion: 'slice'),
      ),
    ];
    for (final (name, item) in cases) {
      test(name, () async {
        expect(await _blocUnit(food, item), _toolUnit(food, item));
      });
    }

    test('the fallback on a record with no serving', () async {
      final noServing = _foodWith(const [], serving: null);
      const item = ParsedMealItem(query: 'Brot', quantity: 3, portion: 'slice');
      expect(await _blocUnit(noServing, item), _toolUnit(noServing, item));
      expect(
        tool.initialUnitStep(
          unit: null,
          quantity: 3,
          key: 'slice',
          query: 'Brot',
          portions: const [],
          servingQuantity: null,
        ),
        tool.InitialUnitStep.fallback,
      );
    });
  });

  group('the photo guard agrees with the interpreter', () {
    final plates = <List<Map<String, Object?>>>[
      [
        {'query': 'egg', 'quantity': 2, 'portion': 'large'},
        {'query': 'toast', 'quantity': 2, 'portion': 'slice'},
        {'query': 'orange juice'},
      ],
      [
        {'query': 'banana', 'quantity': 1.5, 'portion': 'large'},
        {'query': 'salad', 'quantity': 200, 'unit': 'g', 'portion': 'medium'},
        {'query': 'bread', 'quantity': 1, 'portion': 'LARGE '},
      ],
      [
        {'query': 'apple', 'portion': 'large'},
        {'query': 'pizza', 'quantity': 3, 'portion': 'extra large'},
        {'query': 'edamame', 'quantity': 1, 'portion': 'mini'},
        {'query': 'celery', 'quantity': 2, 'portion': 'stalk'},
      ],
    ];
    for (final (i, plate) in plates.indexed) {
      test('plate $i', () async {
        final interpreter = ModelMealPhotoInterpreter(_FixedApi(plate));
        final result = await interpreter.interpret(
          MealPhoto(bytes: Uint8List(0), mediaType: 'image/jpeg'),
        );
        final validated = validateParsedMealItems(mealItemsFromJson(plate));
        expect(result.items.length, validated.items.length);
        for (final (j, item) in validated.items.indexed) {
          final guard = tool.applyPhotoGuard(
            quantity: item.quantity,
            unit: item.unit,
            portion: item.portion,
          );
          expect(result.items[j].quantity, guard.quantity, reason: 'item $j');
          expect(result.items[j].unit, isNull, reason: 'item $j');
          expect(result.items[j].portion, guard.portion, reason: 'item $j');
        }
      });
    }
  });

  group('the copied model ids agree with the catalogue', () {
    test('each provider default', () {
      expect(
        tool.defaultModelIds[tool.Provider.anthropic],
        AiModelCatalogue.defaultFor(AiProvider.anthropic)!.id,
      );
      expect(
        tool.defaultModelIds[tool.Provider.openrouter],
        AiModelCatalogue.defaultFor(AiProvider.openrouter)!.id,
      );
      expect(
        tool.defaultModelIds[tool.Provider.openai],
        AiModelCatalogue.defaultFor(AiProvider.openai)!.id,
      );
    });

    test('every catalogue id per provider', () {
      for (final provider in [
        (tool.Provider.anthropic, AiProvider.anthropic),
        (tool.Provider.openrouter, AiProvider.openrouter),
        (tool.Provider.openai, AiProvider.openai),
      ]) {
        expect(tool.catalogueModelIds[provider.$1], {
          for (final m in AiModelCatalogue.forProvider(provider.$2)) m.id,
        });
      }
    });

    test('the OpenRouter pins', () {
      for (final model in AiModelCatalogue.forProvider(AiProvider.openrouter)) {
        expect(tool.openRouterPins[model.id], model.providers);
      }
    });
  });
}
