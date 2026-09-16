import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/l10n/app_locales.dart';
import 'package:opennutritracker/core/l10n/shipped_locales.dart';

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

  test('every shipped language survives the narrowing', () {
    final generated = shippedLocales.keys.map(Locale.new);
    expect(
      appLocales(generated).map((l) => l.toString()),
      containsAll(shippedLocales.keys),
    );
  });
}
