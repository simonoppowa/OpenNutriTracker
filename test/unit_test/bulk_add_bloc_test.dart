import 'dart:typed_data';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/utils/ai_credential_storage.dart';
import 'package:opennutritracker/features/add_meal/domain/meal_photo_interpreter.dart';
import 'package:opennutritracker/features/add_meal/domain/meal_text_interpreter.dart';
import 'package:opennutritracker/features/add_meal/domain/usecase/read_meal_photo_usecase.dart';
import 'package:opennutritracker/features/add_meal/domain/usecase/read_meal_text_usecase.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_nutriments_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_portion_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/usecase/resolve_parsed_meals_usecase.dart';
import 'package:opennutritracker/features/add_meal/domain/usecase/search_products_usecase.dart';
import 'package:opennutritracker/features/add_meal/presentation/bloc/bulk_add_bloc.dart';
import 'package:opennutritracker/features/add_meal/util/meal_text_parser.dart';

MealEntity meal(
  String name, {
  double? servingQuantity,
  String? servingUnit,
  String? servingSize,
  String? mealUnit,
  List<MealPortionEntity> portions = const [],
}) => MealEntity(
  code: name,
  name: name,
  url: null,
  mealQuantity: null,
  mealUnit: mealUnit,
  servingQuantity: servingQuantity,
  servingUnit: servingUnit,
  servingSize: servingSize,
  portions: portions,
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

/// Same idea for photos: no credential, so the use case reports the feature
/// unavailable without ever building an interpreter.
ReadMealPhotoUseCase photoReaderWithoutKey() => ReadMealPhotoUseCase(
  AiCredentialStorage(_EmptyStorage()),
  (_) => throw StateError('must not be built without a key'),
);

/// A key *is* stored here, so the use case really builds an interpreter and
/// really takes the model path — which is the only way to exercise what
/// happens when that path fails.
ReadMealTextUseCase readerFailingWith(MealInterpreterException failure) {
  return ReadMealTextUseCase(
    AiCredentialStorage(
      _MapStorage({
        'AiApiKeyTag.anthropic': 'sk-test',
        'AiAssistEnabledTag': 'true',
      }),
    ),
    (_) => _AlwaysFailsInterpreter(failure),
  );
}

class _AlwaysFailsInterpreter implements MealTextInterpreter {
  final MealInterpreterException failure;

  _AlwaysFailsInterpreter(this.failure);

  @override
  Future<MealTextParseResult> interpret(String input, {String? localeCode}) =>
      throw failure;
}

/// A model that answers with exactly these items. The sibling of
/// [readerFailingWith]: a key is stored, so the use case really takes the
/// model path rather than falling back to the parser.
ReadMealTextUseCase readerReturning(List<ParsedMealItem> items) =>
    ReadMealTextUseCase(
      AiCredentialStorage(
        _MapStorage({
          'AiApiKeyTag.anthropic': 'sk-test',
          'AiAssistEnabledTag': 'true',
        }),
      ),
      (_) => _FixedInterpreter(items),
    );

class _FixedInterpreter implements MealTextInterpreter {
  final List<ParsedMealItem> items;

  _FixedInterpreter(this.items);

  @override
  Future<MealTextParseResult> interpret(String input, {String? localeCode}) async =>
      MealTextParseResult(items: items, errors: const []);
}

BulkAddBloc blocWithModelReply(
  Map<String, List<MealEntity>> results,
  List<ParsedMealItem> items,
) => BulkAddBloc(
  ResolveParsedMealsUseCase(_FakeSearch(results)),
  readerReturning(items),
  photoReaderWithoutKey(),
);

BulkAddBloc blocWithFailingReader(
  Map<String, List<MealEntity>> results,
  MealInterpreterException failure,
) => BulkAddBloc(
  ResolveParsedMealsUseCase(_FakeSearch(results)),
  readerFailingWith(failure),
  photoReaderWithoutKey(),
);

BulkAddBloc blocWith(
  Map<String, List<MealEntity>> results, {
  ReadMealPhotoUseCase? photoReader,
}) => BulkAddBloc(
  ResolveParsedMealsUseCase(_FakeSearch(results)),
  parserOnlyReader(),
  photoReader ?? photoReaderWithoutKey(),
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

  // The amount field accepts at most two decimals, and the same anchored
  // pattern is both the submit check and the field's input formatter. A
  // prefill it refuses is a row that cannot be logged and cannot be edited
  // back into shape — the field blanks on the first keystroke — and the
  // submit check aborts the whole batch on it. The pattern itself rather
  // than a copy of it: a copy is a test that can pass while the check it
  // claims to speak for says something else.
  final fieldPattern = bulkAddQuantityPattern;

  test(
    'a pound quantity is prefilled at a precision the field accepts',
    () async {
      final bloc = blocWith({
        'mince': [meal('Mince')],
      });

      // 1 lb is 453.59237 g. Prefilled verbatim it was unloggable.
      final state = await parse(bloc, '1 lb mince');

      expect(state.rows.single.amountText, '453.59');
      expect(state.rows.single.unit, 'g');
      expect(fieldPattern.hasMatch(state.rows.single.amountText), isTrue);
    },
  );

  test('one refused row no longer blocks the rows beside it', () async {
    final bloc = blocWith({
      'mince': [meal('Mince')],
      'rice': [meal('Rice')],
    });

    final state = await parse(bloc, '1 lb mince, 100 g rice');

    expect(state.rows, hasLength(2));
    for (final row in state.rows) {
      expect(
        fieldPattern.hasMatch(row.amountText),
        isTrue,
        reason: '${row.meal?.name}: "${row.amountText}" fails the submit '
            'check, and that check refuses the entire batch',
      );
    }
  });

  test('a serving weight carrying more decimals is rounded too', () async {
    final bloc = blocWith({
      'almonds': [
        meal('Almonds', servingQuantity: 226.796185, servingUnit: 'g'),
      ],
    });

    final state = await parse(bloc, 'almonds');

    expect(state.rows.single.amountText, '226.8');
    expect(fieldPattern.hasMatch(state.rows.single.amountText), isTrue);
  });

  test(
    'a positive quantity below the rounding floor does not become zero',
    () async {
      final bloc = blocWith({
        'saffron': [meal('Saffron', servingQuantity: 0.004, servingUnit: 'g')],
      });

      final state = await parse(bloc, 'saffron');

      // Rounding alone gives "0.00", which the submit check rejects for
      // being non-positive — the same dead end by the other route.
      expect(state.rows.single.amountText, '0.01');
      expect(fieldPattern.hasMatch(state.rows.single.amountText), isTrue);
    },
  );

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
      // Nothing to count, so the amount falls back to a weight. The row is
      // marked, and held out of the batch until the user settles it.
      final bloc = blocWith({
        'eggs': [meal('Egg')],
      });

      final row = (await parse(bloc, '2 eggs')).rows.single;

      expect(row.amountText, '2');
      expect(row.amountNeedsCheck, isTrue);
      expect(row.willBeLogged, isFalse);
    });

    test('a harmless substitution still logs', () async {
      // A record measured in grams offers no `ml`, so a typed `200ml`
      // becomes `200 g/ml` — same number, same base quantity, same energy.
      // The #973 guard (#975) held these back too, refusing an amount the
      // user had typed correctly and the app had understood correctly.
      final bloc = blocWith({
        'milk': [meal('Milk', mealUnit: 'g')],
      });

      final state = await parse(bloc, '200ml milk');

      final row = state.rows.single;
      expect(row.effectiveUnit, 'g/ml');
      expect(row.amountText, '200');
      expect(
        row.amountNeedsCheck,
        isTrue,
        reason: 'the swap is still worth pointing at',
      );
      expect(
        row.amountWouldBeWrong,
        isFalse,
        reason: 'but it does not move the number',
      );
      expect(state.loggableCount, 1);
    });

    test('a substitution that moves the number is kept out', () async {
      // `4oz` against a record that cannot honour ounces becomes `4 g/ml`:
      // a 28-fold under-count, and exactly the shape the guard is for.
      final bloc = blocWith({
        'steak': [meal('Steak', mealUnit: 'ml')],
      });

      final state = await parse(bloc, '4oz steak');

      expect(state.rows.single.amountWouldBeWrong, isTrue);
      expect(state.loggableCount, 0);
    });

    test('a flagged count is kept out of the batch', () async {
      // #973. Typing `zwei Eier und drei Scheiben Brot` on a device gave two
      // flagged rows at 2 g/ml and 3 g/ml, and Save all wrote both — 11 kcal
      // for a breakfast. The flag was right and the batch ignored it.
      final bloc = blocWith({
        'eggs': [meal('Egg')],
        'bread': [meal('Bread')],
      });

      final state = await parse(bloc, '2 eggs, 3 bread');

      expect(state.rows.length, 2);
      expect(state.rows.every((r) => r.amountNeedsCheck), isTrue);
      expect(state.loggableCount, 0);
    });

    test('picking a unit returns a flagged row to the batch', () async {
      // The way out has to be reachable from the row itself, or excluding it
      // just strands the user. Choosing a unit is the call the warning asks
      // for, so it both clears the flag and restores the row.
      final bloc = blocWith({
        'eggs': [meal('Egg')],
      });
      await parse(bloc, '2 eggs');

      bloc.add(const ChangeRowUnitEvent(0, 'g'));
      final state = await bloc.stream.first as BulkAddLoadedState;

      expect(state.rows.single.amountNeedsCheck, isFalse);
      expect(state.rows.single.willBeLogged, isTrue);
      expect(state.loggableCount, 1);
    });

    test('a countable food is unaffected and still logs in one pass', () async {
      // The guard must not cost the case that already worked: a record with
      // serving data counts as servings and goes straight into the batch.
      final bloc = blocWith({
        'eggs': [meal('Egg', servingQuantity: 50)],
      });

      final state = await parse(bloc, '2 eggs');

      expect(state.rows.single.unit, 'serving');
      expect(state.rows.single.amountNeedsCheck, isFalse);
      expect(state.loggableCount, 1);
    });

    test('a stated weight is unaffected and still logs in one pass', () async {
      // The deterministic path with an explicit unit is the common case and
      // must be untouched by this.
      final bloc = blocWith({
        'toast': [meal('Toast', servingQuantity: 30)],
      });

      final state = await parse(bloc, '100g toast');

      expect(state.rows.single.unit, 'g');
      expect(state.loggableCount, 1);
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
      photoReaderWithoutKey(),
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

  group('reading a photo', () {
    Future<BulkAddState> readPhoto(
      Map<String, List<MealEntity>> results,
      MealPhotoReadResult reading,
    ) async {
      final bloc = blocWith(results, photoReader: _StubPhotoReader(reading));
      bloc.add(ReadMealPhotoEvent(photo: _photo, usesImperialUnits: false));
      return bloc.stream.firstWhere((s) => s is! BulkAddLoadingState);
    }

    test('resolves the foods a photo produced', () async {
      final state = await readPhoto(
        {
          'egg': [meal('Egg', servingQuantity: 50)],
        },
        const MealPhotoRead(
          MealTextParseResult(
            items: [ParsedMealItem(query: 'egg', quantity: 2)],
            errors: [],
          ),
        ),
      );

      expect(state, isA<BulkAddLoadedState>());
      final loaded = state as BulkAddLoadedState;
      expect(loaded.rows.single.meal?.name, 'Egg');
      // A bare count against a scalable record is servings, same rule the
      // text path uses — the reader changes, the row logic does not.
      expect(loaded.rows.single.amountText, '2');
      expect(loaded.rows.single.unit, 'serving');
    });

    test('marks the batch as read from a photo', () async {
      final state = await readPhoto(
        {
          'egg': [meal('Egg')],
        },
        const MealPhotoRead(
          MealTextParseResult(
            items: [ParsedMealItem(query: 'egg')],
            errors: [],
          ),
        ),
      );

      expect(
        (state as BulkAddLoadedState).source,
        BulkAddReadSource.photo,
        reason:
            'the review notice is the only thing telling the user a machine '
            'identified this food from a picture',
      );
    });

    test('a rejected key reaches the state, not just the log', () async {
      // Before this, a wrong key produced a screen indistinguishable from a
      // working one. The rows are still the parser's — what changes is that
      // the user is told the better reader never ran.
      final bloc = blocWithFailingReader({
        'toast': [meal('Toast')],
      }, const MealInterpreterException(
        'unauthorized',
        failure: MealInterpreterFailure.auth,
        statusCode: 401,
      ));
      addTearDown(bloc.close);

      final state = await parse(bloc, '100g toast');

      expect(state.modelFailure, MealTextModelFailure.auth);
      expect(state.source, BulkAddReadSource.parser);
      expect(
        state.rows,
        isNotEmpty,
        reason: 'reporting the failure must not cost the user their rows',
      );
    });

    test('a model nothing can serve reaches the state', () async {
      final bloc = blocWithFailingReader({
        'toast': [meal('Toast')],
      }, const MealInterpreterException(
        'no endpoints',
        failure: MealInterpreterFailure.unsupported,
        statusCode: 404,
      ));
      addTearDown(bloc.close);

      final state = await parse(bloc, '100g toast');

      expect(state.modelFailure, MealTextModelFailure.unsupported);
      expect(state.rows, isNotEmpty);
    });

    test('a transient failure stays out of the state', () async {
      // Deliberate. A banner that fires on a dropped connection is one
      // people learn to scroll past, and it would cost the notice the value
      // it has for the failures that never fix themselves.
      final bloc = blocWithFailingReader({
        'toast': [meal('Toast')],
      }, const MealInterpreterException(
        'rate limited',
        failure: MealInterpreterFailure.transient,
        statusCode: 429,
      ));
      addTearDown(bloc.close);

      final state = await parse(bloc, '100g toast');

      expect(state.modelFailure, isNull);
      expect(state.rows, isNotEmpty);
    });

    test(
      'a photo with no food lands on the empty state, not an error',
      () async {
        final state = await readPhoto(
          {},
          const MealPhotoRead(MealTextParseResult(items: [], errors: [])),
        );

        expect(state, isA<BulkAddLoadedState>());
        expect((state as BulkAddLoadedState).rows, isEmpty);
      },
    );

    test(
      'the feature being off is its own error, not a generic failure',
      () async {
        final state = await readPhoto({}, const MealPhotoUnavailable());

        expect(state, isA<BulkAddPhotoErrorState>());
        expect(
          (state as BulkAddPhotoErrorState).error,
          BulkAddPhotoError.unavailable,
        );
      },
    );

    test('a rejected key says so rather than "try again"', () async {
      final state = await readPhoto(
        {},
        const MealPhotoFailed(MealPhotoFailure.auth),
      );

      expect((state as BulkAddPhotoErrorState).error, BulkAddPhotoError.auth);
    });

    test('exhausted credit is not offered as retryable or an auth fix', () async {
      final state = await readPhoto(
        {},
        const MealPhotoFailed(MealPhotoFailure.billing),
      );

      expect(
        (state as BulkAddPhotoErrorState).error,
        BulkAddPhotoError.billing,
      );
    });

    test('a transient failure is offered as retryable', () async {
      final state = await readPhoto(
        {},
        const MealPhotoFailed(MealPhotoFailure.transient),
      );

      expect(
        (state as BulkAddPhotoErrorState).error,
        BulkAddPhotoError.transient,
      );
    });

    test('a refused plaintext photo points at the address, not the model', () async {
      final state = await readPhoto(
        {},
        const MealPhotoFailed(MealPhotoFailure.insecureDestination),
      );

      expect(
        (state as BulkAddPhotoErrorState).error,
        BulkAddPhotoError.insecureDestination,
      );
    });

    test('a photo that never encoded reaches the same error surface', () async {
      final bloc = blocWith({});
      bloc.add(const ReadMealPhotoFailedEvent(BulkAddPhotoError.unreadable));

      final state = await bloc.stream.first;

      expect(
        (state as BulkAddPhotoErrorState).error,
        BulkAddPhotoError.unreadable,
      );
    });
  });

  group('a defaulted amount says so (#864)', () {
    BulkAddRow rowFor(
      MealEntity food, {
      double? statedQuantity,
      bool amountEdited = false,
    }) => BulkAddRow(
      resolved: ResolvedMealItem(
        parsed: ParsedMealItem(query: food.name!, quantity: statedQuantity),
        candidates: [food],
        selectedIndex: 0,
        confidence: 0.9,
      ),
      selectedIndex: 0,
      amountText: '100',
      unit: 'g',
      amountEditedByUser: amountEdited,
    );

    test('nobody stated an amount and the record carries none', () {
      // The flat 100 g. `amountNeedsCheck` cannot see this case at all,
      // because it requires a stated quantity — so before this getter the
      // row where the app guesses hardest was the one row saying nothing.
      final row = rowFor(meal('toast'));
      expect(row.amountIsProvisional, isTrue);
      expect(row.amountNeedsCheck, isFalse);
    });

    test('the record supplied the amount, so it is not the app guessing', () {
      final row = rowFor(meal('bread', servingQuantity: 38));
      expect(row.amountIsProvisional, isFalse);
    });

    test('serving *text* alone is still the flat fallback', () {
      // OFF's real shape: no numeric field, a weight only in the text.
      // `scalableServingQuantity` reads the 30 out of it (#629) but
      // `_initialAmount` does not — it gates on `servingQuantity` — so the
      // row shows 100 and this must say so.
      //
      // The example matters. An earlier version used "1 egg", where
      // `scalableServingQuantity` is *also* null, so the test passed against
      // either gate and pinned nothing.
      final row = rowFor(meal('yoghurt', servingSize: '30 g'));
      expect(row.meal!.hasServingValues, isTrue);
      expect(row.meal!.scalableServingQuantity, 30);
      expect(row.meal!.servingQuantity, isNull);
      expect(row.amountIsProvisional, isTrue);
    });

    test('a stated amount is never provisional', () {
      // That number is the user's or the model's. Whether it means what
      // they think is `amountNeedsCheck`'s question, not this one.
      final row = rowFor(meal('toast'), statedQuantity: 2);
      expect(row.amountIsProvisional, isFalse);
    });

    test('typing an amount answers it', () {
      final row = rowFor(meal('toast'), amountEdited: true);
      expect(row.amountIsProvisional, isFalse);
    });

    test('an unresolved row has nothing to be provisional about', () {
      final row = BulkAddRow(
        resolved: const ResolvedMealItem(
          parsed: ParsedMealItem(query: 'zzzz'),
          candidates: [],
          selectedIndex: 0,
          confidence: 0,
        ),
        selectedIndex: 0,
        amountText: '100',
        unit: 'g',
      );
      expect(row.isResolved, isFalse);
      expect(row.amountIsProvisional, isFalse);
    });

    test('the two flags never fire together', () {
      // The screen renders them in one exclusive chain, so an overlap would
      // silently hide the louder of the two rather than show both.
      for (final food in [
        meal('toast'),
        meal('bread', servingQuantity: 38),
        meal('egg', servingSize: '1 egg'),
      ]) {
        for (final stated in [null, 2.0]) {
          final row = rowFor(food, statedQuantity: stated);
          expect(
            row.amountIsProvisional && row.amountNeedsCheck,
            isFalse,
            reason: '${food.name} stated=$stated',
          );
        }
      }
    });
  });


  group('the typed word picks the portion (#864)', () {
    const cup = MealPortionEntity(
        label: '1 cup', gramWeight: 244, localized: false);
    const slice = MealPortionEntity(
        label: '1 slice', gramWeight: 38, localized: false);

    test('"3 slices of bread" preselects the slice, not the cup', () async {
      // The whole point. Without this the row takes the first portion and
      // three slices log as three cups — 732 g of bread.
      final bloc = blocWith({
        'slices of bread': [
          meal('Bread', servingQuantity: 244, portions: [cup, slice]),
        ],
      });

      final row = (await parse(bloc, '3 slices of bread')).rows.single;

      expect(row.unit, 'serving#1');
      expect(row.amountText, '3');
    });

    test('naming no portion leaves the preselection exactly as it was',
        () async {
      // Decision 7: this only ever narrows. A bare count with no word still
      // means the default portion, which is what the row did before.
      final bloc = blocWith({
        'bread': [meal('Bread', servingQuantity: 244, portions: [cup, slice])],
      });

      final row = (await parse(bloc, '3 bread')).rows.single;

      expect(row.unit, 'serving');
    });

    test('a stated unit still wins over a named portion', () async {
      // "100g toast" is grams whatever else the text says: the parser
      // already resolved it, and second-guessing that would let a food name
      // override an explicit measurement.
      final bloc = blocWith({
        'slices of bread': [
          meal('Bread', servingQuantity: 244, portions: [cup, slice]),
        ],
      });

      final row = (await parse(bloc, '100g slices of bread')).rows.single;

      expect(row.unit, 'g');
    });

    test('naming a portion with no count does not preselect it', () async {
      // The gate on a stated quantity is load-bearing, not tidiness.
      // `_initialAmount` falls back to the *default* portion's weight, so
      // preselecting the slice here would pair the slice's name with the
      // cup's 244 g and the row would read "244 slice".
      final bloc = blocWith({
        'slices of bread': [
          meal('Bread', servingQuantity: 244, portions: [cup, slice]),
        ],
      });

      final row = (await parse(bloc, 'slices of bread')).rows.single;

      expect(row.unit, isNot('serving#1'));
      expect(row.amountText, '244');
    });

    test("the model's own word picks the portion", () async {
      // A photograph has no typed text to search, so the key is the only
      // thing that can name a slice on that path. Driven here through the
      // text interpreter, which is the same ParsedMealItem either way.
      final bloc = blocWithModelReply(
        {'bread': [meal('Bread', servingQuantity: 244, portions: [cup, slice])]},
        const [ParsedMealItem(query: 'bread', quantity: 3, portion: 'slice')],
      );

      final row = (await parse(bloc, 'bread')).rows.single;

      expect(row.unit, 'serving#1');
    });

    test('a key that matches nothing leaves the row alone', () async {
      // The weak failure this design chose: an unusable key is ignored, and
      // the row keeps the preselection it would have had.
      final bloc = blocWithModelReply(
        {'bread': [meal('Bread', servingQuantity: 244, portions: [cup, slice])]},
        const [ParsedMealItem(query: 'bread', quantity: 3, portion: 'thimble')],
      );

      final row = (await parse(bloc, 'bread')).rows.single;

      expect(row.unit, 'serving');
    });

    test('a food with no portion list is untouched', () async {
      final bloc = blocWith({
        'slices of bread': [meal('Bread', servingQuantity: 30)],
      });

      final row = (await parse(bloc, '3 slices of bread')).rows.single;

      expect(row.unit, 'serving');
    });
  });

  group('a refused quantity says which refusal it is (#1013)', () {
    /// A perfectly ordinary loggable row, with [amount] typed into it.
    Future<BulkAddRow> rowWithAmount(String amount) async {
      final bloc = blocWith({
        'rice': [meal('Rice')],
      });
      final state = await parse(bloc, '100g rice');
      return state.rows.single.copyWith(amountText: amount);
    }

    test('zero is refused for being zero', () async {
      final row = await rowWithAmount('0');

      expect(row.quantityError, BulkAddQuantityError.tooSmall);
    });

    test('and so is a zero written with decimals', () async {
      final row = await rowWithAmount('0.00');

      expect(row.quantityError, BulkAddQuantityError.tooSmall);
    });

    test('past the bound is refused for being past the bound', () async {
      final row = await rowWithAmount('${bulkAddMaxQuantity + 1}');

      expect(row.quantityError, BulkAddQuantityError.tooLarge);
    });

    test('the bound itself is allowed', () async {
      final row = await rowWithAmount('$bulkAddMaxQuantity');

      expect(row.quantityError, isNull);
    });

    test('a third decimal is refused for its shape, not its size', () async {
      // The rule nothing on the screen states. Reported as itself rather
      // than as "too small", which is what a check that parsed first would
      // have called 0.001.
      final row = await rowWithAmount('0.001');

      expect(row.quantityError, BulkAddQuantityError.malformed);
    });

    test('an emptied field is refused the same way', () async {
      final row = await rowWithAmount('');

      expect(row.quantityError, BulkAddQuantityError.malformed);
    });

    test('a decimal comma is a number, not a fault', () async {
      final row = await rowWithAmount('1,5');

      expect(row.quantityError, isNull);
    });

    test('surrounding space is not a fault either', () async {
      final row = await rowWithAmount(' 100 ');

      expect(row.quantityError, isNull);
    });

    test('the three refusals are three distinct answers', () async {
      final errors = {
        (await rowWithAmount('0')).quantityError,
        (await rowWithAmount('99999')).quantityError,
        (await rowWithAmount('1.234')).quantityError,
      };

      // One message for all three was the bug: `Rice: Quantity`, whichever
      // of them had happened.
      expect(errors, hasLength(3));
    });

    test('a refused row is still part of the batch', () async {
      // The batch is all-or-nothing, so a bad amount has to be handed back
      // to the user rather than filtered out of the write — dropping it
      // would log everything else and say nothing about the row that was
      // meant to be there.
      final row = await rowWithAmount('0');

      expect(row.quantityError, isNotNull);
      expect(row.willBeLogged, isTrue);
    });
  });
}

final _photo = MealPhoto(
  bytes: Uint8List.fromList([1, 2, 3]),
  mediaType: 'image/webp',
);

/// Returns a fixed reading without touching a credential or a network.
class _StubPhotoReader implements ReadMealPhotoUseCase {
  final MealPhotoReadResult reading;

  _StubPhotoReader(this.reading);

  @override
  Future<MealPhotoReadResult> read(
    MealPhoto photo, {
    String? localeCode,
  }) async => reading;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// A keystore with nothing in it, so the read use case always takes the
/// deterministic path.
/// Holds what it is given, so a test can put the use case on the model path
/// instead of the parser one.
class _MapStorage implements FlutterSecureStorage {
  final Map<String, String> values;

  /// Seeds the agreement unless a test says otherwise.
  ///
  /// A stored credential is only usable once the user has agreed to what
  /// leaves the device (#836), so a map holding a key and no agreement is a
  /// state the app cannot reach.
  _MapStorage(Map<String, String> values)
    : values = {'AiTermsAcceptedTag': 'true', ...values};

  @override
  Future<String?> read({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async => values[key];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

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
