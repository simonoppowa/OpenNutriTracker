import 'package:logging/logging.dart';
import 'package:opennutritracker/core/data/dbo/meal_dbo.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Syncs user-created custom meals to Supabase so they survive a local cache
/// clear or app reinstall.
///
/// Requires Supabase Anonymous Auth — call [ensureSignedIn] once at startup.
///
/// Table: user_custom_meals
///   user_id     UUID  (auth.uid())
///   lookup_key  TEXT  (code when available, else name)
///   meal_data   JSONB (full MealDBO as JSON)
///   updated_at  TIMESTAMPTZ
class CustomMealSupabaseDataSource {
  static const _table = 'user_custom_meals';

  final _log = Logger('CustomMealSupabaseDataSource');
  final SupabaseClient _client;

  CustomMealSupabaseDataSource(this._client);

  Future<void> ensureSignedIn() async {
    if (_client.auth.currentSession != null) return;
    try {
      await _client.auth.signInAnonymously();
      _log.fine('Signed in anonymously to Supabase');
    } catch (e) {
      _log.warning('Anonymous sign-in failed: $e');
    }
  }

  Future<void> upsert(MealDBO meal) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;
    final key = meal.code ?? meal.name;
    if (key == null) return;
    try {
      await _client.from(_table).upsert(
        {
          'user_id': userId,
          'lookup_key': key,
          'meal_data': meal.toJson(),
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        },
        onConflict: 'user_id,lookup_key',
      );
      _log.fine('Upserted custom meal: $key');
    } catch (e) {
      _log.warning('Failed to upsert custom meal $key: $e');
    }
  }

  Future<void> delete(String lookupKey) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;
    try {
      await _client
          .from(_table)
          .delete()
          .eq('user_id', userId)
          .eq('lookup_key', lookupKey);
      _log.fine('Deleted custom meal: $lookupKey');
    } catch (e) {
      _log.warning('Failed to delete custom meal $lookupKey: $e');
    }
  }

  Future<List<MealDBO>> fetchAll() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];
    try {
      final rows = await _client.from(_table).select().eq('user_id', userId);
      return rows
          .map((r) => MealDBO.fromJson(r['meal_data'] as Map<String, dynamic>))
          .toList();
    } catch (e) {
      _log.warning('Failed to fetch custom meals: $e');
      return [];
    }
  }
}
