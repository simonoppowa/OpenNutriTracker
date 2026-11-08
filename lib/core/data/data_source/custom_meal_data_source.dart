import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:opennutritracker/core/data/dbo/meal_dbo.dart';
import 'package:opennutritracker/core/utils/hive_db_provider.dart';

class CustomMealDataSource {
  final HiveDBProvider _db;

  CustomMealDataSource(this._db);

  Box<MealDBO> get _customMealBox => _db.customMealBox;

  /// Saves [mealDBO] to the custom meal library.
  ///
  /// Without [previous] — the importers — an entry with the same identity
  /// (the barcode, or the name when there is none) is overwritten, so a
  /// re-import does not duplicate a meal.
  ///
  /// [previous] is the meal as it was before an edit. Its entry is the one
  /// replaced, so an edit that gave the meal a barcode or renamed a meal
  /// without one does not leave the old meal behind next to it (#1403).
  /// Another entry that already has the edited meal's identity is dropped:
  /// the meal just saved wins, as it does when a new meal is saved with a
  /// barcode another custom meal has. When [previous] is not in the library,
  /// the save falls back to the import behaviour.
  Future<void> saveCustomMeal(MealDBO mealDBO, {MealDBO? previous}) async {
    final edited = previous == null
        ? null
        : _customMealBox.values
            .where((m) => _identityOf(m) == _identityOf(previous))
            .firstOrNull;
    if (edited != null) {
      final collisions = _customMealBox.values
          .where((m) =>
              m.key != edited.key && _identityOf(m) == _identityOf(mealDBO))
          .toList();
      await _customMealBox.put(edited.key, mealDBO);
      for (final meal in collisions) {
        await meal.delete();
      }
      return;
    }

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
  }

  /// The key a custom meal is known by, as [deleteCustomMeal] reads it.
  static String? _identityOf(MealDBO meal) => meal.code ?? meal.name;

  List<MealDBO> getAllCustomMeals() => _customMealBox.values.toList();

  Future<void> deleteCustomMeal(String mealKey) async {
    final toDelete = _customMealBox.values
        .where((m) => (m.code ?? m.name) == mealKey)
        .toList();
    for (final meal in toDelete) {
      await meal.delete();
    }
  }

  /// Fires after every write to the box, so a list showing a custom meal
  /// can follow an edit made on another screen.
  Stream<void> watch() => _customMealBox.watch().map((_) {});
}
