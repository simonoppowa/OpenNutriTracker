import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The two keys #726 touched, checked against the ARB files themselves.
///
/// The generated `S` class only exposes the locale the test binding picks, so
/// a widget test can assert English and nothing else. Eight files could lose a
/// translation — or receive the English text pasted into a translated slot —
/// without a single failure. `gen-l10n` warns about a missing key and does not
/// fail on one, so nothing else in the gate catches it either.
void main() {
  const locales = ['cs', 'de', 'en', 'it', 'pl', 'sk', 'tr', 'uk', 'zh'];
  const touched = [
    'aiAssistModelCheapestLabel',
    'aiAssistDisclosureOpenRouter',
    // #758.
    'bulkAddModelInsecureServerLabel',
  ];

  final arb = {
    for (final locale in locales)
      locale:
          jsonDecode(File('lib/l10n/intl_$locale.arb').readAsStringSync())
              as Map<String, dynamic>,
  };

  test('every locale defines the keys, non-empty', () {
    for (final locale in locales) {
      for (final key in touched) {
        expect(arb[locale], contains(key), reason: '$locale is missing $key');
        expect((arb[locale]![key] as String).trim(), isNotEmpty, reason: key);
      }
    }
  });

  test('no locale carries the English text in a translated slot', () {
    // The failure this catches is a real one and it is quiet: a translation
    // pass that inserts the key everywhere but only writes the source string.
    for (final locale in locales.where((l) => l != 'en')) {
      for (final key in touched) {
        expect(
          arb[locale]![key],
          isNot(arb['en']![key]),
          reason: '$locale/$key is untranslated English',
        );
      }
    }
  });

  test('every translation of the broker disclosure gained the new sentence', () {
    // Counted, not measured by length. Length was the first attempt and a
    // mutation walked straight through it: the German paragraph is far longer
    // than its Anthropic sibling with or without the appended sentence,
    // because it also carries the identity-forwarding and retention clauses.
    //
    // The paragraph is four sentences in all nine languages and the fourth is
    // the one #726 added, so a locale that lost it counts three. Compared
    // against English rather than a literal 4, so rewording the paragraph
    // everywhere at once stays green while dropping it anywhere does not.
    int sentences(String s) => '.。'.split('').fold(0, (n, c) => n + s.split(c).length - 1);

    final expected = sentences(arb['en']!['aiAssistDisclosureOpenRouter'] as String);
    expect(expected, greaterThan(1), reason: 'guard against a vacuous compare');

    for (final locale in locales) {
      expect(
        sentences(arb[locale]!['aiAssistDisclosureOpenRouter'] as String),
        expected,
        reason:
            '$locale: the last sentence is the serving vendor\'s own '
            'retention, and it is the only thing standing between an OpenAI '
            'row on this list and telling that user less than the direct path '
            'tells them',
      );
    }
  });

  test('the key counts have not drifted', () {
    // #650: nine files, one insertion each, counts equal afterwards.
    final counts = {
      for (final locale in locales)
        locale: arb[locale]!.keys.where((k) => !k.startsWith('@')).length,
    };
    expect(counts.values.toSet().length, 1, reason: 'drift: $counts');
  });
}
