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

    // The picker DOES write a cache file — `ImagePicker.pickImage` hands the
    // app a temp copy, and `MealPhotoEncoder.encodeAndDiscardSource` deletes
    // it in a `finally`, best effort. So the string may describe the app
    // keeping no copy of its own and deleting that file; it may not claim the
    // photo is never written to the device, which is what this string said
    // before and is not true. The README has always drawn the line here.
    test('describes what happens to the photo without over-claiming', () {
      final camera = valueFor('NSCameraUsageDescription')!.toLowerCase();
      expect(camera, contains('saves no copy of its own'));
      expect(camera, contains("deletes the camera's temporary file"));
      expect(
        camera,
        isNot(contains('never written')),
        reason: 'the picker writes a cache file before it is deleted',
      );
    });
  });

  group('iOS privacy manifest', () {
    // Greedy `(.*)` on purpose. Each collected-type dictionary contains its
    // own `NSPrivacyCollectedDataTypePurposes` array, so a lazy `(.*?)` would
    // stop at the first inner `</array>` and match only the first entry's
    // purposes — 460 characters instead of 5449, with neither AI type inside
    // it. This works because `NSPrivacyCollectedDataTypes` is the last key in
    // the file; if a key is ever added after it, match the outer array some
    // other way rather than making this lazy.
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

    // Tracking is a separate question from linking, and the answer there is
    // still a flat no: nothing is combined with third-party data or handed
    // to a data broker. Linking is decided per type instead — see the test
    // below — because the AI requests carry the user's own provider
    // credential while the diagnostic types carry no identifier at all. A
    // `<true/>` under Tracking would contradict the README's privacy table
    // and the App Store Connect record it has to agree with.
    test('nothing is used for tracking', () {
      final tracking = RegExp(
        '<key>NSPrivacyCollectedDataTypeTracking</key>\\s*<(true|false)/>',
      ).allMatches(manifest).map((m) => m.group(1)).toList();

      expect(tracking, isNotEmpty);
      expect(tracking, everyElement('false'));
    });

    test('linked follows whether a credential travels with the data', () {
      // The diagnostic types carry no identifier at all. The two AI types go
      // out under the user's own provider key, which names the account the
      // content belongs to — so they are linked, whether or not this app can
      // resolve the link itself. Pinned per type rather than as one blanket
      // rule, because a blanket rule is what got the AI path wrong.
      final entries = RegExp(
        '<key>NSPrivacyCollectedDataType</key>\\s*'
        '<string>NSPrivacyCollectedDataType(\\w+)</string>\\s*'
        '<key>NSPrivacyCollectedDataTypeLinked</key>\\s*<(true|false)/>',
      ).allMatches(manifest).map((m) => '${m.group(1)}=${m.group(2)}').toList();

      expect(entries, hasLength(5));
      expect(
        entries,
        containsAll(['PhotosorVideos=true', 'OtherUserContent=true']),
      );
      expect(
        entries,
        containsAll([
          'CrashData=false',
          'PerformanceData=false',
          'OtherDiagnosticData=false',
        ]),
      );
    });
  });

  group('Play release notes', () {
    // Play caps release notes at 500 characters, and like the listing cap it
    // is discovered only when the Console refuses the text. `63.txt` was 628
    // characters and would have been rejected — it never reached the store,
    // which is why nobody noticed. F-Droid reads these same files, so a
    // changelog that cannot be published is not a private problem.
    final changelogs = Directory(
      'fastlane/metadata/android/en-US/changelogs',
    ).listSync().whereType<File>().where((f) => f.path.endsWith('.txt'));

    test('every changelog is within the 500-character cap', () {
      for (final file in changelogs) {
        expect(
          // trimRight() not trim(): a stray leading newline or indent is
          // still charged by Play, so trimming it here would undercount and
          // let an over-cap note through.
          file.readAsStringSync().trimRight().length,
          lessThanOrEqualTo(500),
          reason: '${file.path} exceeds Play\'s 500-character release-note cap',
        );
      }
    });

    test('the 2.2.0 note describes what 2.2.0 actually shipped', () {
      final notes = File(
        'fastlane/metadata/android/en-US/changelogs/63.txt',
      ).readAsStringSync();
      // The published note on both stores names these; an earlier draft
      // described only the TDEE correction and matched neither store.
      expect(notes, contains('Health Connect'));
      expect(notes, contains('AI meal assistance'));
      expect(notes.toLowerCase(), contains('kcal calculations'));
    });
  });

  group('Play listing fields', () {
    // The full description already had a cap test; the title and short
    // description did not, and this branch changes both. Play refuses
    // over-length text at paste time with no earlier warning, and the short
    // description in particular sits at exactly its cap — a stray character
    // would be discovered in the Console rather than here.
    String field(String name) => File(
      'fastlane/metadata/android/en-US/$name',
    ).readAsStringSync().trimRight();

    test('title is within the 30-character cap', () {
      expect(field('title.txt').length, lessThanOrEqualTo(30));
    });

    test('short description is within the 80-character cap', () {
      expect(field('short_description.txt').length, lessThanOrEqualTo(80));
    });

    test('the title avoids the phrase Play forbids there', () {
      // Play names "No Ads" as prohibited in a title specifically; Apple
      // permits it in an app name, which is why this is asserted per store.
      expect(field('title.txt').toLowerCase(), isNot(contains('no ads')));
    });
  });

  group('App Store listing', () {
    // Apple's caps are enforced only by App Store Connect refusing the text,
    // and the fields live in the console rather than in this repo, so they
    // drifted invisibly: the live description was still the pre-2.0 copy
    // while What's New described 2.2.0, and the keyword field used 64 of its
    // 100 characters with `open source` split into two weak tokens (#1063).
    //
    // Apple combines the name, subtitle and keyword field when it indexes, so
    // a word repeated across them is a wasted slot rather than a stronger
    // signal — hence the no-duplicates assertion.
    String field(String name) =>
        File('fastlane/metadata/ios/en-US/$name').readAsStringSync().trim();

    const caps = {
      'name.txt': 30,
      'subtitle.txt': 30,
      'keywords.txt': 100,
      'promotional_text.txt': 170,
      'description.txt': 4000,
      // Both URL fields are pinned so the set stays complete. The marketing
      // URL renders as the product page's "Developer Website" row and was
      // simply absent — the GitHub Pages site was removed in #786, so the
      // repository is the project's public home and the honest target.
      'support_url.txt': 255,
      'marketing_url.txt': 255,
    };

    caps.forEach((file, cap) {
      test('$file is within its $cap-character cap', () {
        expect(field(file).length, lessThanOrEqualTo(cap));
      });
    });

    test('the keyword field wastes nothing on spaces after commas', () {
      // Apple counts every character; ", " costs one more than ",".
      expect(field('keywords.txt'), isNot(contains(', ')));
    });

    test('keywords do not repeat words already in the name or subtitle', () {
      final indexed = '${field('name.txt')} ${field('subtitle.txt')}'
          .toLowerCase()
          .split(RegExp(r'[^a-z]+'))
          .where((w) => w.length > 2)
          .toSet();
      final keywords = field('keywords.txt')
          .toLowerCase()
          .split(',')
          .expand((k) => k.trim().split(' '))
          .where((w) => w.length > 2);
      for (final word in keywords) {
        expect(
          indexed,
          isNot(contains(word)),
          reason: '"$word" is already in the name or subtitle; Apple combines '
              'those fields when indexing, so repeating it wastes a slot',
        );
      }
    });

    test('both URL fields point somewhere real', () {
      for (final f in ['support_url.txt', 'marketing_url.txt']) {
        expect(field(f), startsWith('https://'), reason: f);
      }
    });

    test('carries the not-a-medical-device wording by choice', () {
      // Apple imposes no listing mandate, unlike Play's Health Content and
      // Services policy — this is kept to pre-empt a guideline 1.4.1 call.
      expect(
        field('description.txt'),
        contains(
          'not a medical device and does not diagnose, treat, cure, or '
          'prevent any medical condition',
        ),
      );
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
