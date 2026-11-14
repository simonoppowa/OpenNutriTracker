import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Pins the HealthKit purpose strings in `ios/Runner/Info.plist` (#956).
///
/// Nothing in CI catches a missing purpose string. `ios-build` runs with
/// `--no-codesign` and never uploads, `ios-package` only signs, and the first
/// thing that inspects the bundle is Apple's `altool` at the moment it
/// rejects the upload — which is how 2.1.0's first release attempt failed,
/// after every other job had passed.
///
/// `NSHealthUpdateUsageDescription` covers the opt-in nutrition export. It
/// was required even before the app wrote anything, because the `health`
/// plugin links HealthKit's write APIs.
void main() {
  final infoPlist = File('ios/Runner/Info.plist').readAsStringSync();

  String? valueFor(String key) => RegExp(
        '<key>$key</key>\\s*<string>(.*?)</string>',
        dotAll: true,
      ).firstMatch(infoPlist)?.group(1);

  group('HealthKit purpose strings', () {
    test('the read string is present and says what is read', () {
      final share = valueFor('NSHealthShareUsageDescription');
      expect(share, isNotNull);
      expect(share, contains('workouts'));
    });

    test('the write string is present and says what is written', () {
      final update = valueFor('NSHealthUpdateUsageDescription');
      expect(
        update,
        isNotNull,
        reason: 'altool rejects the build with error 90683 without this key',
      );
      expect(update!.toLowerCase(), contains('meals and water'));
    });

    // The export is opt-in, and the in-app disclosure says so; neither string
    // may read as if the app wrote to Health on its own.
    test('the strings present writing as opt-in', () {
      expect(valueFor('NSHealthUpdateUsageDescription'), contains('turn on'));
      expect(
        valueFor('NSHealthShareUsageDescription'),
        isNot(contains('written')),
      );
    });
  });
}
