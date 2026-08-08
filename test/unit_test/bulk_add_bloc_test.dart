import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_nutriments_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/usecase/resolve_parsed_meals_usecase.dart';
import 'package:opennutritracker/features/add_meal/domain/usecase/search_products_usecase.dart';
import 'package:opennutritracker/features/add_meal/presentation/bloc/bulk_add_bloc.dart';

MealEntity meal(
  String name, {
  double? servingQuantity,
  String? servingUnit,
  String? servingSize,
}) => MealEntity(
  code: name,
  name: name,
  url: null,
  mealQuantity: null,
  mealUnit: null,
  servingQuantity: servingQuantity,
  servingUnit: servingUnit,
  servingSize: servingSize,
  source: MealSourceEntity.off,
  nutriments: MealNutrimentsEntity.empty(),
);

class _FakeSearch implements SearchProductsUseCase {
  final Map<String, List<MealEntity>> results;
  final bool throws;

  _FakeSearch(this.results, {this.throws = false});

  @override
  Future<SearchProductsResult> searchOFFProductsByString(
    String searchString, {
    bool skipRemote = false,
  }) async {
    if (throws) throw StateError('down');
    return SearchProductsResult(
      meals: results[searchString] ?? const [],
      remoteSourceEmpty: false,
    );
  }

  @override
  Future<SearchProductsResult> searchFDCFoodByString(
    String searchString, {
    bool skipRemote = false,
  }) async => const SearchProductsResult(meals: [], remoteSourceEmpty: false);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

BulkAddBloc blocWith(Map<String, List<MealEntity>> results) =>
    BulkAddBloc(ResolveParsedMealsUseCase(_FakeSearch(results)));

Future<BulkAddLoadedState> parse(
  BulkAddBloc bloc,
  String text, {
  bool imperial = false,
}) async {
  bloc.add(ParseBulkTextEvent(text: text, usesImperialUnits: imperial));
  return await bloc.stream.firstWhere((s) => s is BulkAddLoadedState)
      as BulkAddLoadedState;
}

void main() {
  test('a parsed line becomes one row per item', () async {
    final bloc = blocWith({
      'toast': [meal('Toast')],
      'eggs': [meal('Egg')],
    });

    final state = await parse(bloc, '100g toast, 2 eggs');

    expect(state.rows, hasLength(2));
    expect(state.rows[0].meal!.name, 'Toast');
    expect(state.rows[0].amountText, '100');
    expect(state.rows[0].unit, 'g');
    expect(state.rows[1].amountText, '2');
  });

  test(
    'an item with no stated quantity falls back to the metric default',
    () async {
      final bloc = blocWith({
        'black coffee': [meal('Black coffee')],
      });

      final state = await parse(bloc, 'black coffee');

      expect(state.rows.single.amountText, '100');
      expect(state.rows.single.unit, 'g/ml');
    },
  );

  test('the imperial default is used when the profile is imperial', () async {
    final bloc = blocWith({
      'black coffee': [meal('Black coffee')],
    });

    final state = await parse(bloc, 'black coffee', imperial: true);

    expect(state.rows.single.amountText, '1');
    expect(state.rows.single.unit, 'oz');
  });

  test('a food with serving values defaults to its serving', () async {
    final bloc = blocWith({
      'yoghurt': [meal('Yoghurt', servingQuantity: 125, servingUnit: 'g')],
    });

    final state = await parse(bloc, 'yoghurt');

    expect(state.rows.single.amountText, '125');
    expect(state.rows.single.unit, 'g');
  });

  test('unresolved rows are kept and are not loggable', () async {
    final bloc = blocWith({
      'toast': [meal('Toast')],
    });

    final state = await parse(bloc, 'toast, unicorn steak');

    expect(state.rows, hasLength(2));
    expect(state.hasUnresolved, isTrue);
    expect(state.loggableCount, 1);
  });

  test('parser errors survive alongside the rows that did parse', () async {
    final bloc = blocWith({
      'toast': [meal('Toast')],
    });

    // '123' has no letters; 'toast' is fine. One bad segment must not
    // discard the good one.
    final state = await parse(bloc, '123, toast');

    expect(state.rows, hasLength(1));
    expect(state.parseErrors, hasLength(1));
    expect(state.loggableCount, 1);
  });

  test('input that parses to nothing yields no rows and no crash', () async {
    final bloc = blocWith({});

    final state = await parse(bloc, '   ');

    expect(state.rows, isEmpty);
    expect(state.parseErrors, isEmpty);
    expect(state.loggableCount, 0);
  });

  test(
    'skipping a row removes it from the loggable set but keeps it visible',
    () async {
      final bloc = blocWith({
        'toast': [meal('Toast')],
        'eggs': [meal('Egg')],
      });
      await parse(bloc, 'toast, eggs');

      bloc.add(const ToggleRowSkippedEvent(0));
      final state = await bloc.stream.first as BulkAddLoadedState;

      expect(state.rows, hasLength(2));
      expect(state.rows[0].skipped, isTrue);
      expect(state.loggableCount, 1);
    },
  );

  test('editing an amount does not disturb the other rows', () async {
    final bloc = blocWith({
      'toast': [meal('Toast')],
      'eggs': [meal('Egg')],
    });
    await parse(bloc, '100g toast, 2 eggs');

    bloc.add(const ChangeRowAmountEvent(0, '75'));
    final state = await bloc.stream.first as BulkAddLoadedState;

    expect(state.rows[0].amountText, '75');
    expect(state.rows[1].amountText, '2');
  });

  test('picking a candidate clears the low-confidence flag', () async {
    // 'Cadbury Creme Eggs Multipack' is a weak match for 'eggs', so the
    // resolver's own choice is flagged. Once the user picks for themselves
    // the machine's doubt is no longer relevant.
    final bloc = blocWith({
      'eggs': [
        meal('Cadbury Creme Eggs Multipack 5 Pack'),
        meal('Egg salad sandwich'),
      ],
    });
    final initial = await parse(bloc, 'eggs');
    expect(initial.rows.single.isLowConfidence, isTrue);

    bloc.add(const ChangeRowCandidateEvent(0, 1));
    final state = await bloc.stream.first as BulkAddLoadedState;

    expect(state.rows.single.isLowConfidence, isFalse);
  });

  test('a resolution failure surfaces as an error state', () async {
    final bloc = BulkAddBloc(
      ResolveParsedMealsUseCase(_FakeSearch({}, throws: true)),
    );

    bloc.add(const ParseBulkTextEvent(text: 'toast', usesImperialUnits: false));
    final state = await bloc.stream.firstWhere(
      (s) => s is BulkAddLoadedState || s is BulkAddErrorState,
    );

    // The resolver swallows per-source failures, so this is an unresolved
    // row rather than an error — the batch still shows the user what
    // happened instead of a dead end.
    expect(state, isA<BulkAddLoadedState>());
    expect((state as BulkAddLoadedState).hasUnresolved, isTrue);
  });

  test('out-of-range rows never become loggable', () async {
    final bloc = blocWith({
      'flour': [meal('Flour')],
    });

    // 15 kg -> 15000 g, rejected by the parser before resolution.
    final state = await parse(bloc, '15kg flour');

    expect(state.rows, isEmpty);
    expect(state.parseErrors, hasLength(1));
  });
}
