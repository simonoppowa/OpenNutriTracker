import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// No two activities may share an English name in `intl_en.arb`.
///
/// #1200: `paDivingSpringboardPlatform` read "diving", the same as
/// `paDivingGeneral` (3.0 vs 7.0 MET), and `paAmericanFootballGeneral` read
/// "football", which most languages render as soccer — a separate activity.
/// A translator carried both faithfully and the picker showed two identical
/// rows that burn very different calories. Four more pairs (boxing, martial
/// arts, rugby, high intensity interval exercise) had the same shape.
///
/// The picker shows the description under the name, but the home and diary
/// cards, the collapsed detail-screen title and the search all show the name
/// alone — so the name has to carry the distinction on its own. The source
/// is checked, not the translations: Weblate re-requests a translation when
/// its source changes, and the shipped locales inherit whatever English does.
///
/// `paHeading*` keys are section titles ("bicycling" above the bicycling
/// rows), not activities, and are excluded on purpose.
void main() {
  final source = File('lib/l10n/intl_en.arb');
  final activityName = RegExp(r'^pa[A-Z]\w*$');

  Map<String, String> activityNames() {
    final messages =
        jsonDecode(source.readAsStringSync()) as Map<String, dynamic>;
    return {
      for (final entry in messages.entries)
        if (entry.value is String &&
            activityName.hasMatch(entry.key) &&
            !entry.key.endsWith('Desc') &&
            !entry.key.startsWith('paHeading'))
          entry.key: entry.value as String,
    };
  }

  test('the scan actually reaches the activity names', () {
    final names = activityNames();
    expect(names.length, greaterThanOrEqualTo(100), reason: 'found: $names');
    expect(names, contains('paDivingSpringboardPlatform'));
    expect(names, isNot(contains('paDivingSpringboardPlatformDesc')));
    expect(names, isNot(contains('paHeadingBicycling')));
  });

  test('no two activities share an English name', () {
    final byName = <String, List<String>>{};
    for (final entry in activityNames().entries) {
      byName
          .putIfAbsent(entry.value.trim().toLowerCase(), () => [])
          .add(entry.key);
    }
    final collisions = [
      for (final entry in byName.entries)
        if (entry.value.length > 1) '"${entry.key}": ${entry.value.join(', ')}',
    ];
    expect(collisions, isEmpty, reason: collisions.join('\n'));
  });
}
