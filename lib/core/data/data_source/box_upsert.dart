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

/// Whether [id] carries no identity: empty, or only whitespace (a hand-
/// edited backup). No generated id looks like that.
bool isBlankId(String id) => id.trim().isEmpty;

/// A number as a [withContentIds] content field. `-0.0` reads as `0.0`:
/// the CSV writes either as `0`, so the JSON file must derive the same id.
String contentNumber(double value) => (value == 0 ? 0.0 : value).toString();

/// Gives each row in [items] whose id is blank ([isBlankId]: a hand-edited
/// CSV, an old export) an id derived from its content, so it has an
/// identity like any other row: importing the same file again replaces it
/// instead of adding it once more, and no two stored rows share the blank
/// id the meal lists key their cards by (#1357). Rows with equal content
/// are told apart by how many came before them in [items], so two
/// identical entries both survive. Rows that already have an id are
/// returned unchanged, and no derived id repeats one of theirs: an export
/// of an earlier id-less import carries the derived id, and a copy of that
/// row with its id cleared takes the next occurrence instead of merging
/// with it.
///
/// [contentOf] lists the fields that make up a row's content, each already
/// a string, in a fixed order. It names them by hand rather than reading
/// the generated serializer, so a field a later version adds, or a change
/// to how one is serialized, leaves the id of the same backup row where it
/// was. Each field is trimmed and a blank one counts as null, as the CSV
/// reader leaves them, so the JSON file and the CSV derive the same id.
/// Nothing here encodes a double, so a non-finite value cannot throw.
List<T> withContentIds<T>(
  List<T> items, {
  required String Function(T item) idOf,
  required List<String?> Function(T item) contentOf,
  required T Function(T item, String id) withId,
}) {
  final taken = {
    for (final item in items)
      if (!isBlankId(idOf(item))) idOf(item),
  };
  final seen = <String, int>{};
  final out = <T>[];
  for (final item in items) {
    if (!isBlankId(idOf(item))) {
      out.add(item);
      continue;
    }
    final content = jsonEncode([
      for (final field in contentOf(item))
        (field == null || isBlankId(field)) ? null : field.trim(),
    ]);
    var occurrence = seen[content] ?? 0;
    String id;
    do {
      id = IdGenerator.getContentID('$content#${occurrence++}');
    } while (!taken.add(id));
    seen[content] = occurrence;
    out.add(withId(item, id));
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
