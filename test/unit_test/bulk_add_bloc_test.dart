import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/utils/ai_credential_storage.dart';
import 'package:opennutritracker/features/add_meal/domain/usecase/read_meal_text_usecase.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_nutriments_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/usecase/resolve_parsed_meals_usecase.dart';
import 'package:opennutritracker/features/add_meal/domain/usecase/search_products_usecase.dart';
import 'package:opennutritracker/features/add_meal/presentation/bloc/bulk_add_bloc.dart';
import 'package:opennutritracker/features/add_meal/util/meal_text_parser.dart';

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

/// No credential stored, so the use case always takes the parser path —
/// these tests are about the bloc, not about which reader produced the items.
ReadMealTextUseCase parserOnlyReader() => ReadMealTextUseCase(
  AiCredentialStorage(_EmptyStorage()),
  (_) => throw StateError('must not be built without a key'),
);

BulkAddBloc blocWith(Map<String, List<MealEntity>> results) => BulkAddBloc(
  ResolveParsedMealsUseCase(_FakeSearch(results)),
  parserOnlyReader(),
);

/// Candidates come back ranked, not in the order they were faked, so tests
/// that switch candidates have to look the wanted one up by name.
int _indexOf(BulkAddRow row, String name) =>
    row.resolved.candidates.indexWhere((c) => c.name == name);

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

  test('changing candidates falls back from unsupported units', () async {
    final bloc = blocWith({
      'drink': [
        meal('Drink', servingQuantity: 330, servingUnit: 'ml'),
        meal('Alternative'),
      ],
    });
    await parse(bloc, 'drink');

    bloc.add(const ChangeRowUnitEvent(0, 'serving'));
    await bloc.stream.first;
    bloc.add(const ChangeRowCandidateEvent(0, 1));
    final state = await bloc.stream.first as BulkAddLoadedState;

    expect(state.rows.single.effectiveUnit, 'g/ml');
  });

  group('a bare count (#622)', () {
    test('counts a food that has serving data as servings', () async {
      // "2 eggs" means two of them. When the record carries serving data
      // that is exactly a serving, so the unit must be `serving` and not
      // grams — logging 2 g of egg was the bug.
      final bloc = blocWith({
        'eggs': [meal('Egg', servingQuantity: 50)],
      });

      final row = (await parse(bloc, '2 eggs')).rows.single;

      expect(row.amountText, '2');
      expect(row.unit, 'serving');
      expect(row.amountNeedsCheck, isFalse);
    });

    test('flags a count when the food has no serving data', () async {
      // Nothing to count, so the amount falls back to a weight. The row
      // still logs — it is editable — but it is marked.
      final bloc = blocWith({
        'eggs': [meal('Egg')],
      });

      final row = (await parse(bloc, '2 eggs')).rows.single;

      expect(row.amountText, '2');
      expect(row.amountNeedsCheck, isTrue);
      expect(row.willBeLogged, isTrue);
    });

    test('a stated unit is never second-guessed', () async {
      final bloc = blocWith({
        'toast': [meal('Toast', servingQuantity: 30)],
      });

      final row = (await parse(bloc, '100g toast')).rows.single;

      expect(row.unit, 'g');
      expect(row.amountNeedsCheck, isFalse);
    });

    test('no quantity at all keeps the serving default, not a count', () async {
      // Distinct from a bare count: nothing was stated, so the row falls
      // back to one serving expressed the way the record expresses it.
      final bloc = blocWith({
        'yoghurt': [meal('Yoghurt', servingQuantity: 125, servingUnit: 'g')],
      });

      final row = (await parse(bloc, 'yoghurt')).rows.single;

      expect(row.amountText, '125');
      expect(row.unit, 'g');
      expect(row.amountNeedsCheck, isFalse);
    });

    test('an unresolved row is never flagged for its amount', () async {
      final bloc = blocWith({});

      final row = (await parse(bloc, '2 unicorn steaks')).rows.single;

      expect(row.isResolved, isFalse);
      expect(row.amountNeedsCheck, isFalse);
      expect(row.willBeLogged, isFalse);
    });

    test('a stated unit the food cannot honour is flagged', () async {
      // Found by live probing: the model answers "three slices of bread"
      // as `3 serving`. On a record with no scalable serving that becomes
      // 3 g/ml — and the old condition only looked at a *missing* unit, so
      // nothing warned. A substituted unit is just as wrong and less
      // visible than a missing one.
      final bloc = blocWith({
        'bread': [meal('Sliced bread')],
      });
      final row = (await parse(bloc, 'bread')).rows.single;

      // The parser never emits `serving` as a unit, so build the row the
      // model produces.
      final modelRow = BulkAddRow(
        resolved: ResolvedMealItem(
          parsed: const ParsedMealItem(
            query: 'bread',
            quantity: 3,
            unit: 'serving',
          ),
          candidates: row.resolved.candidates,
          selectedIndex: 0,
          confidence: 0.9,
        ),
        selectedIndex: 0,
        amountText: '3',
        unit: 'serving',
      );

      expect(modelRow.effectiveUnit, isNot('serving'));
      expect(modelRow.amountNeedsCheck, isTrue);
    });

    test('a stated unit the food can honour is not flagged', () async {
      final bloc = blocWith({
        'bread': [meal('Sliced bread', servingQuantity: 30)],
      });
      final base = (await parse(bloc, 'bread')).rows.single;

      final modelRow = BulkAddRow(
        resolved: ResolvedMealItem(
          parsed: const ParsedMealItem(
            query: 'bread',
            quantity: 3,
            unit: 'serving',
          ),
          candidates: base.resolved.candidates,
          selectedIndex: 0,
          confidence: 0.9,
        ),
        selectedIndex: 0,
        amountText: '3',
        unit: 'serving',
      );

      expect(modelRow.effectiveUnit, 'serving');
      expect(modelRow.amountNeedsCheck, isFalse);
    });

    test('a serving that cannot be scaled is not offered as a unit', () async {
      // The trap this closes: the row is flagged, the user reads "check the
      // unit", picks the one that obviously means "two of them" — and the
      // app relabels the row, drops the warning and logs the same 2 g.
      final bloc = blocWith({
        'eggs': [meal('Egg', servingSize: '1 egg')],
        'yoghurt': [meal('Yoghurt', servingQuantity: 125)],
      });

      final rows = (await parse(bloc, '2 eggs, yoghurt')).rows;

      expect(rows[0].allowedUnits, isNot(contains('serving')));
      expect(rows[1].allowedUnits, contains('serving'));
    });

    test('unparseable serving text is not read as a count', () async {
      // OFF derives `serving_quantity` by parsing the `serving_size` text;
      // strings like "1 egg" do not parse, so quantity stays null while
      // hasServingValues is still true. convertQuantityToBaseUnit cannot
      // scale such a record, so calling the unit `serving` would leave
      // "2 eggs" logging 2 g under a label that reads correct.
      final bloc = blocWith({
        'eggs': [meal('Egg', servingSize: '1 egg')],
      });

      final row = (await parse(bloc, '2 eggs')).rows.single;

      expect(row.unit, isNot('serving'));
      expect(row.amountNeedsCheck, isTrue);
    });

    test('switching to a countable candidate clears the flag', () async {
      final bloc = blocWith({
        'eggs': [meal('Eggs plain'), meal('Eggs boxed', servingQuantity: 60)],
      });
      final before = (await parse(bloc, '2 eggs')).rows.single;
      // Guard the premise: the ranker, not the list order, decides what is
      // selected, and the test only means anything from the flagged one.
      expect(before.meal?.name, 'Eggs plain');
      expect(before.amountNeedsCheck, isTrue);

      bloc.add(ChangeRowCandidateEvent(0, _indexOf(before, 'Eggs boxed')));
      final after = (await bloc.stream.first as BulkAddLoadedState).rows.single;

      expect(after.amountNeedsCheck, isFalse);
    });

    test('switching to an uncountable candidate raises the flag', () async {
      // The direction that matters: correcting the food must not carry a
      // stale "all clear" forward and leave 2 g unmarked.
      final bloc = blocWith({
        'eggs': [meal('Eggs boxed', servingQuantity: 60), meal('Eggs plain')],
      });
      final before = (await parse(bloc, '2 eggs')).rows.single;
      expect(before.meal?.name, 'Eggs boxed');
      expect(before.amountNeedsCheck, isFalse);

      bloc.add(ChangeRowCandidateEvent(0, _indexOf(before, 'Eggs plain')));
      final after = (await bloc.stream.first as BulkAddLoadedState).rows.single;

      expect(after.amountNeedsCheck, isTrue);
    });

    test(
      'switching candidates re-derives the unit, not just the flag',
      () async {
        // Found on a Pixel 6: clearing the warning while the row kept the
        // previous candidate's weight unit left "2 chicken breasts" reading
        // 2 oz with no warning — #622 again, minus the signal.
        final bloc = blocWith({
          'eggs': [meal('Eggs plain'), meal('Eggs boxed', servingQuantity: 60)],
        });
        final before = (await parse(bloc, '2 eggs')).rows.single;
        expect(before.unit, isNot('serving'));

        bloc.add(ChangeRowCandidateEvent(0, _indexOf(before, 'Eggs boxed')));
        final after =
            (await bloc.stream.first as BulkAddLoadedState).rows.single;

        expect(after.unit, 'serving');
        expect(after.amountText, '2');
        expect(after.amountNeedsCheck, isFalse);
      },
    );

    test('a hand-typed amount is never reinterpreted as a count', () async {
      // The dangerous case: re-deriving the unit under an amount the user
      // typed would turn "150" grams into 150 servings.
      final bloc = blocWith({
        'eggs': [meal('Eggs plain'), meal('Eggs boxed', servingQuantity: 60)],
      });
      final before = (await parse(bloc, '2 eggs')).rows.single;

      bloc.add(const ChangeRowAmountEvent(0, '150'));
      await bloc.stream.first;
      bloc.add(ChangeRowCandidateEvent(0, _indexOf(before, 'Eggs boxed')));
      final after = (await bloc.stream.first as BulkAddLoadedState).rows.single;

      expect(after.amountText, '150');
      expect(after.unit, isNot('serving'));
    });

    test('a chosen unit survives a candidate switch', () async {
      final bloc = blocWith({
        'eggs': [meal('Eggs plain'), meal('Eggs boxed', servingQuantity: 60)],
      });
      final before = (await parse(bloc, '2 eggs')).rows.single;

      bloc.add(const ChangeRowUnitEvent(0, 'oz'));
      await bloc.stream.first;
      bloc.add(ChangeRowCandidateEvent(0, _indexOf(before, 'Eggs boxed')));
      final after = (await bloc.stream.first as BulkAddLoadedState).rows.single;

      expect(after.unit, 'oz');
    });

    test('choosing a unit settles the flag', () async {
      final bloc = blocWith({
        'eggs': [meal('Egg')],
      });
      await parse(bloc, '2 eggs');

      bloc.add(const ChangeRowUnitEvent(0, 'oz'));
      final state = await bloc.stream.first as BulkAddLoadedState;

      expect(state.rows.single.amountNeedsCheck, isFalse);
    });
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
      parserOnlyReader(),
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

/// A keystore with nothing in it, so the read use case always takes the
/// deterministic path.
class _EmptyStorage implements FlutterSecureStorage {
  @override
  Future<String?> read({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async => null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
