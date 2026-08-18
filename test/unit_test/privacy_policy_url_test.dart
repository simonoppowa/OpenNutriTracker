import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/utils/url_const.dart';
import 'package:opennutritracker/generated/l10n.dart';

void main() {
  group('URLConst.privacyPolicyFor', () {
    test('a German device gets the German policy', () {
      expect(URLConst.privacyPolicyFor('de'), URLConst.privacyPolicyURLDe);
    });

    test('English gets the English policy', () {
      expect(URLConst.privacyPolicyFor('en'), URLConst.privacyPolicyURLEn);
    });

    test('the two documents are actually different', () {
      // Guards the whole point of this function: if the constants ever
      // collapse to one URL the tests above would still pass while the
      // German reader was silently back on the English document.
      expect(URLConst.privacyPolicyURLDe, isNot(URLConst.privacyPolicyURLEn));
    });

    test('a locale with no policy of its own falls back to English', () {
      // Nine locales ship and two documents exist. Sending a Czech reader to
      // a German document would be worse than the English fallback, so the
      // rule stays narrow on purpose.
      for (final code in ['cs', 'sk', 'pl', 'it', 'tr', 'uk', 'zh']) {
        expect(
          URLConst.privacyPolicyFor(code),
          URLConst.privacyPolicyURLEn,
          reason: '$code has no policy document of its own',
        );
      }
    });

    test('every shipped locale resolves to a policy that exists', () {
      // If a tenth locale is added, this fails only if the function starts
      // returning something that is neither document — not merely because
      // the new locale lacks its own translation.
      for (final locale in S.supportedLocales) {
        expect(
          URLConst.privacyPolicyFor(locale.languageCode),
          anyOf(URLConst.privacyPolicyURLEn, URLConst.privacyPolicyURLDe),
          reason: '${locale.languageCode} resolved to an unknown document',
        );
      }
    });

    test('German is the only shipped locale routed away from English', () {
      final routedToGerman = S.supportedLocales
          .map((locale) => locale.languageCode)
          .where(
            (code) => URLConst.privacyPolicyFor(code) ==
                URLConst.privacyPolicyURLDe,
          )
          .toList();

      expect(
        routedToGerman,
        ['de'],
        reason: 'only German has a document of its own today',
      );
    });

    test('an unknown language code does not throw', () {
      expect(URLConst.privacyPolicyFor('xx'), URLConst.privacyPolicyURLEn);
      expect(URLConst.privacyPolicyFor(''), URLConst.privacyPolicyURLEn);
    });
  });

  test('no screen reaches past the selector to a policy URL', () {
    // The bug this fixes was two call sites each hardcoding the English URL,
    // so the regression to guard is a screen naming a document directly
    // instead of asking for the one that matches the device.
    //
    // A source scan rather than a widget test per entry point: the settings
    // screen pulls six blocs from the locator in initState, which is a large
    // fixture for a one-line call, and a per-screen test would not notice a
    // *third* entry point being added with the URL hardcoded. This does.
    final offenders = <String>[];
    for (final entity in Directory('lib').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      if (entity.path.endsWith('url_const.dart')) continue;
      if (entity.path.contains('/generated/')) continue;

      final source = entity.readAsStringSync();
      if (source.contains('privacyPolicyURLEn') ||
          source.contains('privacyPolicyURLDe')) {
        offenders.add(entity.path);
      }
    }

    expect(
      offenders,
      isEmpty,
      reason: 'these should call URLConst.privacyPolicyFor(languageCode) '
          'instead of naming a policy document directly',
    );
  });
}
