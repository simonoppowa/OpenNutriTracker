import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The keys the AI work has added, checked against the ARB files themselves.
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
    // #774.
    'bulkAddModelTimedOutLabel',
    // #758.
    'bulkAddModelInsecureServerLabel',
    // #756
    'aiAssistProviderOwnServerLabel',
    'aiAssistEndpointFieldLabel',
    'aiAssistModelFieldLabel',
    'aiAssistDisclosureOwnServerSecure',
    'aiAssistDisclosureOwnServerPlaintext',
    // What the dialog says instead of storing an address that can never be
    // requested, or a server with no model to ask for.
    'aiAssistEndpointInvalidLabel',
    'aiAssistModelRequiredLabel',
    // #780. The setup check, reported per capability — and the save-time
    // refusal folded in from #758.
    'aiAssistEndpointPublicPlaintextLabel',
    'aiAssistProbeSectionLabel',
    'aiAssistProbeRunningLabel',
    'aiAssistProbeCheckLabel',
    'aiAssistProbeTextLabel',
    'aiAssistProbePhotoLabel',
    'aiAssistProbePassedLabel',
    'aiAssistProbeUnknownLabel',
    'aiAssistProbeTextFailedLabel',
    'aiAssistProbePhotoFailedLabel',
    // #781. The one sheet that names a destination the app cannot name by
    // company, so it names the address instead.
    'bulkAddPhotoDisclosureOwnServer',
    // #757. The four outcomes of asking a server what it has, which have to
    // stay four different sentences in every language: an unreachable server
    // and one with nothing pulled produce the same empty picker and want
    // opposite fixes.
    'aiAssistLoadModelsLabel',
    'aiAssistPickModelLabel',
    'aiAssistModelsUnreachableLabel',
    'aiAssistModelsEmptyLabel',
    'aiAssistModelsRejectedLabel',
    'aiAssistModelsInsecureLabel',
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

  test('the provider is never called "local", in any language', () {
    // #736: *local* is what the ecosystem calls Ollama **and** what a user
    // reads as *on my phone*. Labelling this provider with it would promise
    // on-device inference, which this app does not do and which was ruled
    // out of scope. The word may appear descriptively in prose; it may not be
    // the name of the thing.
    for (final locale in locales) {
      final label =
          arb[locale]!['aiAssistProviderOwnServerLabel'] as String;
      expect(
        label.toLowerCase(),
        isNot(contains('local')),
        reason: '$locale labels the provider "local"',
      );
    }
  });

  test('the photo sheet names the address, and no company', () {
    // #781. This is the one destination the app can name *exactly* rather
    // than by company — and the one it must not name by company, because
    // there is no company: the address is the whole of what is known. A
    // locale that dropped the placeholder would send a photograph after
    // showing a sentence with a hole in it; one that pasted a vendor in
    // would name a party that may have nothing to do with the machine.
    for (final locale in locales) {
      final value = arb[locale]!['bulkAddPhotoDisclosureOwnServer'] as String;
      expect(
        value,
        contains('{host}'),
        reason: '$locale drops the address the sentence exists to name',
      );
      for (final company in ['Anthropic', 'OpenAI', 'OpenRouter', 'Google']) {
        expect(
          value,
          isNot(contains(company)),
          reason:
              '$locale names $company for a machine the app knows nothing '
              'about',
        );
      }
    }
  });

  test('no AI string claims the data stays on the device', () {
    // The other half of the same trap. Data does leave — it goes to a machine
    // the user controls, which is "no third party", not "never leaves".
    // Deliberately narrow. A first draft forbade "on this device" and fired
    // on `aiAssistDisclosureCommon` — *"the key is stored on this device
    // only"* — which is true, load-bearing, and about the **key** rather than
    // the meal. The trap is claiming the *content* never leaves; saying where
    // a credential lives is the opposite of the problem.
    const forbidden = [
      'never leaves your device',
      'never leaves this device',
      'stays on your device',
      'stays on this device',
      'processed on your device',
      'processed on-device',
      'verlässt dein gerät nie',
      'bleibt auf deinem gerät',
      'auf deinem gerät verarbeitet',
    ];
    for (final locale in locales) {
      for (final entry in arb[locale]!.entries) {
        if (!entry.key.startsWith('aiAssist') &&
            !entry.key.startsWith('bulkAddPhoto')) {
          continue;
        }
        final value = entry.value;
        if (value is! String) continue;
        for (final phrase in forbidden) {
          expect(
            value.toLowerCase(),
            isNot(contains(phrase)),
            reason: '$locale/${entry.key} claims on-device processing',
          );
        }
      }
    }
  });

  test('the plaintext clause promises no boundary nobody enforces', () {
    // It used to end *"it is only permitted because it stays on your own
    // network"*, which asserts two things the app does not do: it permits
    // plain HTTP to any host, and it cannot know where that host is. On a
    // LAN address the sentence was accidentally reassuring; on
    // `http://example.com` it was simply false, in nine languages, at the
    // moment the user is agreeing to send their meals there.
    //
    // #758 may yet restrict plain HTTP to private addresses. Until something
    // checks, nothing here may say it has been checked — and if #758 lands,
    // the sentence it earns is a new one rather than this one returning.
    //
    // Narrow in the same way the on-device guard above is narrow, and for the
    // same reason: these are the two languages this repo can vouch for
    // phrase by phrase. The parity test keeps the key present everywhere; a
    // reviewer keeps the other seven honest.
    const forbidden = [
      'your own network',
      'stays on your network',
      'only permitted because',
      'deinem eigenen netzwerk',
      'nur erlaubt, weil',
    ];
    for (final locale in locales) {
      final value =
          arb[locale]!['aiAssistDisclosureOwnServerPlaintext'] as String;
      for (final phrase in forbidden) {
        expect(
          value.toLowerCase(),
          isNot(contains(phrase)),
          reason: '$locale claims a network boundary the app never checks',
        );
      }
    }
  });

  test('"never ran" and "checked and failed" read differently everywhere', () {
    // #735 settled that these are two states rather than one, and the widget
    // test can only vouch for English. A translator handed nine near-identical
    // short sentences is exactly who would collapse them, and the result would
    // be a user told their model cannot see when nobody has asked it yet.
    for (final locale in locales) {
      final unknown = arb[locale]!['aiAssistProbeUnknownLabel'] as String;
      for (final key in [
        'aiAssistProbeTextFailedLabel',
        'aiAssistProbePhotoFailedLabel',
        'aiAssistProbePassedLabel',
      ]) {
        expect(
          unknown,
          isNot(arb[locale]![key]),
          reason: '$locale: "not checked yet" reads the same as $key',
        );
      }
    }
  });

  test('the two capabilities are named apart in every locale', () {
    // The other half of the same decision. Two rows carrying the same label
    // is one combined verdict wearing a disguise.
    for (final locale in locales) {
      expect(
        arb[locale]!['aiAssistProbeTextLabel'],
        isNot(arb[locale]!['aiAssistProbePhotoLabel']),
        reason: '$locale names both capabilities the same',
      );
      expect(
        arb[locale]!['aiAssistProbeTextFailedLabel'],
        isNot(arb[locale]!['aiAssistProbePhotoFailedLabel']),
        reason: '$locale: a failed photo and a failed text mean different '
            'things — one hides the camera, the other turns nothing off',
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
