import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:opennutritracker/core/utils/ai_credential_storage.dart';
import 'package:opennutritracker/features/add_meal/data/anthropic_meal_items_api.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_nutriments_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_portion_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/meal_items_api.dart';
import 'package:opennutritracker/features/add_meal/domain/usecase/pick_resolved_matches_usecase.dart';
import 'package:opennutritracker/features/add_meal/domain/usecase/resolve_parsed_meals_usecase.dart';
import 'package:opennutritracker/features/add_meal/presentation/bloc/bulk_add_bloc.dart';
import 'package:opennutritracker/features/add_meal/util/meal_text_parser.dart';

MealEntity food(
  String name, {
  double? kcal,
  List<MealPortionEntity> portions = const [],
  String? mealUnit,
}) => MealEntity(
  code: name,
  name: name,
  url: null,
  mealQuantity: null,
  mealUnit: mealUnit,
  servingQuantity: null,
  servingUnit: null,
  servingSize: null,
  portions: portions,
  source: MealSourceEntity.off,
  nutriments: MealNutrimentsEntity(
    energyKcal100: kcal,
    carbohydrates100: 1,
    fat100: 2,
    proteins100: 3,
    sugars100: null,
    saturatedFat100: null,
    fiber100: null,
  ),
);

ResolvedMealItem item(
  String query,
  List<MealEntity> candidates, {
  double? quantity,
  int selectedIndex = 0,
  double confidence = 0.8,
}) => ResolvedMealItem(
  parsed: ParsedMealItem(query: query, quantity: quantity),
  candidates: candidates,
  selectedIndex: selectedIndex,
  confidence: candidates.isEmpty ? 0 : confidence,
);

final eggs = item('eggs', [
  food('Egg yolk, raw', kcal: 322),
  food(
    'Egg, whole, raw',
    kcal: 143,
    portions: const [
      MealPortionEntity(label: '1 large', gramWeight: 50, localized: false),
    ],
  ),
], quantity: 2);

final toast = item('toast', [
  food('Tostada shell, corn', kcal: 474),
  food('Bread, white, toasted', kcal: 293),
], quantity: 1);

const meal = 'dos huevos revueltos y una tostada';

/// Replays one Anthropic tool call; nothing touches the network.
class _ReplyClient extends http.BaseClient {
  final List<Map<String, dynamic>> items;
  Map<String, dynamic>? sent;

  _ReplyClient(this.items);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    sent = jsonDecode((request as http.Request).body) as Map<String, dynamic>;
    final body = jsonEncode({
      'id': 'msg_1',
      'type': 'message',
      'role': 'assistant',
      'content': [
        {
          'type': 'tool_use',
          'id': 'tu_1',
          'name': 'log_meal_items',
          'input': {'items': items},
        },
      ],
    });
    return http.StreamedResponse(Stream.value(utf8.encode(body)), 200);
  }
}

/// Secure storage with nothing in it: no key, so no model is configured.
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

void main() {
  group('buildRequest', () {
    test('shows the meal and every candidate', () {
      final text = PickResolvedMatchesUseCase.buildRequest(meal, [eggs, toast]);
      expect(text, contains('Meal: "$meal"'));
      expect(text, contains('Item 1: "eggs"'));
      expect(text, contains('c1: Egg, whole, raw [off] | 143 kcal'));
      expect(text, contains('portions: 1 large'));
      expect(text, contains('Item 2: "toast"'));
      expect(text, contains('c0: Tostada shell, corn'));
    });

    test('shows portion labels without their weights', () {
      // Weights would invite the model to work out grams, which it is not
      // asked for and the app would not use.
      final text = PickResolvedMatchesUseCase.buildRequest(meal, [eggs]);
      expect(text, isNot(contains('50 g')));
    });

    test('caps the candidates but keeps the resolver pick', () {
      final many = item('apple', [
        for (var i = 0; i < 10; i++) food('Apple $i', kcal: 50),
      ], selectedIndex: 8);
      final text = PickResolvedMatchesUseCase.buildRequest('an apple', [many]);
      expect(text, contains('c5: Apple 5'));
      expect(text, isNot(contains('c6: Apple 6')));
      expect(text, contains('c8: Apple 8'));
    });
  });

  group('applyPicks', () {
    test('a pick changes the candidate and keeps what the user stated', () {
      final out = PickResolvedMatchesUseCase.applyPicks(
        [eggs, toast],
        const [ParsedMealItem(query: '1:c1'), ParsedMealItem(query: '2:c1')],
      );
      expect(out[0].selectedIndex, 1);
      expect(out[0].parsed, same(eggs.parsed));
      expect(out[1].selected!.name, 'Bread, white, toasted');
      expect(out[1].parsed, same(toast.parsed));
      expect(out[1].isLowConfidence, isFalse);
    });

    test('an amount in the answer is ignored', () {
      final out = PickResolvedMatchesUseCase.applyPicks(
        [eggs],
        const [ParsedMealItem(query: '1:c1', quantity: 300, unit: 'g')],
      );
      expect(out.single.selectedIndex, 1);
      expect(out.single.parsed.quantity, 2);
      expect(out.single.parsed.unit, isNull);
    });

    test('"none" keeps the row but flags it for checking', () {
      final out = PickResolvedMatchesUseCase.applyPicks(
        [toast],
        const [ParsedMealItem(query: '1:none')],
      );
      expect(out.single.selectedIndex, toast.selectedIndex);
      expect(out.single.isLowConfidence, isTrue);
    });

    test('unusable answers leave the resolver rows untouched', () {
      final out = PickResolvedMatchesUseCase.applyPicks(
        [eggs, toast],
        const [
          ParsedMealItem(query: 'eggs'),
          ParsedMealItem(query: '1:c9'),
          ParsedMealItem(query: '3:c0'),
          ParsedMealItem(query: '0:c0'),
        ],
      );
      expect(out, [same(eggs), same(toast)]);
    });

    test('a weak resolver match the model picked starts settled', () {
      final weak = item('eggs', eggs.candidates, quantity: 2, confidence: 0.2);
      final out = PickResolvedMatchesUseCase.applyPicks(
        [weak],
        const [ParsedMealItem(query: '1:c1')],
      );
      final row = BulkAddRow(
        resolved: out.single,
        selectedIndex: out.single.selectedIndex,
        amountText: '100',
        unit: 'g',
      );
      expect(row.isLowConfidence, isFalse);
      expect(row.meal!.name, 'Egg, whole, raw');
    });
  });

  group('pick', () {
    PickResolvedMatchesUseCase useCase(_ReplyClient client) =>
        PickResolvedMatchesUseCase(
          AiCredentialStorage(_EmptyStorage()),
          (_) => AnthropicMealItemsApi(client, () => 'test-key'),
        );

    test('does not call out when no item has a choice to make', () async {
      final client = _ReplyClient(const []);
      final single = item('toast', [food('Bread, white, toasted')]);
      final out = await useCase(client).pick('toast', [single]);

      expect(out, [same(single)]);
      expect(client.sent, isNull);
    });

    test('does not call out without a model configured', () async {
      final client = _ReplyClient(const []);
      final out = await useCase(client).pick(meal, [eggs, toast]);

      expect(out, [same(eggs), same(toast)]);
      expect(client.sent, isNull);
    });
  });

  test('round trip through a real client', () async {
    final client = _ReplyClient([
      {'query': '1:c1'},
      {'query': '2:c1'},
    ]);
    final api = AnthropicMealItemsApi(client, () => 'test-key');
    final reply = await api.requestItems(
      content: MealTextContent(
        PickResolvedMatchesUseCase.buildRequest(meal, [eggs, toast]),
      ),
      system: PickResolvedMatchesUseCase.systemPrompt,
    );
    final out = PickResolvedMatchesUseCase.applyPicks([
      eggs,
      toast,
    ], reply.items);

    expect(client.sent!['system'], PickResolvedMatchesUseCase.systemPrompt);
    expect(out[0].selectedIndex, 1);
    expect(out[1].selectedIndex, 1);
    expect(out[0].parsed.quantity, 2);
  });
}
