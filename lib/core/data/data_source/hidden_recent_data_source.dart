import 'dart:convert';

import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:logging/logging.dart';
import 'package:opennutritracker/core/utils/hive_db_provider.dart';
import 'package:opennutritracker/core/utils/id_generator.dart';
import 'package:uuid/uuid.dart';

/// The active profile's record of which diary entries stand behind a food
/// the user removed from the add-meal Recently list (#1198).
///
/// It holds entry ids, not foods: a Recently row is hidden while every entry
/// behind it is in here, so logging the food again — a new entry with a new
/// id, on whatever day — brings the row back on its own. Nothing here ever
/// deletes an entry or a saved food.
class HiddenRecentDataSource {
  final log = Logger('HiddenRecentDataSource');
  final HiveDBProvider _db;

  HiddenRecentDataSource(this._db);

  Box<DateTime> get _box => _db.hiddenRecentBox;

  /// Whether the entry [intakeId] was hidden from Recently.
  bool Function(String intakeId) hiddenIntakes() {
    final box = _box;
    if (box.isEmpty) return (_) => false;
    return (intakeId) => box.containsKey(keyFor(intakeId));
  }

  /// Hides the entries [intakeIds] from Recently, noting when.
  Future<void> hide(Iterable<String> intakeIds, DateTime at) async {
    final entries = {for (final id in intakeIds) keyFor(id): at};
    if (entries.isEmpty) return;
    log.fine('Hiding ${entries.length} entries from Recently');
    await _box.putAll(entries);
  }

  /// The Hive key of [intakeId]. Hive writes a string key's length in one
  /// byte, so an id longer than [_maxKeyBytes] of UTF-8 (one an imported
  /// file brought in, say) is stored as `#` and a name-based UUID of it; no
  /// id the app generates starts with `#`.
  static String keyFor(String intakeId) {
    if (utf8.encode(intakeId).length <= _maxKeyBytes) return intakeId;
    final hash = IdGenerator.uuid.v5(
      Namespace.url.value,
      'opennutritracker-hidden-recent:$intakeId',
    );
    return '#$hash';
  }

  static const _maxKeyBytes = 255;
}
