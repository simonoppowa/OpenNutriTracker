import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Guards `ios/Runner/Info.plist`'s `CFBundleLocalizations` against drifting
/// from the languages the app actually offers. iOS uses that array to decide
/// which languages to surface in Settings → app language picker; a locale
/// missing there is unpickable even though Flutter ships the strings (six
/// locales were once invisible on iOS for exactly this reason), and a locale
/// listed there without an ARB advertises a language the app cannot render.
///
/// "Offered" is read from the in-app picker's `_supportedLocales` map in
/// `settings_screen.dart`, not from the ARB directory: since translations
/// arrive through Weblate, `lib/l10n/` also holds languages that are still
/// being translated and are deliberately not shipped yet. Those must be able
/// to sit in the repo without being pushed into the iOS picker.
///
/// Stopgap: the full guard across every place that enumerates locales
/// (Info.plist, locales_config.xml, the Settings map, CONTRIBUTING) is
/// https://github.com/simonoppowa/OpenNutriTracker/issues/1182 and replaces
/// this test.
void main() {
  final arbLocales = Directory('lib/l10n')
      .listSync()
      .whereType<File>()
      .map((f) => f.uri.pathSegments.last)
      .where((name) => name.startsWith('intl_') && name.endsWith('.arb'))
      .map(
        (name) => name.substring('intl_'.length, name.length - '.arb'.length),
      )
      .toSet();

  final settingsSource = File(
    'lib/features/settings/settings_screen.dart',
  ).readAsStringSync();
  final settingsMap = RegExp(
    r'static const _supportedLocales = <String, String>\{(.*?)\};',
    dotAll: true,
  ).firstMatch(settingsSource);

  final infoPlist = File('ios/Runner/Info.plist').readAsStringSync();
  final localizationsBlock = RegExp(
    r'<key>CFBundleLocalizations</key>\s*<array>(.*?)</array>',
    dotAll: true,
  ).firstMatch(infoPlist);

  test('the inputs are where this test expects them', () {
    expect(
      arbLocales,
      contains('en'),
      reason: 'the source ARB intl_en.arb must always exist',
    );
    expect(
      settingsMap,
      isNotNull,
      reason: 'settings_screen.dart must declare _supportedLocales',
    );
    expect(
      localizationsBlock,
      isNotNull,
      reason: 'Info.plist must declare CFBundleLocalizations',
    );
  });

  // Locale tags are compared in one spelling: Dart and ARB names use
  // `pt_BR`, Info.plist uses BCP-47 `pt-BR`.
  String canonical(String tag) => tag.replaceAll('-', '_');

  // Commented-out entries (`// 'sv': 'Svenska',`) are not offered.
  final settingsMapBody = (settingsMap?.group(1) ?? '').replaceAll(
    RegExp(r'//[^\n]*'),
    '',
  );
  final offeredLocales = RegExp(
    r"'([a-zA-Z_-]+)':",
  ).allMatches(settingsMapBody).map((m) => canonical(m.group(1)!)).toSet();

  final declaredLocales = RegExp(r'<string>([a-zA-Z_-]+)</string>')
      .allMatches(localizationsBlock?.group(1) ?? '')
      .map((m) => canonical(m.group(1)!))
      .toSet();

  test('the locale lists were actually parsed', () {
    // Both lists are read by regex; an empty result would make the
    // comparisons below pass vacuously, so each must contain English.
    expect(
      offeredLocales,
      contains('en'),
      reason: '_supportedLocales in settings_screen.dart could not be parsed',
    );
    expect(
      declaredLocales,
      contains('en'),
      reason: 'CFBundleLocalizations in Info.plist could not be parsed',
    );
  });

  test('every locale the in-app picker offers is declared for iOS', () {
    final missing = offeredLocales.difference(declaredLocales);
    expect(
      missing,
      isEmpty,
      reason:
          'CFBundleLocalizations is missing locales the Settings picker '
          'offers: ${missing.join(', ')}. Add each as <string>code</string> '
          'to ios/Runner/Info.plist.',
    );
  });

  test('every locale declared for iOS has an ARB and is offered in-app', () {
    final phantom = declaredLocales.difference(arbLocales);
    expect(
      phantom,
      isEmpty,
      reason:
          'CFBundleLocalizations lists locales with no lib/l10n/intl_*.arb: '
          '${phantom.join(', ')}.',
    );
    final unoffered = declaredLocales.difference(offeredLocales);
    expect(
      unoffered,
      isEmpty,
      reason:
          'CFBundleLocalizations lists locales the Settings picker does '
          'not offer: ${unoffered.join(', ')}. Ship the language (add it to '
          '_supportedLocales) or remove it from Info.plist.',
    );
  });
}
