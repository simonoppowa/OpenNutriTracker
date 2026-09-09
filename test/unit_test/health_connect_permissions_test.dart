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
/// well-meant revert of the workout reader that restores the plugin's workout
/// path along with the permissions it needs, and a Flutter plugin that merges
/// its own `uses-permission` in.
///
/// **Only the first is caught everywhere.** The checked-in manifest is not what
/// ships: Android's manifest merger folds every plugin's manifest into it
/// afterwards, so a permission arriving that way is invisible to a test that
/// reads `android/app/src/main/AndroidManifest.xml`. The merged-manifest group
/// below closes that, but Gradle has to have run first — it is skipped on a
/// checkout that has not built Android, which includes the `linux-checks` job.
/// `android-build` is where it has teeth.
void main() {
  final manifest = File(
    'android/app/src/main/AndroidManifest.xml',
  ).readAsStringSync();

  final healthPermission = RegExp(
    r'<uses-permission\s+android:name="android\.permission\.health\.([A-Z_]+)"',
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
  final pluginList = File('.flutter-plugins-dependencies');
  final pluginListPresent = pluginList.existsSync();
  final pluginPermissions = <String, Set<String>>{};
  if (pluginListPresent) {
    final plugins = ((jsonDecode(pluginList.readAsStringSync())
            as Map<String, dynamic>)['plugins']
        as Map<String, dynamic>)['android'] as List<dynamic>;
    for (final plugin in plugins.cast<Map<String, dynamic>>()) {
      final root = (plugin['path'] as String).replaceAll(RegExp(r'/+$'), '');
      final pluginManifest = File('$root/android/src/main/AndroidManifest.xml');
      if (!pluginManifest.existsSync()) continue;
      final found = healthPermission
          .allMatches(pluginManifest.readAsStringSync())
          .map((m) => m.group(1)!)
          .toSet();
      if (found.isNotEmpty) {
        pluginPermissions[plugin['name'] as String] = found;
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

    test('the plugin list is available, so the plugin half checked something',
        () {
      expect(
        pluginListPresent,
        isTrue,
        reason:
            '.flutter-plugins-dependencies is missing, so no plugin manifest '
            'was inspected and the plugin half of this guard passed without '
            'checking anything. Run `flutter pub get` first; CI already does.',
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

  // What Play actually inspects. A plugin's own manifest is merged into the
  // app's, so this is the only place a permission the repo never declared can
  // be seen — and the reason the manifest was checked by hand while #1122 was
  // being written.
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
      // Not a failure: the Android build is not a precondition for running the
      // unit suite. Silence would be, though — a skipped guard that reads as a
      // passing one is the failure mode this whole file exists to avoid.
      if (mergedManifests.isEmpty) {
        markTestSkipped(
          'No merged manifest under build/ — run '
          '`flutter build apk --debug --flavor develop` to exercise this. '
          'The source-manifest assertions above still ran.',
        );
        return;
      }

      for (final manifest in mergedManifests) {
        final merged = RegExp(
          r'<uses-permission\s+android:name="android\.permission\.health\.([A-Z_]+)"',
        )
            .allMatches(manifest.readAsStringSync())
            .map((match) => match.group(1)!)
            .toSet();

        expect(
          merged,
          {'READ_EXERCISE', 'READ_TOTAL_CALORIES_BURNED'},
          reason:
              '${manifest.path} ships a health permission set the repo did '
              'not declare. A dependency merged it in — find which, and '
              'either remove the dependency or justify the permission in the '
              'Play Console declaration before it ships.',
        );
      }
    });
  });
}
