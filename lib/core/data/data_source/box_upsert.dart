import 'package:hive_ce_flutter/hive_flutter.dart';

/// Which row survives when one identity appears more than once (#1357).
///
/// An install hit by the import that used to append holds two copies of
/// each id, and its export writes the box in order. Where an edit made
/// before this fix landed depends on the type, so the policy does too:
enum UpsertWinner {
  /// The old intake edit rewrote the first copy in place, so the first
  /// row is the edited one.
  first,

  /// The old activity edit and template save deleted the first copy and
  /// appended the edited one, so the last row is the edited one.
  last,
}

/// Bulk upsert for boxes whose rows carry their own identity (an `id`,
/// a template name) rather than using it as the Hive key.
extension BoxUpsert<T> on Box<T> {
  /// Writes [items] so the box ends up with exactly one row per
  /// [identityOf] value among them (#1357).
  ///
  /// An item whose identity is already stored replaces the first such row
  /// in place; any further rows sharing the identity are deleted. Within
  /// [items], [winner] picks which of several rows with one identity is
  /// written. Rows whose identity is not among [items] are left alone, and
  /// new identities are appended.
  ///
  /// [identityOf] returns null for a row that has no identity (a CSV row
  /// with a blank id): such a row is always appended, and is never merged
  /// with another row, in [items] or in the box.
  Future<void> upsertAllBy(
    Iterable<T> items,
    Object? Function(T item) identityOf, {
    required UpsertWinner winner,
  }) async {
    final keysByIdentity = <Object, List<dynamic>>{};
    for (final entry in toMap().entries) {
      final identity = identityOf(entry.value);
      if (identity == null) continue;
      keysByIdentity.putIfAbsent(identity, () => []).add(entry.key);
    }
    final incoming = <Object, T>{};
    final additions = <T>[];
    for (final item in items) {
      final identity = identityOf(item);
      if (identity == null) {
        additions.add(item);
      } else if (winner == UpsertWinner.last) {
        incoming[identity] = item;
      } else {
        incoming.putIfAbsent(identity, () => item);
      }
    }

    final replacements = <dynamic, T>{};
    final staleKeys = <dynamic>[];
    incoming.forEach((identity, item) {
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
