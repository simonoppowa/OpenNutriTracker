import 'dart:io';

import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:opennutritracker/core/data/dbo/meal_dbo.dart';

/// Local cache of remote meal lookups (Open Food Facts AND Supabase FDC).
/// Every successful network search or barcode lookup writes its result
/// here so that subsequent searches and scans for the same product
/// resolve from disk — fast, and works offline.
///
/// Cached entries keep their original [MealSourceDBO] (`off` / `fdc`);
/// they are NOT custom meals, just a local mirror of the remote result
/// we last saw. This is separate from `CustomMealBox` so the user's own
/// meals stay distinct from cached remote data and can be deleted
/// independently.
///
/// Each entry has an associated "last touched" timestamp stored in a
/// sidecar box. The timestamp is set on initial cache and refreshed
/// whenever the user explicitly selects (logs an intake of) the item.
/// [pruneStale] drops entries whose timestamp is older than the supplied
/// age — typically 90 days, called on app startup.
///
/// The on-disk box names (`CachedOffMealBox`, `CachedOffMealTimestampsBox`)
/// are kept for backward compatibility with installs that already have
/// data in them; only the Dart class name was generalised when FDC
/// caching was added.
class RemoteSearchCacheDataSource {
  final Box<MealDBO> _cacheBox;
  final Box<int> _timestampsBox;

  RemoteSearchCacheDataSource(this._cacheBox, this._timestampsBox);

  /// Persist [meal] in the cache and stamp its "last touched" timestamp
  /// to the current time. If a cached entry with the same code (or, when
  /// code is null, the same name) already exists, it is overwritten so
  /// the freshest remote result wins.
  Future<void> cache(MealDBO meal) async {
    final index = _buildDedupIndex();
    final existingKey = _lookupExistingKey(meal, index);
    if (existingKey != null) {
      await _cacheBox.put(existingKey, meal);
    } else {
      await _cacheBox.add(meal);
    }
    final tsKey = _timestampKey(meal);
    if (tsKey != null) {
      await _timestampsBox.put(tsKey, DateTime.now().millisecondsSinceEpoch);
    }
  }

  /// Persist all of [meals] in one pass. Touches the timestamp on every
  /// entry — for that reason this is the right choice for intent-driven
  /// writes (a barcode scan that returned multiple variants, etc) but
  /// the wrong choice for bulk caching a search result page; use
  /// [cacheFromSearch] for that.
  Future<void> cacheAll(Iterable<MealDBO> meals) async {
    final index = _buildDedupIndex();
    final now = DateTime.now().millisecondsSinceEpoch;
    for (final meal in meals) {
      final existingKey = _lookupExistingKey(meal, index);
      if (existingKey != null) {
        await _cacheBox.put(existingKey, meal);
      } else {
        final newKey = await _cacheBox.add(meal);
        // Keep the index live so a duplicate later in the same batch
        // overwrites this entry rather than producing a second copy.
        _registerInIndex(meal, newKey, index);
      }
      final tsKey = _timestampKey(meal);
      if (tsKey != null) {
        await _timestampsBox.put(tsKey, now);
      }
    }
  }

  /// Persist a remote search result page. New entries are inserted and
  /// stamped with the current time; entries that already exist get their
  /// data refreshed but **keep their existing timestamp**, so the
  /// "user-selected this recently" signal isn't wiped out by an
  /// unrelated re-search of the same query.
  ///
  /// Exception: if the existing cached entry has user-enriched nutrients
  /// (non-zero kcal) but the incoming remote result does not, the existing
  /// data is kept so manually entered values aren't silently erased.
  Future<void> cacheFromSearch(Iterable<MealDBO> meals) async {
    final index = _buildDedupIndex();
    final now = DateTime.now().millisecondsSinceEpoch;
    for (final meal in meals) {
      final existingKey = _lookupExistingKey(meal, index);
      if (existingKey != null) {
        final existing = _cacheBox.get(existingKey);
        // Preserve user-enriched nutrients: if the cached entry already has
        // kcal data but the incoming remote result doesn't, keep the existing
        // entry so manually entered values survive a re-search.
        final keepExisting = existing != null && _hasNutrients(existing) && !_hasNutrients(meal);
        if (!keepExisting) {
          await _cacheBox.put(existingKey, meal);
        }
      } else {
        final newKey = await _cacheBox.add(meal);
        _registerInIndex(meal, newKey, index);
        final tsKey = _timestampKey(meal);
        if (tsKey != null) {
          await _timestampsBox.put(tsKey, now);
        }
      }
    }
  }

  /// True when [meal] carries meaningful energy data (i.e. a user has
  /// enriched it manually or the remote source returned nutrient values).
  bool _hasNutrients(MealDBO meal) {
    final kcal = meal.nutriments.energyKcal100;
    return kcal != null && kcal > 0;
  }

  /// Snapshot the cache box into a per-call dedup index. Two maps so
  /// barcode-keyed entries and name-keyed entries don't collide on a
  /// shared key namespace.
  ///
  /// The index lives only for the duration of a single cache(All|FromSearch)
  /// call — bookkeeping a long-lived index inside the data source would
  /// be more invasive than the speedup justifies, and Hive's `.values`
  /// already iterates over an in-memory map so the snapshot is cheap.
  _DedupIndex _buildDedupIndex() {
    final byCode = <String, dynamic>{};
    final byName = <String, dynamic>{};
    for (final entry in _cacheBox.toMap().entries) {
      final meal = entry.value;
      final code = meal.code;
      if (code != null && code.isNotEmpty) {
        byCode[code] = entry.key;
      } else {
        final name = meal.name;
        if (name != null && name.isNotEmpty) {
          byName[name] = entry.key;
        }
      }
    }
    return _DedupIndex(byCode: byCode, byName: byName);
  }

  dynamic _lookupExistingKey(MealDBO meal, _DedupIndex index) {
    final code = meal.code;
    if (code != null && code.isNotEmpty) return index.byCode[code];
    final name = meal.name;
    if (name != null && name.isNotEmpty) return index.byName[name];
    return null;
  }

  void _registerInIndex(MealDBO meal, dynamic boxKey, _DedupIndex index) {
    final code = meal.code;
    if (code != null && code.isNotEmpty) {
      index.byCode[code] = boxKey;
      return;
    }
    final name = meal.name;
    if (name != null && name.isNotEmpty) {
      index.byName[name] = boxKey;
    }
  }

  List<MealDBO> getAll() => _cacheBox.values.toList();

  /// Returns cached entries sorted with the most recently touched first.
  /// Entries with no timestamp record sort last. Used by search to put
  /// items the user just selected at the top of the result list.
  List<MealDBO> getAllByMostRecentlyTouched() {
    final entries = _cacheBox.values.toList();
    entries.sort((a, b) {
      final aTs = _timestampFor(a) ?? 0;
      final bTs = _timestampFor(b) ?? 0;
      return bTs.compareTo(aTs);
    });
    return entries;
  }

  int? _timestampFor(MealDBO meal) {
    final key = _timestampKey(meal);
    if (key == null) return null;
    return _timestampsBox.get(key);
  }

  /// Look up a single cached meal by barcode. Returns null when none
  /// matches — the caller should then fall back to the remote API.
  MealDBO? getByBarcode(String barcode) {
    for (final meal in _cacheBox.values) {
      if (meal.code == barcode) return meal;
    }
    return null;
  }

  /// Refresh the "last touched" timestamp for [code] without changing
  /// the cached meal data. Called when the user selects (logs) an item
  /// that was already in the cache, signalling continued interest.
  Future<void> touch(String code) async {
    if (code.isEmpty) return;
    await _timestampsBox.put(code, DateTime.now().millisecondsSinceEpoch);
  }

  int get count => _cacheBox.length;

  /// On-disk size of the cache box plus the timestamps sidecar in bytes.
  /// Returns 0 when the box files haven't been flushed yet or the path
  /// can't be statted (e.g. in tests on an in-memory Hive). Used by
  /// Settings to show how much space the cache is occupying.
  Future<int> getStorageSizeBytes() async {
    var total = 0;
    for (final path in [_cacheBox.path, _timestampsBox.path]) {
      if (path == null) continue;
      final file = File(path);
      if (!await file.exists()) continue;
      total += await file.length();
    }
    return total;
  }

  /// Drop cached entries that haven't been touched within [maxAge].
  /// "Untouched" includes entries with no timestamp record at all (e.g.
  /// data left over from a build before the TTL feature existed) — those
  /// are treated as immediately stale.
  ///
  /// Returns the number of entries removed. Call once at app startup.
  Future<int> pruneStale(Duration maxAge) async {
    final cutoff = DateTime.now().subtract(maxAge).millisecondsSinceEpoch;
    final keysToDelete = <dynamic>[];
    final timestampKeysToDelete = <String>[];

    for (final entry in _cacheBox.toMap().entries) {
      final tsKey = _timestampKey(entry.value);
      if (tsKey == null) {
        // No way to track an age for this entry — drop it.
        keysToDelete.add(entry.key);
        continue;
      }
      final lastTouched = _timestampsBox.get(tsKey);
      if (lastTouched == null || lastTouched < cutoff) {
        keysToDelete.add(entry.key);
        timestampKeysToDelete.add(tsKey);
      }
    }

    if (keysToDelete.isNotEmpty) {
      await _cacheBox.deleteAll(keysToDelete);
    }
    if (timestampKeysToDelete.isNotEmpty) {
      await _timestampsBox.deleteAll(timestampKeysToDelete);
    }
    return keysToDelete.length;
  }

  Future<void> clear() async {
    await _cacheBox.clear();
    await _timestampsBox.clear();
  }

  /// Use the meal's barcode as the timestamp key when present, falling
  /// back to its name. Matches the dedup key used inside [cache].
  String? _timestampKey(MealDBO meal) {
    if (meal.code != null && meal.code!.isNotEmpty) return meal.code;
    if (meal.name != null && meal.name!.isNotEmpty) return meal.name;
    return null;
  }
}

class _DedupIndex {
  final Map<String, dynamic> byCode;
  final Map<String, dynamic> byName;

  _DedupIndex({required this.byCode, required this.byName});
}
