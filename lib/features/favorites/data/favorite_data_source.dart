import 'dart:convert';

import 'package:logging/logging.dart';
import 'package:opennutritracker/core/utils/hive_db_provider.dart';
import 'package:opennutritracker/features/favorites/domain/favorite_entry.dart';

/// The active profile's favourites in `FavoriteBox`, one JSON entry per id.
class FavoriteDataSource {
  static final _log = Logger('FavoriteDataSource');

  final HiveDBProvider _db;

  FavoriteDataSource(this._db);

  /// Every favourite, in list order; an unreadable entry is skipped.
  List<FavoriteEntry> all() {
    final entries = <FavoriteEntry>[];
    for (final raw in _db.favoriteBox.values) {
      try {
        entries.add(
          FavoriteEntry.fromJson(jsonDecode(raw) as Map<String, dynamic>),
        );
      } on Object catch (error) {
        _log.warning('Skipping an unreadable favourite', error);
      }
    }
    return entries..sort((a, b) => a.sortIndex.compareTo(b.sortIndex));
  }

  bool contains(String id) => _db.favoriteBox.containsKey(id);

  Future<void> put(FavoriteEntry entry) =>
      _db.favoriteBox.put(entry.id, jsonEncode(entry.toJson()));

  Future<void> putAll(Iterable<FavoriteEntry> entries) => _db.favoriteBox
      .putAll({for (final e in entries) e.id: jsonEncode(e.toJson())});

  Future<void> delete(String id) => _db.favoriteBox.delete(id);

  Future<void> deleteAll(Iterable<String> ids) =>
      _db.favoriteBox.deleteAll(ids);
}
