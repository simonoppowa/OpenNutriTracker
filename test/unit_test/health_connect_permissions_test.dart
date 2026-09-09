import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Pins the Health Connect permissions in `android/app/src/main/AndroidManifest.xml`.
///
/// Play's Health Connect permissions policy rejected the 2.3.0 submission for
/// "excessive data access for declared functionality": `READ_BODY_FAT`,
/// `READ_DISTANCE` and `READ_STEPS` were held without a feature that needed
/// them. Enforced 8 Sept 2026, with the previous version left live.
///
/// Nothing else in CI would catch them coming back. The manifest is not
/// linted for this, the `android-deploy` job tolerates a failed Play upload
/// by design (#942), and the first thing that inspects the declaration is a
/// human reviewer at Google — days after the release went out. A regression
/// here costs another rejection and another version code.
///
/// Two ways they could return without anyone deciding to bring them back: a
/// Flutter plugin that merges its own `uses-permission` into the manifest,
/// and a well-meant revert of the workout reader that restores the plugin's
/// workout path along with the permissions it needs. Both show up here.
///
/// Three checks, deliberately overlapping, because each sees something the
/// others cannot:
///
///  1. the app manifest — what this repo declares on purpose;
///  2. every plugin's own manifest, resolved from
///     `.flutter-plugins-dependencies` — what Gradle is about to merge in,
///     checkable without building, so it has teeth in `linux-checks`;
///  3. the merged manifest Gradle actually produced — the ground truth Play
///     inspects, which catches anything the merger adds from a source (2)
///     cannot enumerate, such as a transitive AAR that is nobody's Flutter
///     plugin. It needs a build, so it is skipped, loudly, when there is not
///     one.
///
/// (2) and (3) are not redundant: one runs everywhere and reasons about
/// intent, the other runs after a build and reasons about the artifact.
void main() {
  final manifest = File(
    'android/app/src/main/AndroidManifest.xml',
  ).readAsStringSync();

  /// Matches a Health Connect `uses-permission` however it is spelled.
  ///
  /// Attribute order and quote style are free in XML, and both occur in the
  /// wild: `<uses-permission android:maxSdkVersion="32" android:name="…"/>`
  /// is merged by Gradle exactly like the canonical spelling. A pattern that
  /// insisted on `android:name` coming first would stay green while the
  /// release acquired the permission.
  ///
  /// Not handled, and not worth a parser: a manifest binding the Android
  /// namespace to an alias other than `android:`. No plugin in the wild does
  /// that, and the only robust fix is structural XML parsing, which would
  /// mean promoting `xml` from a transitive dependency to a declared one.
  final healthPermission = RegExp(
    r'''<uses-permission\b[^>]*?\bandroid:name\s*=\s*'''
    r'''["']android\.permission\.health\.([A-Z_]+)["']''',
  );

  /// Every `android.permission.health.*` the app manifest declares.
  final declared =
      healthPermission.allMatches(manifest).map((m) => m.group(1)!).toSet();

  /// The same, per plugin, from each plugin's own manifest.
  ///
  /// Gradle merges plugin manifests into the application manifest, so a
  /// plugin declaring `android.permission.health.*` puts it in the APK and in
  /// front of Play's reviewer without it ever appearing in
  /// `android/app/src/main/AndroidManifest.xml`. Reading only the app
  /// manifest cannot see that — so the first of the two regressions named
  /// above was claimed but not actually covered until this was added.
  ///
  /// Paths come from `.flutter-plugins-dependencies`, which `flutter pub get`
  /// writes and `.gitignore` excludes. If it is absent the plugin half checks
  /// nothing, so its absence fails a test of its own rather than passing
  /// quietly — a silent pass is the failure mode this file exists to prevent.
  ///
  /// Every source set is read, not just `src/main`: Gradle merges a variant
  /// overlay such as `android/src/release/AndroidManifest.xml` into the
  /// production manifest, so a permission declared only there would ship
  /// while a `src/main`-only check stayed green. No plugin here has a
  /// non-`main` source set today, which is when a guard is worth adding
  /// rather than after it is needed.
  final pluginList = File('.flutter-plugins-dependencies');
  final pluginListPresent = pluginList.existsSync();
  final pluginPermissions = <String, Set<String>>{};
  var pluginManifestsRead = 0;
  if (pluginListPresent) {
    final plugins = ((jsonDecode(pluginList.readAsStringSync())
            as Map<String, dynamic>)['plugins']
        as Map<String, dynamic>)['android'] as List<dynamic>;
    for (final plugin in plugins.cast<Map<String, dynamic>>()) {
      final root = (plugin['path'] as String).replaceAll(RegExp(r'/+$'), '');
      // Only the source sets Gradle merges into a release build. `debug`,
      // `profile` and `androidTest` never reach the uploaded artifact, so a
      // permission a plugin declares there is not a Play problem — failing on
      // it would be a false alarm, and the app's own debug/profile manifests
      // are excluded for the same reason.
      for (final sourceSet in const ['main', 'release']) {
        final pluginManifest =
            File('$root/android/src/$sourceSet/AndroidManifest.xml');
        if (!pluginManifest.existsSync()) continue;
        pluginManifestsRead++;
        final found = healthPermission
            .allMatches(pluginManifest.readAsStringSync())
            .map((m) => m.group(1)!)
            .toSet();
        if (found.isNotEmpty) {
          pluginPermissions
              .putIfAbsent(plugin['name'] as String, () => <String>{})
              .addAll(found);
        }
      }
    }
  }

  group('Health Connect permissions', () {
    test('exercise and total calories are declared', () {
      // The workout import needs the session, and the calories that give an
      // imported workout its kcal. Without these the feature cannot work.
      expect(declared, contains('READ_EXERCISE'));
      expect(declared, contains('READ_TOTAL_CALORIES_BURNED'));
    });

    test('the three permissions Play refused are not declared', () {
      expect(
        declared.intersection({
          'READ_BODY_FAT',
          'READ_DISTANCE',
          'READ_STEPS',
        }),
        isEmpty,
        reason:
            'Play enforced against these on 8 Sept 2026 as excessive for the '
            'features this app offers. Reinstating one needs a feature that '
            'genuinely requires it AND a Health Connect declaration that '
            'covers it — not a manifest edit.',
      );
    });

    test('no health permission is declared beyond those two', () {
      // Catches a new read added here without the declaration form being
      // updated to match. A plugin merging one in never reaches this set —
      // that is the separate plugin test below.
      expect(
        declared,
        {'READ_EXERCISE', 'READ_TOTAL_CALORIES_BURNED'},
        reason:
            'Every declared Health Connect permission has to be justified by '
            'a feature in the Play Console declaration form. Adding one here '
            'without updating that form is what gets an update rejected.',
      );
    });

    test('plugin manifests were actually inspected', () {
      // Not just "the list exists": if the paths in it resolved to nothing,
      // pluginPermissions would be empty and the plugin test below would pass
      // having read no files at all. Assert the work happened.
      expect(
        pluginListPresent,
        isTrue,
        reason:
            '.flutter-plugins-dependencies is missing. Run `flutter pub get` '
            'first; CI already does.',
      );
      expect(
        pluginManifestsRead,
        greaterThan(0),
        reason:
            'The plugin list resolved to no readable manifests, so the plugin '
            'half of this guard passed without checking anything.',
      );
    });

    test('no plugin merges a health permission into the manifest', () {
      expect(
        pluginPermissions,
        isEmpty,
        reason:
            'Gradle merges plugin manifests into the application manifest, so '
            'a permission declared there reaches the APK and Play without '
            'appearing in android/app/src/main/AndroidManifest.xml. If a '
            'plugin genuinely needs one, the Play Console declaration has to '
            'cover it first — the health plugin wanting READ_DISTANCE and '
            'READ_STEPS for its own workout path is precisely why this app '
            'reads ExerciseSessionRecord itself.',
      );
    });

    test('nothing is ever written back', () {
      expect(
        declared.where((permission) => permission.startsWith('WRITE_')),
        isEmpty,
      );
    });
  });

  // Check (3): the artifact rather than the intent. The plugin check above
  // reasons about what Gradle is going to merge, from the sources it can
  // enumerate; this reads what Gradle actually emitted, so a permission
  // arriving from somewhere `.flutter-plugins-dependencies` does not list —
  // a transitive AAR, a build-type overlay — is still caught. It is also the
  // check that was run by hand while #1122 was being written, which is how
  // that release was known to be clean.
  group('the merged manifest Gradle produced', () {
    // AGP has used both spellings for this directory; take whichever exists.
    final mergedManifests = [
      'build/app/intermediates/merged_manifest',
      'build/app/intermediates/merged_manifests',
    ]
        .map(Directory.new)
        .where((directory) => directory.existsSync())
        .expand((directory) => directory.listSync(recursive: true))
        .whereType<File>()
        .where((file) => file.path.endsWith('AndroidManifest.xml'))
        .toList();

    test('declares those two health permissions and no others', () {
      // Not a failure: the Android build is not a precondition for the unit
      // suite, and `linux-checks` never runs one. Silence would be, though —
      // a skipped guard that reads as a passing one is the failure mode this
      // whole file exists to prevent, which is why this announces itself
      // rather than quietly returning.
      if (mergedManifests.isEmpty) {
        markTestSkipped(
          'No merged manifest under build/ — run '
          '`flutter build apk --debug --flavor develop` to exercise this. '
          'Checks (1) and (2) above still ran.',
        );
        return;
      }

      for (final manifest in mergedManifests) {
        final merged = healthPermission
            .allMatches(manifest.readAsStringSync())
            .map((match) => match.group(1)!)
            .toSet();

        expect(
          merged,
          {'READ_EXERCISE', 'READ_TOTAL_CALORIES_BURNED'},
          reason:
              '${manifest.path} ships a health permission set the repo did '
              'not declare, and one the plugin check did not predict. Find '
              'what contributed it — it need not be a Flutter plugin — and '
              'either drop it or get the Play Console declaration to cover '
              'it before this ships.',
        );
      }
    });
  });
}
