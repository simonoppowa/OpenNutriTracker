import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/utils/app_locale.dart';
import 'package:opennutritracker/core/utils/locator.dart';
import 'package:opennutritracker/features/add_meal/data/data_sources/food_rpc_client.dart';
import 'package:opennutritracker/features/add_meal/data/data_sources/sp_food_data_source.dart';
import 'package:opennutritracker/features/add_meal/data/dto/sp/sp_const.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Answers every call from a script and records what it was asked.
class _FakeFoodRpcClient implements FoodRpcClient {
  final calls = <(String, Map<String, dynamic>)>[];
  final Map<String, List<Map<String, dynamic>>> answers;

  _FakeFoodRpcClient(this.answers);

  @override
  Future<List<Map<String, dynamic>>> rpc(
    String fn,
    Map<String, dynamic> params,
  ) async {
    calls.add((fn, params));
    return answers[fn] ?? const [];
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() {
    AppLocale.reset();
    if (locator.isRegistered<FoodRpcClient>()) {
      locator.unregister<FoodRpcClient>();
    }
    if (locator.isRegistered<SupabaseClient>()) {
      locator.unregister<SupabaseClient>();
    }
  });

  test('a registered FoodRpcClient answers instead of Supabase', () async {
    AppLocale.select('de');
    final fake = _FakeFoodRpcClient({
      SPConst.portionLabelsByFoodIdsFn: [
        {'food_id': 1, 'label': 'Scheibe'},
      ],
    });
    locator.registerSingleton<FoodRpcClient>(fake);
    // No SupabaseClient is registered: reaching for one would throw.

    final labels = await SpFoodDataSource().fetchPortionLabels([1]);

    expect(labels, {1: 'Scheibe'});
    expect(fake.calls.single.$1, SPConst.portionLabelsByFoodIdsFn);
    expect(fake.calls.single.$2, {
      'ids': [1],
      'loc': 'de',
    });
  });
}
