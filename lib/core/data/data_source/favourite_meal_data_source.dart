import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:logging/logging.dart';
import 'package:opennutritracker/core/data/dbo/favourite_meal_dbo.dart';
import 'package:opennutritracker/core/data/dbo/meal_dbo.dart';
import 'package:opennutritracker/core/utils/hive_db_provider.dart';

/// The active profile's Favourites box, keyed by [FavouriteMealDBO.mealKey].
class FavouriteMealDataSource {
  final log = Logger('FavouriteMealDataSource');
  final HiveDBProvider _db;

  FavouriteMealDataSource(this._db);

  Box<FavouriteMealDBO> get _favouriteMealBox => _db.favouriteMealBox;

  bool isFavourite(String mealKey) => _favouriteMealBox.containsKey(mealKey);

  FavouriteMealDBO? getFavourite(String mealKey) =>
      _favouriteMealBox.get(mealKey);

  /// In every profile whose list has a favourite under [fromKey] — the
  /// active one and each other one in the registry — replaces its snapshot
  /// with [meal], under [meal]'s key, keeping `addedAt`. Stars nothing new.
  /// When [meal]'s key is a different one that is already starred too (a
  /// merge onto a starred meal), the two become one entry with the earlier
  /// `addedAt`.
  ///
  /// The custom-meal and recipe libraries are shared by every profile while
  /// each has its own list, so an edit or delete in one profile changes the
  /// meal under the others' favourites too. Run it under the tracked-day
  /// lock, which excludes a profile switch, so the active box is the same
  /// one throughout.
  Future<void> rewriteInEveryProfile(String fromKey, MealDBO meal) async {
    await _rewrite(_favouriteMealBox, fromKey, meal);
    for (final profile in _db.profileBox.values) {
      if (profile.id == _db.activeProfileId) continue;
      final box = await _db.openScopedBox<FavouriteMealDBO>(
        HiveDBProvider.favouriteMealBoxName,
        profile.boxSuffix,
      );
      try {
        await _rewrite(box, fromKey, meal);
      } finally {
        await _db.closeScopedBox<FavouriteMealDBO>(
          HiveDBProvider.favouriteMealBoxName,
          profile.boxSuffix,
        );
      }
    }
  }

  Future<void> _rewrite(
    Box<FavouriteMealDBO> box,
    String fromKey,
    MealDBO meal,
  ) async {
    final existing = box.get(fromKey);
    if (existing == null) return;
    final toKey = FavouriteMealDBO.keyFor(meal.source, meal.code, meal.name);
    final target = box.get(toKey);
    final addedAt = target != null && target.addedAt.isBefore(existing.addedAt)
        ? target.addedAt
        : existing.addedAt;
    final favourite = FavouriteMealDBO(meal: meal, addedAt: addedAt);
    log.fine('Rewriting favourite $fromKey as ${favourite.mealKey}');
    await box.put(favourite.mealKey, favourite);
    if (favourite.mealKey != fromKey) await box.delete(fromKey);
  }

  /// Upserts by meal key: starring a food that is already on the list
  /// replaces its snapshot rather than adding a second row.
  Future<void> addFavourite(FavouriteMealDBO favourite) async {
    log.fine('Adding favourite ${favourite.mealKey}');
    await _favouriteMealBox.put(favourite.mealKey, favourite);
  }

  Future<void> addAllFavourites(List<FavouriteMealDBO> favourites) async {
    log.fine('Adding ${favourites.length} favourites');
    await _favouriteMealBox.putAll({
      for (final favourite in favourites) favourite.mealKey: favourite,
    });
  }

  Future<void> deleteFavourite(String mealKey) async {
    log.fine('Deleting favourite $mealKey');
    await _favouriteMealBox.delete(mealKey);
  }

  /// Every favourite, the most recently starred first.
  List<FavouriteMealDBO> getAllFavourites() =>
      _favouriteMealBox.values.toList()
        ..sort((a, b) => b.addedAt.compareTo(a.addedAt));

  /// Fires after every write to the box, whichever screen made it, so a list
  /// or a star on screen can follow a toggle made on the detail page.
  Stream<void> watch() => _favouriteMealBox.watch().map((_) {});
}
