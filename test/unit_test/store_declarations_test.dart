import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Pins the platform-facing declarations that 2.2.0 outgrew (#990).
///
/// These files are read by Apple's reviewer and Google's policy check, not by
/// the app, so nothing else in CI looks at them. Every one of them drifted
/// silently while AI meal assistance and workout import were being built: the
/// camera purpose string still described an app with no meal photo, the
/// privacy manifest declared only Sentry's diagnostics, and the Play listing
/// described neither feature while over-claiming encryption.
///
/// The listing is also under a hard 4000-character cap that nothing warns
/// about until the Play Console rejects the text, which is why the length is
/// asserted here rather than discovered during a submission.
void main() {
  final infoPlist = File('ios/Runner/Info.plist').readAsStringSync();
  final manifest = File('ios/Runner/PrivacyInfo.xcprivacy').readAsStringSync();
  final listing = File(
    'fastlane/metadata/android/en-US/full_description.txt',
  ).readAsStringSync();

  String? valueFor(String key) => RegExp(
    '<key>$key</key>\\s*<string>(.*?)</string>',
    dotAll: true,
  ).firstMatch(infoPlist)?.group(1);

  group('iOS camera purpose string', () {
    // Apple requires the string to describe the actual use, and reading a
    // meal photograph is the use a reviewer will exercise — it is also the
    // only camera use where the picture leaves the device.
    test('names reading a meal photo', () {
      final camera = valueFor('NSCameraUsageDescription')!;
      expect(camera.toLowerCase(), contains('ai meal assistance'));
      expect(camera.toLowerCase(), contains('photograph a meal'));
    });

    // The AI clause was added to a string that already had two purposes.
    // Neither may be dropped on the way past.
    test('keeps the barcode and custom-meal purposes', () {
      final camera = valueFor('NSCameraUsageDescription')!.toLowerCase();
      expect(camera, contains('barcode'));
      expect(camera, contains('custom meal'));
    });

    // The photo path promises this in Settings and in the README, and the
    // purpose string is the one place Apple reads it.
    test('does not claim the photo is kept', () {
      final camera = valueFor('NSCameraUsageDescription')!.toLowerCase();
      expect(camera, contains('never written to your device'));
    });
  });

  group('iOS privacy manifest', () {
    String collectedTypes() => RegExp(
      '<key>NSPrivacyCollectedDataTypes</key>\\s*<array>(.*)</array>',
      dotAll: true,
    ).firstMatch(manifest)!.group(1)!;

    // Lowercase "or" is Apple's own spelling of this constant. A well-meaning
    // correction to `PhotosOrVideos` would be silently ignored by Apple.
    test('declares the meal photo', () {
      expect(
        collectedTypes(),
        contains('<string>NSPrivacyCollectedDataTypePhotosorVideos</string>'),
      );
    });

    test('declares the typed meal line', () {
      expect(
        collectedTypes(),
        contains('<string>NSPrivacyCollectedDataTypeOtherUserContent</string>'),
      );
    });

    // The app generates no user or device identifier and sends none, so
    // nothing it declares may be linked to an identity or used for tracking.
    // A `<true/>` under either key would contradict the README's privacy
    // table and the App Store Connect record it has to agree with.
    test('nothing is linked to the user or used for tracking', () {
      final linked = RegExp(
        '<key>NSPrivacyCollectedDataTypeLinked</key>\\s*<(true|false)/>',
      ).allMatches(manifest).map((m) => m.group(1)).toList();
      final tracking = RegExp(
        '<key>NSPrivacyCollectedDataTypeTracking</key>\\s*<(true|false)/>',
      ).allMatches(manifest).map((m) => m.group(1)).toList();

      expect(linked, isNotEmpty);
      expect(linked, everyElement('false'));
      expect(tracking, isNotEmpty);
      expect(tracking, everyElement('false'));
    });
  });

  group('Play listing', () {
    // Play rejects a longer description outright. Nothing in the repo or in
    // CI checks it, and `upload_to_play_store` runs with
    // `skip_upload_metadata: true`, so the rejection would arrive during a
    // manual Console edit rather than from the pipeline.
    test('is within the 4000-character cap', () {
      expect(
        listing.length,
        lessThanOrEqualTo(4000),
        reason: 'Play truncates or refuses a longer full description',
      );
    });

    test('describes the two features 2.2.0 added', () {
      expect(listing.toLowerCase(), contains('ai meal assistance'));
      expect(listing.toLowerCase(), contains('workout import'));
    });

    // Google's Health Content and Services policy requires this sentence in
    // the app description, in these words, for a health-and-fitness app that
    // is not a declared medical device.
    test('carries the disclaimer Google specifies, verbatim', () {
      expect(
        listing,
        contains(
          'not a medical device and does not diagnose, treat, cure, '
          'or prevent any medical condition',
        ),
      );
    });

    test('reminds the reader to consult a professional', () {
      expect(listing.toLowerCase(), contains('healthcare professional'));
    });

    // Photos attached to a meal or recipe are stored as ordinary image files,
    // so the blanket claim was false in the direction that matters.
    test('does not claim that all data is encrypted', () {
      expect(listing, isNot(contains('All data is AES-encrypted')));
      expect(listing, contains('AES-256 encrypted databases'));
    });
  });
}
