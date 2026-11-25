import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/l10n/app_locales.dart';
import 'package:opennutritracker/core/l10n/shipped_locales.dart';
import 'package:opennutritracker/generated/l10n.dart';

/// `appLocales` is what keeps a language that is present in `lib/l10n/` but
/// not yet shipped from being resolved for a matching device — including a
/// regional or script variant of a language that *is* shipped.
void main() {
  test('keeps exactly the bare locales of shipped languages', () {
    final generated = [
      const Locale('en'),
      const Locale('de'),
      const Locale('sv'), // present, unshipped
      const Locale('zh'),
      const Locale('zh', 'TW'), // variant of a shipped language: still inert
      const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant'),
      const Locale('pt', 'BR'), // no base language shipped either
    ];

    expect(appLocales(generated), [
      const Locale('en'),
      const Locale('de'),
      const Locale('zh'),
    ]);
  });

  test('French ships (#596), and the app resolves against it', () {
    expect(shippedLocales['fr'], 'Français');
    expect(appLocales(S.supportedLocales), contains(const Locale('fr')));
  });

  test('a present but unshipped ARB stays out of the resolved list', () {
    // gen-l10n compiles every intl_*.arb; Dutch is one Weblate is filling.
    expect(S.supportedLocales, contains(const Locale('nl')));
    expect(shippedLocales, isNot(contains('nl')));
    expect(appLocales(S.supportedLocales), isNot(contains(const Locale('nl'))));
  });

  test('every shipped language survives the narrowing', () {
    final generated = shippedLocales.keys.map(Locale.new);
    expect(
      appLocales(generated).map((l) => l.toString()),
      containsAll(shippedLocales.keys),
    );
  });
}
