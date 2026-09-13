// Every place that enumerates the app's languages is checked against the
// one list in lib/core/l10n/shipped_locales.dart:
//
//   lib/l10n/intl_<code>.arb                          a shipped language has strings
//   ios/Runner/Info.plist  CFBundleLocalizations      iOS per-app picker / App Store
//   android/app/src/main/res/xml/locales_config.xml  Android 13+ per-app picker
//   lib/features/settings/settings_screen.dart        reads shippedLocales, owns no list
//
// An ARB that is in lib/l10n/ but not in shipped_locales.dart is a language
// Weblate is still filling: compiled, never resolved or offered. Shipping it
// is one line in shipped_locales.dart followed by `--fix`.
//
// Run from the repository root:
//        dart run tool/check_locales.dart          report, exit 1 on drift
//        dart run tool/check_locales.dart --fix    rewrite Info.plist and
//                                                  locales_config.xml, then check
import 'dart:convert';
import 'dart:io';

import 'package:opennutritracker/core/l10n/shipped_locales.dart';

const _plistPath = 'ios/Runner/Info.plist';
const _localesConfigPath = 'android/app/src/main/res/xml/locales_config.xml';
const _settingsPath = 'lib/features/settings/settings_screen.dart';
const _templatePath = 'lib/l10n/intl_en.arb';

/// Bare language codes only: resolution matches on `Locale.languageCode`,
/// and Weblate is limited to base languages (#1181).
final _bareCode = RegExp(r'^[a-z]{2,3}$');

void main(List<String> args) {
  if (!File('pubspec.yaml').existsSync() || !File(_templatePath).existsSync()) {
    stderr.writeln('Run from the repository root.');
    exit(2);
  }
  final result = checkLocales(fix: args.contains('--fix'));
  stdout.write(result.report);
  exit(result.ok ? 0 : 1);
}

class LocaleCheck {
  LocaleCheck(this.ok, this.report);
  final bool ok;
  final String report;
}

/// Compares every locale list with [shippedLocales]. With [fix], rewrites
/// the two platform files first and reports the state after the rewrite —
/// "OK" is always the result of a comparison, never an assumption.
LocaleCheck checkLocales({bool fix = false}) {
  final shipped = shippedLocales.keys.toSet();
  final problems = <String>[];
  final buffer = StringBuffer();

  // --- the list itself ---------------------------------------------------
  for (final code in shipped.where((c) => !_bareCode.hasMatch(c))) {
    problems.add(
      '"$code" in shipped_locales.dart is not a bare language code; '
      'region and script variants are not supported (see the file header)',
    );
  }
  if (!shipped.contains('en')) {
    problems.add(
      'en must stay in shipped_locales.dart: it is the template and the '
      'resolution fallback',
    );
  }

  // --- ARBs: what exists, and how complete ------------------------------
  final templateKeys = _arbKeys(File(_templatePath)).length;
  final arbLocales = <String, int>{};
  for (final file in Directory('lib/l10n').listSync().whereType<File>()) {
    final name = file.uri.pathSegments.last;
    if (!name.startsWith('intl_') || !name.endsWith('.arb')) continue;
    final code = name.substring('intl_'.length, name.length - '.arb'.length);
    arbLocales[code] = _arbKeys(file).length;
  }
  for (final code in shipped.difference(arbLocales.keys.toSet())) {
    problems.add('$code is shipped but lib/l10n/intl_$code.arb does not exist');
  }

  // A broken list is never written into the platform files.
  final rewrite = fix && problems.isEmpty;
  final fixed = <String>[];

  // --- Info.plist --------------------------------------------------------
  final plist = File(_plistPath).readAsStringSync();
  final plistBlock = RegExp(
    r'(<key>CFBundleLocalizations</key>\s*<array>)(.*?)(</array>)',
    dotAll: true,
  ).firstMatch(plist);
  if (plistBlock == null) {
    problems.add('$_plistPath has no CFBundleLocalizations array');
  } else {
    var declared = RegExp(
      r'<string>([^<]+)</string>',
    ).allMatches(plistBlock.group(2)!).map((m) => m.group(1)!).toSet();
    if (rewrite && !_sameSet(declared, shipped)) {
      final entries = _englishFirst(
        shipped,
      ).map((code) => '\t\t<string>$code</string>').join('\n');
      File(_plistPath).writeAsStringSync(
        plist.replaceRange(
          plistBlock.start,
          plistBlock.end,
          '${plistBlock.group(1)}\n$entries\n\t${plistBlock.group(3)}',
        ),
      );
      fixed.add(_plistPath);
      declared = shipped;
    }
    if (!_sameSet(declared, shipped)) {
      problems.add(
        '$_plistPath CFBundleLocalizations ${_diff(declared, shipped)}',
      );
    }
  }

  // --- locales_config.xml -----------------------------------------------
  final xml = File(_localesConfigPath).readAsStringSync();
  final xmlBody = RegExp(
    r'(<locale-config[^>]*>)(.*?)(</locale-config>)',
    dotAll: true,
  ).firstMatch(xml);
  if (xmlBody == null) {
    problems.add(
      '$_localesConfigPath has no <locale-config> … </locale-config> element',
    );
  } else {
    // Only elements count; a locale named in a comment is not declared.
    final uncommented = xmlBody
        .group(2)!
        .replaceAll(RegExp(r'<!--.*?-->', dotAll: true), '');
    var declared = RegExp(
      r'<locale\s+android:name="([^"]+)"',
    ).allMatches(uncommented).map((m) => m.group(1)!).toSet();
    if (rewrite && !_sameSet(declared, shipped)) {
      final entries = (shipped.toList()..sort())
          .map((code) => '    <locale android:name="$code"/>')
          .join('\n');
      File(_localesConfigPath).writeAsStringSync(
        xml.replaceRange(
          xmlBody.start,
          xmlBody.end,
          '${xmlBody.group(1)}\n$entries\n${xmlBody.group(3)}',
        ),
      );
      fixed.add(_localesConfigPath);
      declared = shipped;
    }
    if (!_sameSet(declared, shipped)) {
      problems.add('$_localesConfigPath ${_diff(declared, shipped)}');
    }
  }

  // --- Settings screen: must not own a list of its own -------------------
  final settings = File(_settingsPath).readAsStringSync();
  if (settings.contains('_supportedLocales = <String, String>{')) {
    problems.add(
      '$_settingsPath still declares its own _supportedLocales map; '
      'it should read shippedLocales',
    );
  } else if (!settings.contains('shippedLocales')) {
    problems.add('$_settingsPath does not use shippedLocales');
  }

  // --- report ------------------------------------------------------------
  buffer.writeln('Shipped (${shipped.length}):');
  for (final code in _englishFirst(shipped)) {
    final keys = arbLocales[code];
    final pct = keys == null ? 'no ARB' : _pct(keys, templateKeys);
    buffer.writeln('  $code  ${shippedLocales[code]}  $pct');
  }
  final unshipped = arbLocales.keys.toSet().difference(shipped).toList()
    ..sort();
  buffer.writeln(
    'Present, not shipped (${unshipped.length}) — compiled, '
    'never resolved or offered until listed in shipped_locales.dart:',
  );
  for (final code in unshipped) {
    buffer.writeln('  $code  ${_pct(arbLocales[code]!, templateKeys)}');
  }
  if (fixed.isNotEmpty) {
    buffer.writeln('Rewrote: ${fixed.join(', ')}');
  }
  if (problems.isEmpty) {
    buffer.writeln('OK: every locale list matches shipped_locales.dart.');
  } else {
    buffer.writeln('DRIFT:');
    for (final p in problems) {
      buffer.writeln('  - $p');
    }
    if (!fix) {
      buffer.writeln(
        'Run `dart run tool/check_locales.dart --fix` to rewrite the '
        'platform files.',
      );
    }
  }
  return LocaleCheck(problems.isEmpty, buffer.toString());
}

Iterable<String> _arbKeys(File file) =>
    (jsonDecode(file.readAsStringSync()) as Map<String, dynamic>).keys.where(
      (k) => !k.startsWith('@'),
    );

String _pct(int keys, int total) =>
    '${(100 * keys / total).toStringAsFixed(0)}% ($keys/$total)';

/// English first, then alphabetical.
List<String> _englishFirst(Set<String> codes) => [
  if (codes.contains('en')) 'en',
  ...(codes.where((c) => c != 'en').toList()..sort()),
];

bool _sameSet(Set<String> a, Set<String> b) =>
    a.length == b.length && a.containsAll(b);

String _diff(Set<String> actual, Set<String> expected) {
  final missing = expected.difference(actual).toList()..sort();
  final extra = actual.difference(expected).toList()..sort();
  return [
    if (missing.isNotEmpty) 'is missing ${missing.join(', ')}',
    if (extra.isNotEmpty) 'lists unshipped ${extra.join(', ')}',
  ].join('; ');
}
