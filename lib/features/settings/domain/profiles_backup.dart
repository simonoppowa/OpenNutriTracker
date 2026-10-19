import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:opennutritracker/core/data/data_source/profile_data_source.dart';
import 'package:opennutritracker/core/data/data_source/user_activity_dbo.dart';
import 'package:opennutritracker/core/data/dbo/fasting_session_dbo.dart';
import 'package:opennutritracker/core/data/dbo/intake_dbo.dart';
import 'package:opennutritracker/core/data/dbo/profile_dbo.dart';
import 'package:opennutritracker/core/data/dbo/tracked_day_dbo.dart';
import 'package:opennutritracker/core/data/dbo/water_intake_dbo.dart';
import 'package:opennutritracker/core/data/dbo/weight_log_dbo.dart';
import 'package:opennutritracker/core/utils/hive_db_provider.dart';
import 'package:opennutritracker/core/utils/profile_box_scope.dart';
import 'package:opennutritracker/core/utils/user_image_storage.dart';
import 'package:opennutritracker/features/settings/domain/export_import_failure.dart';
import 'package:opennutritracker/features/settings/domain/goal_settings_backup.dart';
import 'package:opennutritracker/features/settings/domain/personal_backup_extras.dart';
import 'package:opennutritracker/features/settings/domain/usecase/export_data_usecase.dart';
import 'package:opennutritracker/features/settings/domain/usecase/import_data_usecase.dart';

/// The export and import usecases bound to one profile's boxes.
typedef BackupUsecases = ({
  ExportDataUsecase exporter,
  ImportDataUsecase importer,
});

/// Builds [BackupUsecases] for the box-set [db] hands out. Their extras must
/// not carry a [ProfilesBackup] themselves.
typedef BackupUsecasesFor = BackupUsecases Function(HiveDBProvider db);

/// Makes the JSON backup cover every profile, not only the active one.
///
/// The top level of the zip stays exactly what upstream writes for the
/// active profile (so upstream and older builds still import it). On top,
/// `profiles.json` lists every profile and names the one the top level
/// belongs to (the *main* profile), and each other profile gets a folder
/// `profiles/<id>/` with its own per-profile files. Shared data (custom
/// meals, recipes, activity templates, app settings, photos) lives at the
/// top level only.
///
/// On import the top level goes into the active profile, as before; each
/// folder goes into the profile with the same id, which is created when the
/// device does not have it.
class ProfilesBackup {
  static const profilesFileName = 'profiles.json';
  static const folderPrefix = 'profiles/';

  static const activityFileName = 'user_activity.json';
  static const intakeFileName = 'user_intake.json';
  static const trackedDayFileName = 'user_tracked_day.json';
  static const recipeFileName = 'user_recipes.json';
  static const weightLogFileName = 'weight_log.json';
  static const templateFileName = 'custom_activity_templates.json';
  static const goalSettingsFileName = 'goal_settings.json';

  /// The files of one profile's folder: everything per-profile the JSON
  /// bundle carries.
  static const profileFileNames = [
    activityFileName,
    intakeFileName,
    trackedDayFileName,
    weightLogFileName,
    goalSettingsFileName,
    PersonalBackupExtras.waterIntakeFileName,
    PersonalBackupExtras.fastingSessionsFileName,
    PersonalBackupExtras.userProfileFileName,
  ];

  final HiveDBProvider _db;
  final ProfileDataSource _profiles;
  final ProfileScopes _scopes;
  final BackupUsecasesFor _usecasesFor;

  ProfilesBackup(this._db, this._profiles, this._scopes, this._usecasesFor);

  /// Writes `profiles.json` and a folder for every profile except the active
  /// one into [archive].
  Future<void> addTo(Archive archive) async {
    final profiles = _profiles.getAllProfiles();
    final mainId = _db.activeProfileId;
    _addJson(archive, profilesFileName, {
      'mainProfileId': mainId,
      'profiles': [
        for (final profile in profiles)
          {
            'id': profile.id,
            'name': profile.name,
            'createdAt': profile.createdAt.toIso8601String(),
            'boxSuffix': profile.boxSuffix,
          },
      ],
    });

    for (final profile in profiles) {
      if (profile.id == mainId) continue;
      final scope = await _scopes.open(profile);
      try {
        final folder = await _usecasesFor(scope).exporter.assembleArchive(
          format: ExportFormat.json,
          userActivityJsonFileName: activityFileName,
          userIntakeJsonFileName: intakeFileName,
          trackedDayJsonFileName: trackedDayFileName,
          recipeJsonFileName: recipeFileName,
          weightLogJsonFileName: weightLogFileName,
          customActivityTemplateJsonFileName: templateFileName,
          goalSettingsJsonFileName: goalSettingsFileName,
        );
        for (final file in folder.files) {
          if (profileFileNames.contains(file.name)) {
            archive.addFile(
              ArchiveFile.bytes(
                '$folderPrefix${profile.id}/${file.name}',
                file.content as List<int>,
              ),
            );
          } else if (_isPhoto(file.name) &&
              archive.findFile(file.name) == null) {
            archive.addFile(
              ArchiveFile.bytes(file.name, file.content as List<int>),
            );
          }
        }
      } finally {
        await _scopes.close(profile);
      }
    }
  }

  /// Decodes `profiles.json` and every profile folder of [archive], so a
  /// malformed one throws an [ExportImportFailure] before anything is
  /// written. A zip without `profiles.json` (upstream, older builds)
  /// restores nothing here.
  ///
  /// Throws [ExportImportFailureReason.activeProfileIsNotBackupMain] when
  /// the device's active profile is one of the backup's *other* profiles:
  /// the top level would otherwise land in the wrong diary.
  PreparedRestore prepareRestore(
    Archive archive, {
    required bool includeProfileAndSettings,
    required bool replaceExisting,
  }) {
    final file = archive.findFile(profilesFileName);
    final listed = file == null ? null : _decodeProfiles(file);
    final mainId = listed?.mainId;
    final others = [
      for (final profile in listed?.profiles ?? const <ProfileDBO>[])
        if (profile.id != mainId) profile,
    ];
    if (others.any((profile) => profile.id == _db.activeProfileId)) {
      throw ExportImportFailure(
        ExportImportFailureReason.activeProfileIsNotBackupMain,
        'The active profile is not the main profile of this backup',
      );
    }
    final folders = {
      for (final profile in others) profile.id: _folder(archive, profile.id),
    };
    folders.forEach((id, folder) => _validateFolder(folder, id));
    final mainName = listed?.profiles
        .where((profile) => profile.id == mainId)
        .firstOrNull
        ?.name;

    return PreparedRestore(
      clearForReplace: () async {
        if (!replaceExisting) return;
        await _clearProfileData(_db);
        await _db.customMealBox.clear();
        await _db.recipeBox.clear();
        await _db.customActivityTemplateBox.clear();
        for (final local in _profiles.getAllProfiles()) {
          if (local.id == _db.activeProfileId) continue;
          if (folders.containsKey(local.id)) {
            final scope = await _scopes.open(local);
            try {
              await _clearProfileData(scope);
            } finally {
              await _scopes.close(local);
            }
          } else {
            await _scopes.delete(local);
            await _profiles.deleteProfile(local.id);
          }
        }
      },
      write: () async {
        if (includeProfileAndSettings && mainName != null) {
          final active = _profiles.getProfile(_db.activeProfileId);
          if (active != null && active.name != mainName) {
            active.name = mainName;
            await _profiles.saveProfile(active);
          }
        }
        for (final backupProfile in others) {
          final local = await _ensureProfile(backupProfile);
          final scope = await _scopes.open(local);
          try {
            await _usecasesFor(scope).importer.importArchive(
              folders[backupProfile.id]!,
              activityFileName,
              intakeFileName,
              trackedDayFileName,
              recipeFileName,
              weightLogFileName,
              templateFileName,
              goalSettingsJsonFileName: goalSettingsFileName,
              restoreProfileAndSettings: includeProfileAndSettings,
            );
          } finally {
            await _scopes.close(local);
          }
        }
      },
    );
  }

  /// The device's profile for [backupProfile]: the one with the same id, or
  /// a new one under that id. The new profile keeps the backup's box suffix
  /// unless it is empty (the device's first profile owns that) or taken.
  Future<ProfileDBO> _ensureProfile(ProfileDBO backupProfile) async {
    final existing = _profiles.getProfile(backupProfile.id);
    if (existing != null) return existing;
    final takenSuffixes = {
      for (final local in _profiles.getAllProfiles()) local.boxSuffix,
    };
    final suffix =
        backupProfile.boxSuffix.isEmpty ||
            takenSuffixes.contains(backupProfile.boxSuffix)
        ? backupProfile.id.replaceAll('-', '')
        : backupProfile.boxSuffix;
    final created = ProfileDBO(
      id: backupProfile.id,
      name: backupProfile.name,
      createdAt: backupProfile.createdAt,
      boxSuffix: suffix,
    );
    await _profiles.saveProfile(created);
    return created;
  }

  /// Clears the logs a restore replaces. The profile body data and the goals
  /// stay: the restore overwrites them when the user asked for it.
  static Future<void> _clearProfileData(HiveDBProvider db) async {
    await db.intakeBox.clear();
    await db.userActivityBox.clear();
    await db.trackedDayBox.clear();
    await db.weightLogBox.clear();
    await db.waterIntakeBox.clear();
    await db.fastingBox.clear();
  }

  /// A photo entry of a profile's folder export (an intake photo of that
  /// profile, or a shared custom meal or recipe photo). Photos live at the
  /// top level, where upstream's import writes them back.
  static bool _isPhoto(String name) =>
      name.startsWith('${UserImageKind.meal.subdir}/') ||
      name.startsWith('${UserImageKind.recipe.subdir}/');

  static Archive _folder(Archive archive, String profileId) {
    final prefix = '$folderPrefix$profileId/';
    final folder = Archive();
    for (final file in archive.files) {
      if (!file.isFile || !file.name.startsWith(prefix)) continue;
      folder.addFile(
        ArchiveFile.bytes(
          file.name.substring(prefix.length),
          file.content as List<int>,
        ),
      );
    }
    return folder;
  }

  /// Decodes every file of a profile folder the way its import will, so a
  /// broken folder is found before the first write.
  static void _validateFolder(Archive folder, String profileId) {
    ExportImportFailure.guardSync(
      ExportImportFailureReason.unreadableOrWrongFormat,
      'Could not parse the folder of profile $profileId',
      () {
        Object? read(String name, {bool required = false}) {
          final file = folder.findFile(name);
          if (file == null) {
            if (required) throw FormatException('Missing $name');
            return null;
          }
          return _decodeFinite(file);
        }

        List<Map<String, dynamic>> rows(String name, {bool required = false}) {
          final json = read(name, required: required);
          if (json == null && folder.findFile(name) == null) return const [];
          return (json as List).cast<Map<String, dynamic>>();
        }

        rows(
          activityFileName,
          required: true,
        ).forEach(UserActivityDBO.fromJson);
        rows(intakeFileName, required: true).forEach(IntakeDBO.fromJson);
        rows(
          trackedDayFileName,
          required: true,
        ).forEach(TrackedDayDBO.fromJson);
        rows(weightLogFileName).forEach(WeightLogDBO.fromJson);
        rows(
          PersonalBackupExtras.waterIntakeFileName,
        ).forEach(WaterIntakeDBO.fromJson);
        rows(
          PersonalBackupExtras.fastingSessionsFileName,
        ).forEach(FastingSessionDBO.fromJson);
        if (folder.findFile(goalSettingsFileName) != null) {
          GoalSettingsBackup.fromJson(
            read(goalSettingsFileName) as Map<String, dynamic>,
          );
        }
        if (folder.findFile(PersonalBackupExtras.userProfileFileName) != null) {
          PersonalBackupExtras.decodeUserProfile(
            read(PersonalBackupExtras.userProfileFileName)
                as Map<String, dynamic>,
          );
        }
      },
    );
  }

  static ({String? mainId, List<ProfileDBO> profiles}) _decodeProfiles(
    ArchiveFile file,
  ) => ExportImportFailure.guardSync(
    ExportImportFailureReason.unreadableOrWrongFormat,
    'Could not parse $profilesFileName',
    () {
      final json = _decodeFinite(file) as Map<String, dynamic>;
      return (
        mainId: json['mainProfileId'] as String?,
        profiles: [
          for (final row
              in (json['profiles'] as List).cast<Map<String, dynamic>>())
            ProfileDBO(
              id: row['id'] as String,
              name: row['name'] as String,
              createdAt: DateTime.parse(row['createdAt'] as String),
              boxSuffix: row['boxSuffix'] as String? ?? '',
            ),
        ],
      );
    },
  );

  static Object? _decodeFinite(ArchiveFile file) => jsonDecode(
    utf8.decode(file.content as List<int>),
    reviver: (key, value) {
      if (value is double && !value.isFinite) {
        throw FormatException('Not a finite number', '$key');
      }
      return value;
    },
  );

  static void _addJson(Archive archive, String name, Object json) {
    archive.addFile(ArchiveFile.bytes(name, utf8.encode(jsonEncode(json))));
  }
}

/// What a restore does after every file has been decoded: [clearForReplace]
/// (a no-op unless the user chose to replace everything), then [write].
class PreparedRestore {
  final Future<void> Function() clearForReplace;
  final Future<void> Function() write;

  const PreparedRestore({required this.clearForReplace, required this.write});
}
