import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/l10n/shipped_locales.dart';

/// The keys the AI work has added, checked against the ARB files themselves.
///
/// The generated `S` class only exposes the locale the test binding picks, so
/// a widget test can assert English and nothing else. A translated slot could
/// receive the English text pasted in, the broker disclosure could lose its
/// fourth sentence in one language, the own-server provider could be labelled
/// "local" — without a single failure elsewhere: `gen-l10n` warns and does
/// not fail, and `check_l10n` fails only on a structural error or a blank
/// value.
///
/// What this file does *not* check, since #1188 (#1174, #1199): that every
/// locale has every key. A code PR adds the English key only and the other
/// `intl_<code>.arb` files receive it from Weblate at their own pace, so a
/// locale without a key is skipped rather than failed — visibly: English, the
/// source, must have every key, and the untranslated-English check asserts a
/// floor on the locale×key pairs it actually looked at.
void main() {
  // The languages that ship, from the one map a human edits to ship one — not
  // every `intl_*.arb`, since Weblate lands files that are barely begun and
  // nothing here should be asserted of those.
  final locales = shippedLocales.keys.toList();
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
    // #850. The second rendering of `unknown`: a check that ran and came back
    // with no verdict, which is not the same claim as "nobody has asked".
    'aiAssistProbeNoAnswerLabel',
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

  /// The shipped locales that carry every one of [keys]: where a check that
  /// reads those keys can run. The rest have not received them from Weblate
  /// yet and show English by fallback, which is the policy, not a finding.
  ///
  /// English is always in the list — a key the source lacks is a typo in the
  /// caller, and a check that quietly ran on nobody would look like a pass.
  List<String> localesWith(List<String> keys) {
    final have = locales.where((l) => keys.every(arb[l]!.containsKey)).toList();
    expect(have, contains('en'), reason: 'the source lacks one of $keys');
    return have;
  }

  test('the source defines every checked key, and no landed slot is blank', () {
    // English is where a key is born, so a checked key that is not there is a
    // typo in `touched` — and since every check below runs only where a key
    // exists, the typo would make that key's checks vacuous everywhere.
    for (final key in touched) {
      expect(arb['en'], contains(key), reason: 'en is missing $key');
    }
    for (final locale in locales) {
      for (final key in touched.where(arb[locale]!.containsKey)) {
        expect(
          (arb[locale]![key] as String).trim(),
          isNotEmpty,
          reason: '$locale/$key is blank',
        );
      }
    }
  });

  test('no locale carries the English text in a translated slot', () {
    // The failure this catches is a real one and it is quiet: a translation
    // pass that inserts the key everywhere but only writes the source string.
    // Only where the key has landed: a locale that has not received it yet
    // shows English by fallback, which is #1188's policy, not this bug.
    var checked = 0;
    for (final locale in locales.where((l) => l != 'en')) {
      for (final key in touched.where(arb[locale]!.containsKey)) {
        expect(
          arb[locale]![key],
          isNot(arb['en']![key]),
          reason: '$locale/$key is untranslated English',
        );
        checked++;
      }
    }
    // Skipping has to stay visible, or a check that emptied itself — a skip
    // predicate that skips too much, a `touched` list that lost its entries
    // — would pass the same way a check that ran does. Every key in `touched`
    // was in all eight translated locales when #1199 was written, and a key
    // does not un-translate, so the figure only grows: a new key or a newly
    // shipped language adds to it as Weblate lands them. Lower it only for a
    // key retired from `touched` or a language that stops shipping — never
    // for a translation that went missing.
    const floor = 8 * 29;
    expect(
      checked,
      greaterThanOrEqualTo(floor),
      reason:
          'only $checked locale×key pairs were checked, below the $floor '
          'that were translated when this floor was set',
    );
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

    for (final locale in localesWith(['aiAssistDisclosureOpenRouter'])) {
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
    for (final locale in localesWith(['aiAssistProviderOwnServerLabel'])) {
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
    for (final locale in localesWith(['bulkAddPhotoDisclosureOwnServer'])) {
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

  test('the README names the destination it cannot name a party for', () {
    // #759. The privacy section is the falsifiable promise the project is
    // built on, and a fourth provider whose address the user supplies is the
    // one destination it cannot list as a company. Burying it in prose would
    // read as evasive, so it is a row — set apart from the contracted
    // parties, stating the rule rather than a host.
    final readme = File('README.md').readAsStringSync();
    final privacy = readme.substring(readme.indexOf('**What leaves your device.**'));

    expect(
      privacy,
      contains('The address you entered, and nothing else'),
      reason: 'the rule is the row; there is no party to put there',
    );
    // Both moments, because the address is contacted by an explicit fetch as
    // well as by sending a meal — a table that named only the second would
    // understate when the app talks to the machine.
    expect(privacy, contains('Load models'));
    expect(
      privacy,
      contains('No third party receives anything on this path'),
      reason: 'the honest claim, which is not "it never leaves"',
    );
  });

  test('the README never labels a destination "local"', () {
    // #736 settled that "local" is the word this feature must not use as a
    // label: it reads as *on the phone*, and the data does leave — to a
    // machine the user happens to own. Descriptive prose elsewhere is fine,
    // which is why this looks only at the destination cells.
    final readme = File('README.md').readAsStringSync().split('\n');
    final rows = readme.where(
      (line) => line.startsWith('| ') && line.split('|').length > 3,
    );
    for (final row in rows) {
      final destination = row.split('|')[1].trim().toLowerCase();
      expect(
        destination,
        isNot(contains('local')),
        reason: 'a destination cell reading "$destination" claims the data '
            'does not leave, and it does',
      );
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
    // phrase by phrase. The untranslated-English check above catches a slot
    // that still holds the source; a reviewer keeps the other languages
    // honest.
    const forbidden = [
      'your own network',
      'stays on your network',
      'only permitted because',
      'deinem eigenen netzwerk',
      'nur erlaubt, weil',
    ];
    for (final locale in localesWith([
      'aiAssistDisclosureOwnServerPlaintext',
    ])) {
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
    for (final locale in localesWith(['aiAssistProbeUnknownLabel'])) {
      final unknown = arb[locale]!['aiAssistProbeUnknownLabel'] as String;
      for (final key in [
        'aiAssistProbeTextFailedLabel',
        'aiAssistProbePhotoFailedLabel',
        'aiAssistProbePassedLabel',
        // #850 adds a fourth to the same set, and it is the one most at risk
        // of being folded back in: "not checked yet" and "checked, no
        // answer" are a hair apart in English and closer still once a
        // translator is working from the English alone.
        'aiAssistProbeNoAnswerLabel',
      ].where(arb[locale]!.containsKey)) {
        expect(
          unknown,
          isNot(arb[locale]![key]),
          reason: '$locale: "not checked yet" reads the same as $key',
        );
      }
    }
  });

  test('"checked, no answer" is not a verdict in any language (#850)', () {
    // The other direction. A check that came back with nothing must not read
    // as a check that came back with an answer — the whole reason a timeout
    // stays `AiCapability.unknown` is that it says nothing about the model,
    // and a locale that phrased this like the failure sentences would put the
    // blame the state model refuses to assign.
    for (final locale in localesWith(['aiAssistProbeNoAnswerLabel'])) {
      final noAnswer = arb[locale]!['aiAssistProbeNoAnswerLabel'] as String;
      for (final key in [
        'aiAssistProbePassedLabel',
        'aiAssistProbeTextFailedLabel',
        'aiAssistProbePhotoFailedLabel',
      ].where(arb[locale]!.containsKey)) {
        expect(
          noAnswer,
          isNot(arb[locale]![key]),
          reason: '$locale: "checked, no answer" reads the same as $key',
        );
      }
    }
  });

  test('the quoted wait carries the derived figure everywhere (#851)', () {
    // The running notice is the copy that invites the user to walk away, so
    // the number in it is what they use to decide when to come back. A locale
    // that dropped the placeholder would go back to stating a fixed duration
    // — which is the bug, in eight more languages, and silent because the
    // sentence still reads perfectly well.
    for (final locale in localesWith(['aiAssistProbeRunningLabel'])) {
      expect(
        arb[locale]!['aiAssistProbeRunningLabel'] as String,
        contains('{minutes'),
        reason: '$locale states a duration the code does not control',
      );
    }
  });

  test('the two capabilities are named apart in every locale', () {
    // The other half of the same decision. Two rows carrying the same label
    // is one combined verdict wearing a disguise.
    for (final locale in localesWith([
      'aiAssistProbeTextLabel',
      'aiAssistProbePhotoLabel',
    ])) {
      expect(
        arb[locale]!['aiAssistProbeTextLabel'],
        isNot(arb[locale]!['aiAssistProbePhotoLabel']),
        reason: '$locale names both capabilities the same',
      );
    }
    for (final locale in localesWith([
      'aiAssistProbeTextFailedLabel',
      'aiAssistProbePhotoFailedLabel',
    ])) {
      expect(
        arb[locale]!['aiAssistProbeTextFailedLabel'],
        isNot(arb[locale]!['aiAssistProbePhotoFailedLabel']),
        reason: '$locale: a failed photo and a failed text mean different '
            'things — one hides the camera, the other turns nothing off',
      );
    }
  });
}
