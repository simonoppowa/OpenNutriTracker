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
/// **`NSHealthUpdateUsageDescription` is required even though the app never
/// writes to Health.** Apple's check is static: the `health` plugin links
/// HealthKit's write APIs, and its own error says that "while your app might
/// not use these APIs, a purpose string is still required". So the absence of
/// a write call is not a reason to drop this key — it is the reason the key
/// needs a comment explaining itself.
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

    // The one that was missing. Apple rejects the upload without it, and the
    // rejection arrives only after a full build, sign and package cycle.
    test('the write string is present, despite the app never writing', () {
      expect(
        valueFor('NSHealthUpdateUsageDescription'),
        isNotNull,
        reason: 'altool rejects the build with error 90683 without this key, '
            'even though no write call exists anywhere in lib/',
      );
    });

    // A write string that claimed the app writes data would contradict both
    // the read string beside it and the in-app disclosure (#926), which tell
    // the user nothing is written back.
    test('the write string does not claim the app writes to Health', () {
      final update = valueFor('NSHealthUpdateUsageDescription')!;
      expect(
        update.toLowerCase(),
        contains('does not write'),
        reason: 'the read string and the #926 disclosure both promise nothing '
            'is written back; this must not contradict them',
      );
    });
  });
}
