// PROTOTYPE for https://github.com/simonoppowa/OpenNutriTracker/issues/1182
//
// Every place that enumerates the app's languages is checked against the
// one list in lib/core/l10n/shipped_locales.dart:
//
//   lib/l10n/intl_<code>.arb                          a shipped language has strings
//   ios/Runner/Info.plist  CFBundleLocalizations      iOS per-app picker / App Store
//   android/app/src/main/res/xml/locales_config.xml  Android 13+ per-app picker
//   lib/features/settings/settings_screen.dart        reads shippedLocales, owns no list
//   CONTRIBUTING.md                                   the locale table
//
// Run:   dart run tool/check_locales.dart          report, exit 1 on drift
//        dart run tool/check_locales.dart --fix    rewrite Info.plist and
//                                                  locales_config.xml, then report
import 'dart:convert';
import 'dart:io';

import 'package:opennutritracker/core/l10n/shipped_locales.dart';

const _plistPath = 'ios/Runner/Info.plist';
const _localesConfigPath = 'android/app/src/main/res/xml/locales_config.xml';
const _settingsPath = 'lib/features/settings/settings_screen.dart';
const _contributingPath = 'CONTRIBUTING.md';
const _templatePath = 'lib/l10n/intl_en.arb';

void main(List<String> args) {
  final fix = args.contains('--fix');
  final result = checkLocales(fix: fix);
  stdout.write(result.report);
  exit(result.ok ? 0 : 1);
}

class LocaleCheck {
  LocaleCheck(this.ok, this.report);
  final bool ok;
  final String report;
}

LocaleCheck checkLocales({bool fix = false}) {
  final shipped = shippedLocales.keys.toSet();
  final problems = <String>[];
  final fixed = <String>[];
  final buffer = StringBuffer();

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

  // --- Info.plist --------------------------------------------------------
  final plist = File(_plistPath).readAsStringSync();
  final plistBlock = RegExp(
    r'(<key>CFBundleLocalizations</key>\s*<array>)(.*?)(</array>)',
    dotAll: true,
  ).firstMatch(plist);
  if (plistBlock == null) {
    problems.add('$_plistPath has no CFBundleLocalizations array');
  } else {
    final declared = RegExp(r'<string>([^<]+)</string>')
        .allMatches(plistBlock.group(2)!)
        .map((m) => _canonical(m.group(1)!))
        .toSet();
    if (!_sameSet(declared, shipped)) {
      if (fix) {
        final entries = _plistOrder(
          shipped,
        ).map((code) => '\t\t<string>${_bcp47(code)}</string>').join('\n');
        File(_plistPath).writeAsStringSync(
          plist.replaceRange(
            plistBlock.start,
            plistBlock.end,
            '${plistBlock.group(1)}\n$entries\n\t${plistBlock.group(3)}',
          ),
        );
        fixed.add(_plistPath);
      } else {
        problems.add(
          '$_plistPath CFBundleLocalizations ${_diff(declared, shipped)}',
        );
      }
    }
  }

  // --- locales_config.xml -----------------------------------------------
  final xml = File(_localesConfigPath).readAsStringSync();
  final declaredAndroid = RegExp(
    r'android:name="([^"]+)"',
  ).allMatches(xml).map((m) => _canonical(m.group(1)!)).toSet();
  if (!_sameSet(declaredAndroid, shipped)) {
    if (fix) {
      final entries = (shipped.toList()..sort())
          .map((code) => '    <locale android:name="${_bcp47(code)}"/>')
          .join('\n');
      File(_localesConfigPath).writeAsStringSync(
        xml.replaceAllMapped(
          RegExp(
            r'(<locale-config[^>]*>)(.*?)(</locale-config>)',
            dotAll: true,
          ),
          (m) => '${m.group(1)}\n$entries\n${m.group(3)}',
        ),
      );
      fixed.add(_localesConfigPath);
    } else {
      problems.add('$_localesConfigPath ${_diff(declaredAndroid, shipped)}');
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

  // --- CONTRIBUTING table ------------------------------------------------
  final contributing = File(_contributingPath).readAsStringSync();
  final documented = RegExp(r'`intl_([a-zA-Z_]+)\.arb`')
      .allMatches(contributing)
      .map((m) => m.group(1)!)
      .where((code) => code != '*')
      .toSet();
  if (!_sameSet(documented, shipped)) {
    problems.add(
      '$_contributingPath locale table ${_diff(documented, shipped)} '
      '(hand-edit; see the recipe in that file)',
    );
  }

  // --- report ------------------------------------------------------------
  buffer.writeln('Shipped (${shipped.length}):');
  for (final code in _plistOrder(shipped)) {
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
        'Run `dart run tool/check_locales.dart --fix` for the '
        'platform files; the rest is a hand edit.',
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

/// `pt_BR` and `pt-BR` are the same tag; compare in ARB spelling.
String _canonical(String tag) => tag.replaceAll('-', '_');

/// Platform files use BCP-47 (`pt-BR`).
String _bcp47(String code) => code.replaceAll('_', '-');

/// English first, then alphabetical — the order Info.plist has always used.
List<String> _plistOrder(Set<String> codes) => [
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
