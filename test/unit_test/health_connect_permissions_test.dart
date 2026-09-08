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
void main() {
  final manifest = File(
    'android/app/src/main/AndroidManifest.xml',
  ).readAsStringSync();

  /// Every `android.permission.health.*` the manifest declares.
  final declared = RegExp(
    r'<uses-permission\s+android:name="android\.permission\.health\.([A-Z_]+)"',
  ).allMatches(manifest).map((match) => match.group(1)!).toSet();

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
      // Catches a plugin quietly merging one in, and catches a new read being
      // added without the declaration form being updated to match.
      expect(
        declared,
        {'READ_EXERCISE', 'READ_TOTAL_CALORIES_BURNED'},
        reason:
            'Every declared Health Connect permission has to be justified by '
            'a feature in the Play Console declaration form. Adding one here '
            'without updating that form is what gets an update rejected.',
      );
    });

    test('nothing is ever written back', () {
      expect(
        declared.where((permission) => permission.startsWith('WRITE_')),
        isEmpty,
      );
    });
  });
}
