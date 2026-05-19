import 'dart:async';

import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:opennutritracker/core/data/data_source/custom_meal_supabase_data_source.dart';
import 'package:opennutritracker/core/data/dbo/meal_dbo.dart';

class CustomMealDataSource {
  final Box<MealDBO> _customMealBox;
  final CustomMealSupabaseDataSource? _supabase;

  CustomMealDataSource(this._customMealBox, [this._supabase]);

  Future<void> saveCustomMeal(MealDBO mealDBO) async {
    final existing = _customMealBox.values.cast<MealDBO?>().firstWhere(
        (m) =>
            (mealDBO.code != null && m?.code == mealDBO.code) ||
            (mealDBO.code == null && m?.name == mealDBO.name),
        orElse: () => null);
    if (existing != null) {
      await _customMealBox.put(existing.key, mealDBO);
    } else {
      await _customMealBox.add(mealDBO);
    }
    unawaited(_supabase?.upsert(mealDBO));
  }

  List<MealDBO> getAllCustomMeals() => _customMealBox.values.toList();

  Future<void> deleteCustomMeal(String mealKey) async {
    final toDelete = _customMealBox.values
        .where((m) => (m.code ?? m.name) == mealKey)
        .toList();
    for (final meal in toDelete) {
      await meal.delete();
    }
    unawaited(_supabase?.delete(mealKey));
  }

  /// Fetches custom meals from Supabase and saves any that are missing locally.
  /// Called once at startup to restore data after a reinstall.
  Future<void> syncFromSupabase() async {
    final remote = await _supabase?.fetchAll() ?? [];
    if (remote.isEmpty) return;
    final localKeys = _customMealBox.values.map((m) => m.code ?? m.name).toSet();
    for (final meal in remote) {
      if (!localKeys.contains(meal.code ?? meal.name)) {
        await _customMealBox.add(meal);
      }
    }
  }
}
