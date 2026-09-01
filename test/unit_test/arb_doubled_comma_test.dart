import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// No translated string may carry a comma twice in a row.
///
/// #849: eight own-server disclosure strings shipped as `... auslesen lässt,,
/// an {host} gesendet ...` in `cs`, `de`, `sk` and `uk`. Nothing in the gate
/// noticed. `gen-l10n` only cares that the placeholders line up, the parity
/// test only cares that a key exists and differs from English, and no widget
/// test can read eight locales at once — so a punctuation slip survives all
/// the way to the screen, and this one was found by a person looking at a
/// phone.
///
/// A doubled comma is worth a test of its own because of where it comes from:
/// it is the fingerprint of a machine translation nobody read. The four
/// locales carrying it were written that way, and the same pipeline will write
/// the next batch. So this guards every locale and every key rather than the
/// two keys that were wrong — the point is to catch the *next* string, in a
/// language this repo cannot review, before it ships.
///
/// Locales are read off disk rather than listed, so a tenth language is
/// covered the day its ARB lands.
void main() {
  // A comma, the full-width comma, and the ideographic comma — `zh` writes
  // its lists with the latter two, and doubling one of those is the same
  // mistake in a different codepoint. Whitespace between them still counts:
  // `, ,` is not a thing any of these languages does either.
  final doubled = RegExp(r'[,，、]\s*[,，、]');

  final arbs = Directory('lib/l10n')
      .listSync()
      .whereType<File>()
      .where((f) => f.path.endsWith('.arb'))
      .toList()
    ..sort((a, b) => a.path.compareTo(b.path));

  test('the scan actually reaches the strings', () {
    // Without this the suite passes just as happily on an empty directory, a
    // renamed folder, or a `whereType` that quietly matches nothing.
    expect(arbs.length, greaterThanOrEqualTo(9), reason: 'found: $arbs');
    expect(
      doubled.hasMatch('auslesen lässt,, an {host}'),
      isTrue,
      reason: 'the pattern must match the string that prompted #849',
    );
  });

  test('no locale writes a comma twice in a row', () {
    final offenders = <String>[];
    for (final arb in arbs) {
      final locale = arb.uri.pathSegments.last;
      final messages =
          jsonDecode(arb.readAsStringSync()) as Map<String, dynamic>;
      for (final entry in messages.entries) {
        final value = entry.value;
        if (value is! String) continue; // `@key` metadata is a map.
        final match = doubled.firstMatch(value);
        if (match == null) continue;
        final from = (match.start - 30).clamp(0, value.length);
        final to = (match.end + 30).clamp(0, value.length);
        offenders.add('$locale/${entry.key}: ...${value.substring(from, to)}...');
      }
    }
    expect(offenders, isEmpty, reason: offenders.join('\n'));
  });
}
