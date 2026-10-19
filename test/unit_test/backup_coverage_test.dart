import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/utils/hive_db_provider.dart';
import 'package:opennutritracker/features/settings/domain/personal_backup_extras.dart';
import 'package:opennutritracker/features/settings/domain/profiles_backup.dart';

/// Where each Hive box lives in the JSON backup.
///
/// Every box `HiveDBProvider` declares must be listed here, either with the
/// backup file that carries it or as a deliberate exclusion. A new box makes
/// this test fail until someone decides how it is backed up, which is how
/// each new feature extends the backup instead of forgetting it.
const _coverage = <String, String>{
  HiveDBProvider.configBoxName:
      '${ProfilesBackup.goalSettingsFileName} + '
      '${PersonalBackupExtras.appSettingsFileName}',
  HiveDBProvider.appConfigBoxName: PersonalBackupExtras.appSettingsFileName,
  HiveDBProvider.intakeBoxName: ProfilesBackup.intakeFileName,
  HiveDBProvider.userActivityBoxName: ProfilesBackup.activityFileName,
  HiveDBProvider.userBoxName: PersonalBackupExtras.userProfileFileName,
  HiveDBProvider.trackedDayBoxName: ProfilesBackup.trackedDayFileName,
  HiveDBProvider.weightLogBoxName: ProfilesBackup.weightLogFileName,
  HiveDBProvider.waterIntakeBoxName: PersonalBackupExtras.waterIntakeFileName,
  HiveDBProvider.customMealBoxName: PersonalBackupExtras.customMealsFileName,
  HiveDBProvider.recipeBoxName: ProfilesBackup.recipeFileName,
  HiveDBProvider.customActivityTemplateBoxName: ProfilesBackup.templateFileName,
  HiveDBProvider.profileBoxName: ProfilesBackup.profilesFileName,
  HiveDBProvider.cachedOffMealBoxName: _excludedCache,
  HiveDBProvider.cachedOffMealTimestampsBoxName: _excludedCache,
  HiveDBProvider.fastingBoxName: _pendingFasting,
};

const _excludedCache = 'excluded: search cache, refilled by searching';
const _pendingFasting = 'pending: fasting sessions (#28)';

void main() {
  final declared = RegExp(r"static const (\w+BoxName) = '(\w+)';")
      .allMatches(
        File('lib/core/utils/hive_db_provider.dart').readAsStringSync(),
      )
      .map((match) => match.group(2)!)
      .toSet();

  test('the scan finds the boxes it is meant to find', () {
    expect(declared, contains(HiveDBProvider.intakeBoxName));
    expect(declared.length, greaterThanOrEqualTo(15));
  });

  test('every box is backed up or deliberately left out', () {
    expect(
      declared.difference(_coverage.keys.toSet()),
      isEmpty,
      reason: 'a new box needs a backup file, or an entry here saying why not',
    );
    expect(
      _coverage.keys.toSet().difference(declared),
      isEmpty,
      reason: 'a box listed here no longer exists',
    );
  });

  test('every per-profile box travels in the other profiles\' folders', () {
    final folderFiles = ProfilesBackup.profileFileNames.toSet();
    for (final box in HiveDBProvider.perProfileBoxNames) {
      final where = _coverage[box]!;
      if (where.startsWith('pending')) continue;
      expect(
        folderFiles.any(where.contains),
        isTrue,
        reason: '$box is per profile, so its file belongs in each folder',
      );
    }
  });
}
