import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/l10n/shipped_locales.dart';

import '../../tool/check_locales.dart';

/// Runs the checker against a fixture repository: the shipped languages with
/// minimal ARBs, both platform lists, and a Settings screen that reads the
/// map. Each case breaks one list and expects the check to say so and
/// `--fix` to repair it.
void main() {
  late Directory root;

  String plist(Iterable<String> entries) =>
      '<plist><dict>\n\t<key>CFBundleLocalizations</key>\n\t<array>\n'
      '${entries.map((e) => '\t\t$e').join('\n')}\n\t</array>\n</dict></plist>\n';

  String localesConfig(Iterable<String> entries) =>
      '<?xml version="1.0" encoding="utf-8"?>\n<!-- kept comment -->\n'
      '<locale-config xmlns:android="http://schemas.android.com/apk/res/android">\n'
      '${entries.map((e) => '    $e').join('\n')}\n</locale-config>\n';

  void write(String relative, String content) => File('${root.path}/$relative')
    ..createSync(recursive: true)
    ..writeAsStringSync(content);

  String read(String relative) =>
      File('${root.path}/$relative').readAsStringSync();

  setUp(() {
    root = Directory.systemTemp.createTempSync('check_locales_');
    write('pubspec.yaml', 'name: fixture\n');
    for (final code in shippedLocales.keys) {
      write('lib/l10n/intl_$code.arb', '{\n  "appTitle": "x"\n}\n');
    }
    write(
      'lib/features/settings/settings_screen.dart',
      'final names = shippedLocales;\n',
    );
    write(
      'ios/Runner/Info.plist',
      plist(shippedLocales.keys.map((c) => '<string>$c</string>')),
    );
    write(
      'android/app/src/main/res/xml/locales_config.xml',
      localesConfig(
        shippedLocales.keys.map((c) => '<locale android:name="$c"/>'),
      ),
    );
  });

  tearDown(() => root.deleteSync(recursive: true));

  test('a consistent fixture passes', () {
    final result = checkLocales(root: root.path);
    expect(result.ok, isTrue, reason: result.report);
  });

  test('a commented-out iOS locale is drift, and --fix restores it', () {
    write(
      'ios/Runner/Info.plist',
      plist(
        shippedLocales.keys.map(
          (c) => c == 'de'
              ? '<!-- <string>de</string> -->'
              : '<string>$c</string>',
        ),
      ),
    );

    final check = checkLocales(root: root.path);
    expect(check.ok, isFalse);
    expect(
      check.report,
      contains('Info.plist CFBundleLocalizations is missing de'),
    );

    final fix = checkLocales(root: root.path, fix: true);
    expect(fix.ok, isTrue, reason: fix.report);
    expect(fix.report, contains('Rewrote: ios/Runner/Info.plist'));
    expect(
      RegExp(r'<string>de</string>').allMatches(read('ios/Runner/Info.plist')),
      hasLength(1),
    );
    expect(checkLocales(root: root.path).ok, isTrue);
  });

  test('a commented-out Android locale is drift, and --fix restores it', () {
    write(
      'android/app/src/main/res/xml/locales_config.xml',
      localesConfig(
        shippedLocales.keys.map(
          (c) => c == 'de'
              ? '<!-- <locale android:name="de"/> -->'
              : '<locale android:name="$c"/>',
        ),
      ),
    );

    final check = checkLocales(root: root.path);
    expect(check.ok, isFalse);
    expect(check.report, contains('locales_config.xml is missing de'));

    final fix = checkLocales(root: root.path, fix: true);
    expect(fix.ok, isTrue, reason: fix.report);
    final xml = read('android/app/src/main/res/xml/locales_config.xml');
    expect(xml, contains('<!-- kept comment -->'));
    expect(
      RegExp(r'<locale android:name="de"/>').allMatches(xml),
      hasLength(1),
    );
  });

  test('an unshipped locale in a platform list is drift', () {
    write(
      'ios/Runner/Info.plist',
      plist([
        ...shippedLocales.keys.map((c) => '<string>$c</string>'),
        '<string>sv</string>',
      ]),
    );
    final check = checkLocales(root: root.path);
    expect(check.ok, isFalse);
    expect(check.report, contains('lists unshipped sv'));
  });

  test(
    'a shipped code without an ARB is reported and nothing is rewritten',
    () {
      File('${root.path}/lib/l10n/intl_de.arb').deleteSync();
      write(
        'ios/Runner/Info.plist',
        plist(
          shippedLocales.keys
              .where((c) => c != 'de')
              .map((c) => '<string>$c</string>'),
        ),
      );
      final before = read('ios/Runner/Info.plist');
      final fix = checkLocales(root: root.path, fix: true);
      expect(fix.ok, isFalse);
      expect(
        fix.report,
        contains('de is shipped but lib/l10n/intl_de.arb does not exist'),
      );
      expect(fix.report, isNot(contains('Rewrote')));
      expect(read('ios/Runner/Info.plist'), before);
    },
  );
}
