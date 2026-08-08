import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_nutriments_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/usecase/resolve_parsed_meals_usecase.dart';
import 'package:opennutritracker/features/add_meal/domain/usecase/search_products_usecase.dart';
import 'package:opennutritracker/features/add_meal/util/meal_text_parser.dart';

MealEntity meal(
  String name, {
  MealSourceEntity source = MealSourceEntity.off,
}) => MealEntity(
  code: name,
  name: name,
  url: null,
  mealQuantity: null,
  mealUnit: null,
  servingQuantity: null,
  servingUnit: null,
  servingSize: null,
  source: source,
  nutriments: MealNutrimentsEntity.empty(),
);

/// Records call order so the concurrency assertion can tell "all searches
/// started before any finished" from "each waited for the last".
class _FakeSearch implements SearchProductsUseCase {
  final Map<String, List<MealEntity>> off;
  final Map<String, List<MealEntity>> supabase;
  final Set<String> throwOff;
  final Set<String> throwSupabase;
  final List<String> started = [];
  final List<String> finished = [];
  int maxConcurrent = 0;
  int _inFlight = 0;

  _FakeSearch({
    Map<String, List<MealEntity>>? off,
    Map<String, List<MealEntity>>? supabase,
    Set<String>? throwOff,
    Set<String>? throwSupabase,
  }) : off = off ?? {},
       supabase = supabase ?? {},
       throwOff = throwOff ?? {},
       throwSupabase = throwSupabase ?? {};

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
  }) async {
    if (throwSupabase.contains(searchString)) {
      started.add('sp:$searchString');
      throw StateError('Supabase is down');
    }
    return _respond('sp', searchString, supabase);
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
}
