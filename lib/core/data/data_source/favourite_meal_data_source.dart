import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:logging/logging.dart';
import 'package:opennutritracker/core/data/dbo/favourite_meal_dbo.dart';
import 'package:opennutritracker/core/utils/hive_db_provider.dart';

/// The active profile's Favourites box, keyed by [FavouriteMealDBO.mealKey].
class FavouriteMealDataSource {
  final log = Logger('FavouriteMealDataSource');
  final HiveDBProvider _db;

  FavouriteMealDataSource(this._db);

  Box<FavouriteMealDBO> get _favouriteMealBox => _db.favouriteMealBox;

  bool isFavourite(String mealKey) => _favouriteMealBox.containsKey(mealKey);

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
