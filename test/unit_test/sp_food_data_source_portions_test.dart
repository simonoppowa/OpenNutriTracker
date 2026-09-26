import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:opennutritracker/core/utils/locator.dart';
import 'package:opennutritracker/features/add_meal/data/data_sources/sp_food_data_source.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Answers every request with [status] and [body], so the same data source
/// can be shown a backend that answered and one that did not.
class _ScriptedClient extends http.BaseClient {
  _ScriptedClient({required this.status, required this.body});

  final int status;
  final String body;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async =>
      http.StreamedResponse(
        Stream.value(utf8.encode(body)),
        status,
        headers: {'content-type': 'application/json; charset=utf-8'},
        request: request,
      );
}

void _serve(_ScriptedClient client) {
  if (locator.isRegistered<SupabaseClient>()) {
    locator.unregister<SupabaseClient>();
  }
  locator.registerSingleton<SupabaseClient>(
    SupabaseClient('http://backend.invalid', 'test-key', httpClient: client),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() {
    if (locator.isRegistered<SupabaseClient>()) {
      locator.unregister<SupabaseClient>();
    }
  });

  // The resolver reads the difference between these two answers
  // (`MealEntity.portionsUnavailable`), so the data source has to make it.
  group(
    'SpFoodDataSource.fetchPortions tells a failure from an empty answer',
    () {
      test('a backend that answered with no rows is an empty map', () async {
        _serve(_ScriptedClient(status: 200, body: '[]'));

        final portions = await SpFoodDataSource().fetchPortions([1, 2]);

        expect(portions, isNotNull);
        expect(portions, isEmpty);
      });

      test('a backend that refused is null, and nothing is thrown', () async {
        // A portion list must never cost a search: the failure is swallowed
        // as before, and reported as what it is rather than as "none".
        _serve(
          _ScriptedClient(
            status: 500,
            body:
                '{"message":"portions_by_food_ids: relation is being rebuilt"}',
          ),
        );

        final portions = await SpFoodDataSource().fetchPortions([1, 2]);

        expect(portions, isNull);
      });

      test('a backend that answered is read per food', () async {
        _serve(
          _ScriptedClient(
            status: 200,
            body: jsonEncode([
              {
                'food_id': 1,
                'label': '1 slice',
                'gram_weight': 38,
                'localized': false,
              },
              {
                'food_id': 1,
                'label': '1 loaf',
                'gram_weight': 500,
                'localized': false,
              },
            ]),
          ),
        );

        final portions = await SpFoodDataSource().fetchPortions([1, 2]);

        expect(portions, isNotNull);
        expect(portions![1]?.map((p) => p.label), ['1 slice', '1 loaf']);
        // Asked for and not answered: the backend's "none", not a failure.
        expect(portions.containsKey(2), isFalse);
      });

      test('the English label rides beside the coalesced one', () async {
        // `label_en` is what a model's portion key is matched against
        // (#1157): a German reader sees "1 Scheibe", the key "slice" lands on
        // it through the English string the record carries.
        _serve(
          _ScriptedClient(
            status: 200,
            body: jsonEncode([
              {
                'food_id': 1,
                'label': '1 Scheibe',
                'label_en': '1 slice',
                'gram_weight': 28,
                'localized': true,
              },
            ]),
          ),
        );

        final portions = await SpFoodDataSource().fetchPortions([1]);

        expect(portions![1]!.single.label, '1 Scheibe');
        expect(portions[1]!.single.englishLabel, '1 slice');
        expect(portions[1]!.single.localized, isTrue);
      });

      test('a backend without the column still answers', () async {
        // The column is added in parallel; an app built before it must keep
        // working. Absent, or present and empty, the entity carries null and
        // the matcher falls back to the label.
        _serve(
          _ScriptedClient(
            status: 200,
            body: jsonEncode([
              {
                'food_id': 1,
                'label': '1 slice',
                'gram_weight': 28,
                'localized': false,
              },
              {
                'food_id': 1,
                'label': '1 cup',
                'label_en': '',
                'gram_weight': 40,
                'localized': false,
              },
              {
                'food_id': 1,
                'label': '1 cubic inch',
                'label_en': null,
                'gram_weight': 2.8,
                'localized': false,
              },
            ]),
          ),
        );

        final portions = await SpFoodDataSource().fetchPortions([1]);

        expect(portions![1]!.map((p) => p.label), [
          '1 slice',
          '1 cup',
          '1 cubic inch',
        ]);
        expect(portions[1]!.map((p) => p.englishLabel), [null, null, null]);
      });

      test('nothing to ask about is not a failure', () async {
        // No client registered at all: an empty id list never reaches one,
        // and an empty page has no record to spare or to penalise.
        expect(await SpFoodDataSource().fetchPortions(const []), isEmpty);
      });
    },
  );
}
