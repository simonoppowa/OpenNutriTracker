import 'dart:convert';

import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:opennutritracker/core/utils/id_generator.dart';

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

/// Gives each row in [items] whose id is blank (a hand-edited CSV, an old
/// export) an id derived from its content, so it has an identity like any
/// other row: importing the same file again replaces it instead of adding
/// it once more, and no two stored rows share the blank id the meal lists
/// key their cards by (#1357). Rows with equal content are told apart by
/// how many came before them in [items], so two identical entries both
/// survive. Rows that already have an id are returned unchanged.
List<T> withContentIds<T>(
  List<T> items, {
  required String Function(T item) idOf,
  required Map<String, dynamic> Function(T item) toJson,
  required T Function(Map<String, dynamic> json) fromJson,
}) {
  final seen = <String, int>{};
  final out = <T>[];
  for (final item in items) {
    if (idOf(item).isNotEmpty) {
      out.add(item);
      continue;
    }
    // Round-trip through JSON so nested DBOs become plain maps.
    final json =
        jsonDecode(jsonEncode(toJson(item))) as Map<String, dynamic>
          ..remove('id');
    final content = jsonEncode(json);
    final occurrence = seen.update(
      content,
      (count) => count + 1,
      ifAbsent: () => 0,
    );
    json['id'] = IdGenerator.getContentID('$content#$occurrence');
    out.add(fromJson(json));
  }
  return out;
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
  /// [identityOf] returns null for a row that has no identity (a blank id
  /// stored by an import before [withContentIds]): such a row is always
  /// appended, and is never merged with another row, in [items] or in the
  /// box.
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
