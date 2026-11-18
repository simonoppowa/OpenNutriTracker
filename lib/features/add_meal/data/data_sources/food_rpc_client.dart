import 'package:supabase_flutter/supabase_flutter.dart';

/// Calls one of the backend's food functions by name and hands back its rows,
/// each keyed by the function's column names.
///
/// [SpFoodDataSource] reaches the backend only through this, so anything
/// that answers `search_food_summary`, `search_food_translation`,
/// `food_summary_by_ids`, `portion_labels_by_food_ids` and
/// `portions_by_food_ids` with the same row maps can stand in for the
/// hosted Supabase project.
abstract interface class FoodRpcClient {
  Future<List<Map<String, dynamic>>> rpc(
    String fn,
    Map<String, dynamic> params,
  );
}

/// The hosted backend: a PostgREST RPC per call.
class SupabaseFoodRpcClient implements FoodRpcClient {
  SupabaseFoodRpcClient(this._client);

  final SupabaseClient _client;

  /// `rpc` posts [params] as the request body and leaves the URL as a bare
  /// `/rest/v1/rpc/<fn>` — which is the entire point of routing search this
  /// way — but it is typed `dynamic`, where `select()` handed back a typed
  /// list. One cast in one place.
  @override
  Future<List<Map<String, dynamic>>> rpc(
    String fn,
    Map<String, dynamic> params,
  ) async {
    final response = await _client.rpc(fn, params: params);
    // A set-returning function with no matches answers with an empty array,
    // never null; null would mean the function itself returned NULL, which
    // none of these can.
    return (response as List).cast<Map<String, dynamic>>();
  }
}
