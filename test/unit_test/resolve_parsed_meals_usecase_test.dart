import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_nutriments_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_portion_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/usecase/resolve_parsed_meals_usecase.dart';
import 'package:opennutritracker/features/add_meal/domain/usecase/search_products_usecase.dart';
import 'package:opennutritracker/features/add_meal/util/meal_text_parser.dart';

import '../fixture/backend_sibling_fixtures.dart';

MealEntity meal(
  String name, {
  MealSourceEntity source = MealSourceEntity.off,
  String? code,
  String? brands,
  double? servingQuantity,
  bool detailed = false,
  int portions = 0,
  bool machineTranslatedName = false,
}) => MealEntity(
  code: code ?? name,
  name: name,
  brands: brands,
  url: null,
  mealQuantity: null,
  mealUnit: null,
  servingQuantity: servingQuantity,
  servingUnit: null,
  servingSize: null,
  source: source,
  detailed: detailed,
  machineTranslatedName: machineTranslatedName,
  portions: [
    for (var i = 0; i < portions; i++)
      MealPortionEntity(
        label: '1 portion $i',
        gramWeight: 50,
        localized: false,
      ),
  ],
  nutriments: MealNutrimentsEntity.empty(),
);

/// Records call order so the concurrency assertion can tell "all searches
/// started before any finished" from "each waited for the last".
class _FakeSearch implements SearchProductsUseCase {
  final Map<String, List<MealEntity>> off;
  final Map<String, List<MealEntity>> supabase;
  final Set<String> throwOff;
  final Set<String> throwSupabase;

  /// The full Open Food Facts record behind a thin hit, by code; a code in
  /// [throwFullRecord] fails the lookup instead.
  final Map<String, MealEntity> fullRecords;
  final Set<String> throwFullRecord;
  final List<String> fullRecordLookups = [];
  final List<String> started = [];
  final List<String> finished = [];
  int maxConcurrent = 0;
  int _inFlight = 0;

  _FakeSearch({
    Map<String, List<MealEntity>>? off,
    Map<String, List<MealEntity>>? supabase,
    Set<String>? throwOff,
    Set<String>? throwSupabase,
    Map<String, MealEntity>? fullRecords,
    Set<String>? throwFullRecord,
  }) : off = off ?? {},
       supabase = supabase ?? {},
       throwOff = throwOff ?? {},
       throwSupabase = throwSupabase ?? {},
       fullRecords = fullRecords ?? {},
       throwFullRecord = throwFullRecord ?? {};

  Future<SearchProductsResult> _respond(
    String tag,
    String query,
    Map<String, List<MealEntity>> from,
  ) async {
    started.add('$tag:$query');
    _inFlight++;
    if (_inFlight > maxConcurrent) maxConcurrent = _inFlight;
    // Yield so every caller gets to start before any completes.
    await Future<void>.delayed(Duration.zero);
    _inFlight--;
    finished.add('$tag:$query');
    return SearchProductsResult(
      meals: from[query] ?? const [],
      remoteSourceEmpty: false,
    );
  }

  @override
  Future<SearchProductsResult> searchOFFProductsByString(
    String searchString, {
    bool skipRemote = false,
  }) async {
    if (throwOff.contains(searchString)) {
      started.add('off:$searchString');
      throw StateError('OFF is down');
    }
    return _respond('off', searchString, off);
  }

  @override
  Future<SearchProductsResult> searchFDCFoodByString(
    String searchString, {
    bool skipRemote = false,
    bool forResolution = false,
  }) async {
    if (throwSupabase.contains(searchString)) {
      started.add('sp:$searchString');
      throw StateError('Supabase is down');
    }
    return _respond('sp', searchString, supabase);
  }

  @override
  Future<MealEntity?> fetchFullOffRecord(MealEntity meal) async {
    final code = meal.code!;
    fullRecordLookups.add(code);
    if (throwFullRecord.contains(code)) throw StateError('OFF is down');
    return fullRecords[code];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

ParsedMealItem item(String query, {double? quantity, String? unit}) =>
    ParsedMealItem(query: query, quantity: quantity, unit: unit);

void main() {
  test('each parsed item gets its own candidate list', () async {
    final search = _FakeSearch(
      off: {
        'toast': [meal('Toast')],
        'eggs': [meal('Egg')],
      },
    );

    final resolved = await ResolveParsedMealsUseCase(search).resolve([
      item('toast', quantity: 100, unit: 'g'),
      item('eggs', quantity: 2),
    ]);

    expect(resolved, hasLength(2));
    expect(resolved[0].selected!.name, 'Toast');
    expect(resolved[1].selected!.name, 'Egg');
    // The parsed item is carried through untouched — the review screen
    // needs the quantity the user typed, not one the resolver invented.
    expect(resolved[0].parsed.quantity, 100);
    expect(resolved[1].parsed.unit, isNull);
  });

  test('an item with no matches comes back unresolved, not dropped', () async {
    final search = _FakeSearch(
      off: {
        'toast': [meal('Toast')],
      },
    );

    final resolved = await ResolveParsedMealsUseCase(
      search,
    ).resolve([item('toast'), item('unicorn steak')]);

    expect(resolved, hasLength(2));
    expect(resolved[1].isResolved, isFalse);
    expect(resolved[1].candidates, isEmpty);
    expect(resolved[1].confidence, 0.0);
    // Still carries the parsed item so the row can be shown and fixed.
    expect(resolved[1].parsed.query, 'unicorn steak');
  });

  test('results from both sources are merged and ranked together', () async {
    final search = _FakeSearch(
      off: {
        'eggs': [meal('Cadbury Creme Eggs')],
      },
      supabase: {
        'eggs': [meal('Egg')],
      },
    );

    final resolved = await ResolveParsedMealsUseCase(
      search,
    ).resolve([item('eggs')]);

    expect(
      resolved.single.candidates.map((m) => m.name),
      containsAll(['Egg', 'Cadbury Creme Eggs']),
    );
    // The whole point of #601: the inflected match wins the selection.
    expect(resolved.single.selected!.name, 'Egg');
  });

  test('own content is selected over a better-scoring remote result', () async {
    final search = _FakeSearch(
      off: {
        'eggs': [meal('Egg')],
      },
      supabase: {
        'eggs': [meal('My scrambled eggs', source: MealSourceEntity.custom)],
      },
    );

    final resolved = await ResolveParsedMealsUseCase(
      search,
    ).resolve([item('eggs')]);

    expect(resolved.single.selected!.source, MealSourceEntity.custom);
  });

  test('one source throwing still yields results from the other', () async {
    final search = _FakeSearch(
      supabase: {
        'toast': [meal('Toast')],
      },
      throwOff: {'toast'},
    );

    // The real SearchProductsUseCase degrades internally rather than
    // throwing, so this guards against that changing: a source erroring
    // must narrow the candidate list, never fail the item or the batch.
    final resolved = await ResolveParsedMealsUseCase(
      search,
    ).resolve([item('toast')]);

    expect(resolved.single.isResolved, isTrue);
    expect(resolved.single.selected!.name, 'Toast');
  });

  test(
    'both sources throwing yields an unresolved item, not an exception',
    () async {
      final search = _FakeSearch(throwOff: {'toast'}, throwSupabase: {'toast'});

      final resolved = await ResolveParsedMealsUseCase(
        search,
      ).resolve([item('toast')]);

      expect(resolved.single.isResolved, isFalse);
      expect(resolved.single.parsed.query, 'toast');
    },
  );

  test('one item failing does not lose the other items in the batch', () async {
    final search = _FakeSearch(
      off: {
        'eggs': [meal('Egg')],
      },
      throwOff: {'toast'},
      throwSupabase: {'toast'},
    );

    final resolved = await ResolveParsedMealsUseCase(
      search,
    ).resolve([item('toast'), item('eggs')]);

    expect(resolved, hasLength(2));
    expect(resolved[0].isResolved, isFalse);
    expect(resolved[1].selected!.name, 'Egg');
  });

  test('searches run concurrently, not one item after another', () async {
    final search = _FakeSearch(
      off: {
        'a': [meal('A')],
        'b': [meal('B')],
        'c': [meal('C')],
      },
    );

    await ResolveParsedMealsUseCase(
      search,
    ).resolve([item('a'), item('b'), item('c')]);

    // 3 items x 2 sources. If this were serial, maxConcurrent would be 1.
    expect(search.started, hasLength(6));
    expect(search.maxConcurrent, greaterThan(1));
  });

  test('an empty item list does no searching at all', () async {
    final search = _FakeSearch();

    expect(await ResolveParsedMealsUseCase(search).resolve([]), isEmpty);
    expect(search.started, isEmpty);
  });

  test('a weak top match is flagged low-confidence', () async {
    final search = _FakeSearch(
      off: {
        'eggs': [meal('Cadbury Creme Eggs Multipack 5 Pack')],
      },
    );

    final resolved = await ResolveParsedMealsUseCase(
      search,
    ).resolve([item('eggs')]);

    expect(resolved.single.isResolved, isTrue);
    expect(resolved.single.isLowConfidence, isTrue);
  });

  test('a strong top match is not flagged', () async {
    final search = _FakeSearch(
      off: {
        'toast': [meal('Toast')],
      },
    );

    final resolved = await ResolveParsedMealsUseCase(
      search,
    ).resolve([item('toast')]);

    expect(resolved.single.isLowConfidence, isFalse);
    expect(resolved.single.confidence, greaterThan(kResolutionConfidenceFloor));
  });

  group('backend siblings through the use case (#1164)', () {
    // Real backend rows; see the fixture for where the numbers come from.
    test('egg keeps every sibling as a candidate, yolk included', () async {
      final search = _FakeSearch(supabase: {'egg': BackendSiblingFixtures.egg});

      final resolved = await ResolveParsedMealsUseCase(
        search,
      ).resolve([item('egg', quantity: 2)]);

      expect(resolved.single.candidates, hasLength(4));
      expect(
        resolved.single.candidates.map((m) => m.name),
        contains('Egg, yolk only, raw'),
      );
    });

    test('apple auto-selects Apple, raw by its description', () async {
      final search = _FakeSearch(
        supabase: {'apple': BackendSiblingFixtures.apple},
      );

      final resolved = await ResolveParsedMealsUseCase(
        search,
      ).resolve([item('apple', quantity: 1)]);

      expect(resolved.single.selected!.name, 'Apple, raw');
      expect(resolved.single.selected!.portions, hasLength(7));
    });

    test('eggs resolves above the floor, to the record egg does', () async {
      // The #601 case this scorer exists for: a plural query against the
      // survey family. Scored on their titles the four tie at 0.75 — the
      // `eggs` → `Egg` match the floor was set against — and the length
      // key picks "Egg, creamed", the pinned known miss (#1170), as it
      // does on `egg`; scored on the description it showed, "Egg, whole,
      // raw" was 0.375 and flagged as a guess.
      final search = _FakeSearch(
        supabase: {'eggs': BackendSiblingFixtures.egg},
      );

      final resolved = await ResolveParsedMealsUseCase(
        search,
      ).resolve([item('eggs', quantity: 2)]);

      expect(resolved.single.selected!.name, 'Egg, creamed');
      expect(resolved.single.confidence, closeTo(0.75, 1e-9));
      expect(
        resolved.single.confidence,
        greaterThanOrEqualTo(kResolutionConfidenceFloor),
      );
      expect(resolved.single.isLowConfidence, isFalse);
    });

    test('orange juice auto-selects the survey record over BLS', () async {
      // Both titles match the query exactly; the −0.15 for carrying no
      // portion is what puts the BLS record second, and the confidence
      // reported is the survey record's unpenalised 1.0.
      final search = _FakeSearch(
        supabase: {'orange juice': BackendSiblingFixtures.orangeJuice},
      );

      final resolved = await ResolveParsedMealsUseCase(
        search,
      ).resolve([item('orange juice')]);

      expect(resolved.single.selected!.name, 'Orange juice, 100%, NFS');
      expect(resolved.single.confidence, 1.0);
      expect(resolved.single.candidates.map((m) => m.name), [
        'Orange juice, 100%, NFS',
        'Orange juice',
      ]);
    });

    test(
      'dried apple auto-selects Apple, dried, not the most-portioned',
      () async {
        // The review's finding against the title-only revision, through the
        // use case: every "Apple" tied at 0.667 on the title, the tie-break
        // picked "Apple, raw", and at 0.667 nothing flagged it
        // — a silently wrong food at a quarter of the kcal. The page is
        // listed everyday-form first so the input order cannot be what picks
        // the winner either.
        final search = _FakeSearch(
          supabase: {
            'dried apple': [
              BackendSiblingFixtures.appleRaw,
              BackendSiblingFixtures.appleDried,
              BackendSiblingFixtures.appleBaked,
            ],
          },
        );

        final resolved = await ResolveParsedMealsUseCase(
          search,
        ).resolve([item('dried apple', quantity: 30, unit: 'g')]);

        expect(resolved.single.selected!.name, 'Apple, dried');
        expect(resolved.single.confidence, 1.0);
        expect(resolved.single.isLowConfidence, isFalse);
        expect(resolved.single.candidates.map((m) => m.name), [
          'Apple, dried',
          'Apple, raw',
          'Apple, baked',
        ]);
      },
    );

    test('egg yolk auto-selects the yolk record over the boiled egg', () async {
      final search = _FakeSearch(
        supabase: {
          'egg yolk': [
            BackendSiblingFixtures.eggWholeBoiledOrPoached,
            BackendSiblingFixtures.eggWholeRaw,
            BackendSiblingFixtures.eggCreamed,
            BackendSiblingFixtures.eggYolkOnlyRaw,
          ],
        },
      );

      final resolved = await ResolveParsedMealsUseCase(
        search,
      ).resolve([item('egg yolk', quantity: 2)]);

      expect(resolved.single.selected!.name, 'Egg, yolk only, raw');
      expect(resolved.single.confidence, 1.0);
      expect(resolved.single.candidates, hasLength(4));
    });

    test('the confidence reported is the penalised score', () async {
      // The selected candidate's score is what the review screen shows;
      // for a portionless backend record that is the score after the
      // penalty, not before, so the two never disagree.
      final search = _FakeSearch(
        supabase: {
          'orange juice': [BackendSiblingFixtures.orangeJuiceBls],
        },
      );

      final resolved = await ResolveParsedMealsUseCase(
        search,
      ).resolve([item('orange juice')]);

      expect(resolved.single.confidence, closeTo(0.85, 1e-9));
    });
  });

  group('a counted item looks behind thin Open Food Facts hits (#1472)', () {
    // "2 Eier und eine Scheibe Vollkornbrot", as the 2.6.0 Pixel run read
    // it. The pools are shaped like the live ones: a text-search hit from
    // Open Food Facts carries no serving fields, and the German backend
    // pool holds a portionless BLS record and an FDC survey dish with
    // portions. Only some full product records declare a serving.
    MealEntity thin(String name, String brand) =>
        meal(name, code: brand, brands: brand);
    MealEntity full(String name, String brand, {double? serving}) => meal(
      name,
      code: brand,
      brands: brand,
      servingQuantity: serving,
      detailed: true,
    );

    final offEier = [thin('Eier', 'lidl'), thin('Eier', 'aldi')];
    final backendEier = [
      meal('Eier gekocht', source: MealSourceEntity.fdc, code: '10003161'),
      meal(
        'Eier Benedict',
        source: MealSourceEntity.fdc,
        code: '2707180',
        portions: 3,
        servingQuantity: 200,
        machineTranslatedName: true,
      ),
    ];
    final offBrot = [
      thin('Vollkornbrot', 'kaufland'),
      thin('Vollkornbrot', 'jacquet'),
    ];
    final backendBrot = [
      meal('Vollkornbrot', source: MealSourceEntity.fdc, code: '10002122'),
      meal(
        'Brot, Vollkornbrot, nach eigenem Rezept gebacken oder in der '
        'Bäckerei gekauft',
        source: MealSourceEntity.fdc,
        code: '2707711',
        portions: 4,
        servingQuantity: 32,
        machineTranslatedName: true,
      ),
    ];
    final fullRecords = {
      'lidl': full('Eier', 'lidl'),
      'aldi': full('Eier', 'aldi', serving: 59),
      'kaufland': full('Vollkornbrot', 'kaufland'),
      'jacquet': full('Vollkornbrot', 'jacquet', serving: 62.5),
    };

    _FakeSearch search({
      Map<String, MealEntity>? records,
      Set<String>? throwFullRecord,
    }) => _FakeSearch(
      off: {'Eier': offEier, 'Vollkornbrot': offBrot},
      supabase: {'Eier': backendEier, 'Vollkornbrot': backendBrot},
      fullRecords: records ?? fullRecords,
      throwFullRecord: throwFullRecord,
    );

    const eggs = ParsedMealItem(query: 'Eier', quantity: 2);
    const slice = ParsedMealItem(
      query: 'Vollkornbrot',
      quantity: 1,
      portion: 'slice',
    );

    test('the product that declares a serving is selected', () async {
      final resolved = await ResolveParsedMealsUseCase(
        search(),
      ).resolve([eggs, slice]);

      expect(resolved[0].selected!.brands, 'aldi');
      expect(resolved[0].selected!.servingQuantity, 59);
      expect(resolved[1].selected!.brands, 'jacquet');
      expect(resolved[1].selected!.servingQuantity, 62.5);
      // The full records take the thin hits' places in the list.
      expect(
        resolved[0].candidates.where((m) => m.source == MealSourceEntity.off),
        everyElement(predicate<MealEntity>((m) => m.detailed)),
      );
    });

    test('nothing countable keeps the plain food, never a dish', () async {
      final resolved = await ResolveParsedMealsUseCase(
        search(records: const {}),
      ).resolve([eggs]);

      // Held back on the review screen, as #973 decided — but still eggs.
      expect(resolved.single.selected!.name, 'Eier');
      expect(resolved.single.selected!.servingQuantity, isNull);
    });

    test('a failed lookup leaves the thin hit and fails nothing', () async {
      final resolved = await ResolveParsedMealsUseCase(
        search(throwFullRecord: {'lidl', 'aldi'}),
      ).resolve([eggs]);

      expect(resolved.single.isResolved, isTrue);
      expect(resolved.single.selected!.name, 'Eier');
    });

    test('a weight or no number at all looks nothing up', () async {
      final fake = search();
      await ResolveParsedMealsUseCase(fake).resolve([
        const ParsedMealItem(query: 'Eier', quantity: 120, unit: 'g'),
        const ParsedMealItem(query: 'Vollkornbrot'),
      ]);

      expect(fake.fullRecordLookups, isEmpty);
    });

    test('a stated serving counts as a count', () async {
      final resolved = await ResolveParsedMealsUseCase(search()).resolve([
        const ParsedMealItem(query: 'Eier', quantity: 2, unit: 'serving'),
      ]);

      expect(resolved.single.selected!.brands, 'aldi');
    });

    test(
      'a hit that cannot overtake the first candidate is not looked up',
      () async {
        // "Frische Eier" scores 0.667 on `Eier`; the first candidate's sort
        // score is 0.85, so even a serving would not move it.
        final fake = _FakeSearch(
          off: {
            'Eier': [thin('Eier', 'lidl'), thin('Frische Eier', 'rewe')],
          },
        );
        await ResolveParsedMealsUseCase(fake).resolve([eggs]);

        expect(fake.fullRecordLookups, ['lidl']);
      },
    );

    test('the bound counts what a hit gains once detailed', () async {
      // A cached, detailed "Apple" with no serving sorts at 0.85 under the
      // count; thin "Apples" scores 0.833 but 0.863 once detailed, and its
      // full record declares a serving, so it has to be looked up.
      final fake = _FakeSearch(
        off: {
          'apple': [full('Apple', 'cached'), thin('Apples', 'bag')],
        },
        fullRecords: {'bag': full('Apples', 'bag', serving: 150)},
      );
      final resolved = await ResolveParsedMealsUseCase(
        fake,
      ).resolve([const ParsedMealItem(query: 'apple', quantity: 2)]);

      expect(fake.fullRecordLookups, ['bag']);
      expect(resolved.single.selected!.brands, 'bag');
    });

    test('a first candidate that can already count needs no lookup', () async {
      final fake = _FakeSearch(
        off: {
          'Eier': [full('Eier', 'aldi', serving: 59), thin('Eier', 'lidl')],
        },
      );
      final resolved = await ResolveParsedMealsUseCase(fake).resolve([eggs]);

      expect(fake.fullRecordLookups, isEmpty);
      expect(resolved.single.selected!.brands, 'aldi');
    });

    test('no more than five hits are looked up for one item', () async {
      final fake = _FakeSearch(
        off: {
          'Eier': [for (var i = 0; i < 8; i++) thin('Eier', 'brand$i')],
        },
      );
      await ResolveParsedMealsUseCase(fake).resolve([eggs]);

      expect(fake.fullRecordLookups, hasLength(5));
    });
  });
}
