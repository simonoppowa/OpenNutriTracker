import 'package:hive_ce_flutter/hive_flutter.dart';

/// Bulk upsert for boxes whose rows carry their own identity (an `id`,
/// a template name) rather than using it as the Hive key.
extension BoxUpsert<T> on Box<T> {
  /// Writes [items] so the box ends up with exactly one row per
  /// [identityOf] value among them (#1357).
  ///
  /// An item whose identity is already stored replaces that row in place;
  /// any further rows sharing the identity — left behind by the import
  /// that used to append — are deleted. Within [items] the last one with
  /// a given identity wins. Rows whose identity is not among [items] are
  /// left alone, and new identities are appended.
  Future<void> upsertAllBy(
    Iterable<T> items,
    Object Function(T item) identityOf,
  ) async {
    final keysByIdentity = <Object, List<dynamic>>{};
    for (final entry in toMap().entries) {
      keysByIdentity
          .putIfAbsent(identityOf(entry.value), () => [])
          .add(entry.key);
    }
    final latest = <Object, T>{
      for (final item in items) identityOf(item): item,
    };

    final replacements = <dynamic, T>{};
    final staleKeys = <dynamic>[];
    final additions = <T>[];
    latest.forEach((identity, item) {
      final existingKeys = keysByIdentity[identity];
      if (existingKeys == null) {
        additions.add(item);
      } else {
        replacements[existingKeys.first] = item;
        staleKeys.addAll(existingKeys.skip(1));
      }
    });

    await deleteAll(staleKeys);
    await putAll(replacements);
    await addAll(additions);
  }
}
