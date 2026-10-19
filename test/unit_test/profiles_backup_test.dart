import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:opennutritracker/core/data/data_source/custom_activity_template_dbo.dart';
import 'package:opennutritracker/core/data/data_source/profile_data_source.dart';
import 'package:opennutritracker/core/data/data_source/user_activity_dbo.dart';
import 'package:opennutritracker/core/data/data_source/user_data_source.dart';
import 'package:opennutritracker/core/data/dbo/config_dbo.dart';
import 'package:opennutritracker/core/data/dbo/fasting_session_dbo.dart';
import 'package:opennutritracker/core/data/dbo/intake_dbo.dart';
import 'package:opennutritracker/core/data/dbo/meal_dbo.dart';
import 'package:opennutritracker/core/data/dbo/profile_dbo.dart';
import 'package:opennutritracker/core/data/dbo/recipe_dbo.dart';
import 'package:opennutritracker/core/data/dbo/tracked_day_dbo.dart';
import 'package:opennutritracker/core/data/dbo/user_dbo.dart';
import 'package:opennutritracker/core/data/dbo/user_gender_dbo.dart';
import 'package:opennutritracker/core/data/dbo/user_pal_dbo.dart';
import 'package:opennutritracker/core/data/dbo/user_weight_goal_dbo.dart';
import 'package:opennutritracker/core/data/dbo/water_intake_dbo.dart';
import 'package:opennutritracker/core/data/dbo/weight_log_dbo.dart';
import 'package:opennutritracker/core/utils/backup_usecases_for.dart';
import 'package:opennutritracker/core/utils/hive_db_provider.dart';
import 'package:opennutritracker/core/utils/profile_box_scope.dart';
import 'package:opennutritracker/features/settings/domain/export_import_failure.dart';
import 'package:opennutritracker/features/settings/domain/personal_backup_extras.dart';
import 'package:opennutritracker/features/settings/domain/profiles_backup.dart';
import 'package:opennutritracker/features/settings/domain/usecase/export_data_usecase.dart';
import 'package:opennutritracker/features/settings/presentation/bloc/export_import_bloc.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import '../helpers/fake_hive_db_provider.dart';
import '../helpers/hive_test_setup.dart';

class _FakePathProvider extends PathProviderPlatform
    with MockPlatformInterfaceMixin {
  _FakePathProvider(this.root);

  final String root;

  @override
  Future<String?> getApplicationDocumentsPath() async => root;
}

/// One simulated device: shared boxes, a profile registry and one box-set
/// per profile, handed out the way [HiveProfileScopes] does.
class _Device implements ProfileScopes {
  _Device._(this.shared, this.profileBox);

  final ({
    Box<MealDBO> customMeals,
    Box<RecipeDBO> recipes,
    Box<CustomActivityTemplateDBO> templates,
    Box<ConfigDBO> appConfig,
  })
  shared;
  final Box<ProfileDBO> profileBox;
  final _sets = <String, FakeHiveDBProvider>{};
  final deleted = <String>[];
  late FakeHiveDBProvider active;

  static int _counter = 0;

  static Future<Box<T>> _open<T>(String name) =>
      Hive.openBox<T>('${name}_${_counter++}');

  static Future<_Device> create() async {
    final device = _Device._((
      customMeals: await _open<MealDBO>('custom_meal'),
      recipes: await _open<RecipeDBO>('recipe'),
      templates: await _open<CustomActivityTemplateDBO>('template'),
      appConfig: await _open<ConfigDBO>('app_config'),
    ), await _open<ProfileDBO>('profiles'));
    return device;
  }

  Future<FakeHiveDBProvider> addProfile(
    String id, {
    String? name,
    String suffix = '',
    bool makeActive = false,
  }) async {
    await profileBox.put(
      id,
      ProfileDBO(
        id: id,
        name: name ?? id,
        createdAt: DateTime(2026, 1, 1),
        boxSuffix: suffix,
      ),
    );
    final set = await _boxSet(id);
    if (makeActive) active = set;
    return set;
  }

  Future<FakeHiveDBProvider> _boxSet(String id) async =>
      _sets[id] ??= FakeHiveDBProvider(
        activeProfileId: id,
        configBox: await _open<ConfigDBO>('config_$id'),
        appConfigBox: shared.appConfig,
        intakeBox: await _open<IntakeDBO>('intake_$id'),
        userActivityBox: await _open<UserActivityDBO>('activity_$id'),
        userBox: await _open<UserDBO>('user_$id'),
        trackedDayBox: await _open<TrackedDayDBO>('tracked_$id'),
        weightLogBox: await _open<WeightLogDBO>('weight_$id'),
        waterIntakeBox: await _open<WaterIntakeDBO>('water_$id'),
        fastingBox: await _open<FastingSessionDBO>('fasting_$id'),
        customMealBox: shared.customMeals,
        recipeBox: shared.recipes,
        customActivityTemplateBox: shared.templates,
        profileBox: profileBox,
      );

  FakeHiveDBProvider boxesOf(String id) => _sets[id]!;

  @override
  Future<HiveDBProvider> open(ProfileDBO profile) => _boxSet(profile.id);

  @override
  Future<void> close(ProfileDBO profile) async {}

  @override
  Future<void> delete(ProfileDBO profile) async => deleted.add(profile.id);

  /// The usecases of the active profile, with the all-profiles backup.
  BackupUsecases usecases() => backupUsecasesFor(
    active,
    profiles: ProfilesBackup(
      active,
      ProfileDataSource(active),
      this,
      backupUsecasesFor,
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory tempDir;
  late PathProviderPlatform originalPathProvider;

  setUpAll(() {
    Hive.init(Directory.systemTemp.createTempSync('profiles_backup').path);
    registerHiveAdaptersOnce();
  });

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('profiles_backup_docs');
    originalPathProvider = PathProviderPlatform.instance;
    PathProviderPlatform.instance = _FakePathProvider(tempDir.path);
  });

  tearDown(() async {
    PathProviderPlatform.instance = originalPathProvider;
    await Hive.close();
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  IntakeDBO intake(String id) => IntakeDBO.fromJson({
    'id': id,
    'unit': 'g',
    'amount': 100.0,
    'type': 'breakfast',
    'dateTime': '2026-10-01T08:00:00.000',
    'meal': {
      'name': 'Porridge $id',
      'mealQuantity': '100',
      'mealUnit': 'g',
      'source': 'custom',
      'nutriments': {'energyKcal100': 120.0},
    },
  });

  UserDBO user(double weight) => UserDBO(
    birthday: DateTime(1990),
    heightCM: 175,
    weightKG: weight,
    gender: UserGenderDBO.male,
    goal: UserWeightGoalDBO.maintainWeight,
    pal: UserPALDBO.active,
  );

  Future<Archive> exportFrom(_Device device) async {
    final exporter = device.usecases().exporter;
    final archive = await exporter.assembleArchive(
      format: ExportFormat.json,
      userActivityJsonFileName: ExportImportBloc.userActivityJsonFileName,
      userIntakeJsonFileName: ExportImportBloc.userIntakeJsonFileName,
      trackedDayJsonFileName: ExportImportBloc.trackedDayJsonFileName,
      recipeJsonFileName: ExportImportBloc.recipeJsonFileName,
      weightLogJsonFileName: ExportImportBloc.weightLogJsonFileName,
      customActivityTemplateJsonFileName:
          ExportImportBloc.customActivityTemplateJsonFileName,
    );
    return ZipDecoder().decodeBytes(ZipEncoder().encode(archive));
  }

  Future<void> importInto(
    _Device device,
    Archive archive, {
    bool replaceExisting = false,
  }) => device.usecases().importer.importArchive(
    archive,
    ExportImportBloc.userActivityJsonFileName,
    ExportImportBloc.userIntakeJsonFileName,
    ExportImportBloc.trackedDayJsonFileName,
    ExportImportBloc.recipeJsonFileName,
    ExportImportBloc.weightLogJsonFileName,
    ExportImportBloc.customActivityTemplateJsonFileName,
    replaceExisting: replaceExisting,
  );

  Future<_Device> twoProfileDevice() async {
    final device = await _Device.create();
    final me = await device.addProfile('me', name: 'Theo', makeActive: true);
    final partner = await device.addProfile(
      'partner',
      name: 'Partner',
      suffix: 'partner',
    );
    await me.intakeBox.add(intake('me-1'));
    await partner.intakeBox.add(intake('partner-1'));
    await partner.intakeBox.add(intake('partner-2'));
    await UserDataSource(me).saveUserData(user(84));
    await UserDataSource(partner).saveUserData(user(62));
    await partner.waterIntakeBox.put(
      'w1',
      WaterIntakeDBO(id: 'w1', dateTime: DateTime(2026, 10, 1), amountMl: 500),
    );
    return device;
  }

  test('the file names match the ones the bloc exports under', () {
    expect(
      ProfilesBackup.activityFileName,
      ExportImportBloc.userActivityJsonFileName,
    );
    expect(
      ProfilesBackup.intakeFileName,
      ExportImportBloc.userIntakeJsonFileName,
    );
    expect(
      ProfilesBackup.trackedDayFileName,
      ExportImportBloc.trackedDayJsonFileName,
    );
    expect(ProfilesBackup.recipeFileName, ExportImportBloc.recipeJsonFileName);
    expect(
      ProfilesBackup.weightLogFileName,
      ExportImportBloc.weightLogJsonFileName,
    );
    expect(
      ProfilesBackup.templateFileName,
      ExportImportBloc.customActivityTemplateJsonFileName,
    );
    expect(
      ProfilesBackup.goalSettingsFileName,
      ExportImportBloc.goalSettingsJsonFileName,
    );
  });

  test(
    'the export lists every profile and gives the others a folder',
    () async {
      final archive = await exportFrom(await twoProfileDevice());

      final listed =
          jsonDecode(
                utf8.decode(
                  archive.findFile(ProfilesBackup.profilesFileName)!.content
                      as List<int>,
                ),
              )
              as Map<String, dynamic>;
      expect(listed['mainProfileId'], 'me');
      expect(
        (listed['profiles'] as List).map((p) => p['name']),
        unorderedEquals(['Theo', 'Partner']),
      );
      final folder = archive.files
          .where((f) => f.name.startsWith('profiles/partner/'))
          .map((f) => f.name.substring('profiles/partner/'.length));
      expect(
        folder,
        containsAll([
          'user_intake.json',
          'water_intake.json',
          'user_profile.json',
        ]),
      );
      expect(
        folder,
        isNot(contains(PersonalBackupExtras.customMealsFileName)),
        reason: 'shared data is at the top level only',
      );
      expect(
        archive.files.any((f) => f.name.startsWith('profiles/me/')),
        isFalse,
      );
    },
  );

  test('a fresh device gets every profile back', () async {
    final archive = await exportFrom(await twoProfileDevice());
    final fresh = await _Device.create();
    await fresh.addProfile('device-default', makeActive: true);

    await importInto(fresh, archive);

    expect(
      fresh.active.intakeBox.values.map((i) => i.id),
      ['me-1'],
      reason: 'the top level goes into the active profile',
    );
    expect(fresh.profileBox.get('device-default')!.name, 'Theo');
    final partner = fresh.profileBox.get('partner')!;
    expect(partner.name, 'Partner');
    final partnerBoxes = fresh.boxesOf('partner');
    expect(
      partnerBoxes.intakeBox.values.map((i) => i.id),
      unorderedEquals(['partner-1', 'partner-2']),
    );
    expect(partnerBoxes.waterIntakeBox.values.single.amountMl, 500);
    expect((await UserDataSource(partnerBoxes).getUserData()).weightKG, 62);
  });

  test('importing the same backup twice adds nothing', () async {
    final archive = await exportFrom(await twoProfileDevice());
    final fresh = await _Device.create();
    await fresh.addProfile('device-default', makeActive: true);

    await importInto(fresh, archive);
    await importInto(fresh, archive);

    expect(fresh.boxesOf('partner').intakeBox.length, 2);
    expect(fresh.profileBox.length, 2);
  });

  test('replacing clears the device first and drops profiles not in the '
      'backup', () async {
    final archive = await exportFrom(await twoProfileDevice());
    final device = await _Device.create();
    final active = await device.addProfile('me', makeActive: true);
    final partner = await device.addProfile('partner', suffix: 'partner');
    await device.addProfile('stranger', suffix: 'stranger');
    await active.intakeBox.add(intake('only-on-device'));
    await partner.intakeBox.add(intake('partner-only-on-device'));
    await device.shared.customMeals.add(
      MealDBO.fromJson({
        'name': 'Leftover',
        'mealQuantity': '100',
        'mealUnit': 'g',
        'source': 'custom',
        'nutriments': {'energyKcal100': 1.0},
      }),
    );

    await importInto(device, archive, replaceExisting: true);

    expect(active.intakeBox.values.map((i) => i.id), ['me-1']);
    expect(
      partner.intakeBox.values.map((i) => i.id),
      unorderedEquals(['partner-1', 'partner-2']),
    );
    expect(device.shared.customMeals.isEmpty, isTrue);
    expect(device.deleted, ['stranger']);
    expect(device.profileBox.containsKey('stranger'), isFalse);
  });

  test('a broken profile folder rejects the import before any write', () async {
    final archive = await exportFrom(await twoProfileDevice());
    final broken = Archive();
    for (final file in archive.files) {
      if (file.name == 'profiles/partner/user_intake.json') continue;
      broken.addFile(file);
    }
    broken.addFile(
      ArchiveFile.bytes('profiles/partner/user_intake.json', utf8.encode('{')),
    );
    final fresh = await _Device.create();
    await fresh.addProfile('device-default', makeActive: true);

    await expectLater(
      importInto(fresh, broken, replaceExisting: true),
      throwsA(isA<ExportImportFailure>()),
    );
    expect(fresh.active.intakeBox.isEmpty, isTrue);
    expect(fresh.profileBox.containsKey('partner'), isFalse);
  });

  for (final name in [
    'fasting_sessions.json',
    'water_intake.json',
    'goal_settings.json',
    'user_profile.json',
  ]) {
    test(
      'a folder file holding null is rejected before any write ($name)',
      () async {
        final archive = await exportFrom(await twoProfileDevice());
        final broken = Archive();
        for (final file in archive.files) {
          if (file.name == 'profiles/partner/$name') continue;
          broken.addFile(file);
        }
        broken.addFile(
          ArchiveFile.bytes('profiles/partner/$name', utf8.encode('null')),
        );
        final fresh = await _Device.create();
        final active = await fresh.addProfile(
          'device-default',
          makeActive: true,
        );
        await active.intakeBox.add(intake('keep-me'));

        await expectLater(
          importInto(fresh, broken, replaceExisting: true),
          throwsA(isA<ExportImportFailure>()),
        );
        expect(active.intakeBox.values.map((i) => i.id), ['keep-me']);
      },
    );
  }

  test(
    'an active profile that is another profile of the backup is refused',
    () async {
      final archive = await exportFrom(await twoProfileDevice());
      final device = await _Device.create();
      await device.addProfile('me');
      final partner = await device.addProfile(
        'partner',
        suffix: 'partner',
        makeActive: true,
      );

      await expectLater(
        importInto(device, archive),
        throwsA(
          isA<ExportImportFailure>().having(
            (failure) => failure.reason,
            'reason',
            ExportImportFailureReason.activeProfileIsNotBackupMain,
          ),
        ),
      );
      expect(partner.intakeBox.isEmpty, isTrue);
    },
  );

  test(
    'a photo on another profile\'s diary entry travels and comes back',
    () async {
      const slug = 'meal_images/partner-lunch.webp';
      final photo = File('${tempDir.path}/$slug');
      await photo.parent.create(recursive: true);
      await photo.writeAsBytes([4, 2], flush: true);
      final device = await twoProfileDevice();
      final withPhoto = intake('partner-photo')
        ..meal = MealDBO.fromJson({
          'name': 'Lunch',
          'mealQuantity': '100',
          'mealUnit': 'g',
          'source': 'custom',
          'localImagePath': slug,
          'nutriments': {'energyKcal100': 300.0},
        });
      await device.boxesOf('partner').intakeBox.add(withPhoto);

      final archive = await exportFrom(device);
      expect(archive.findFile(slug), isNotNull);

      await photo.delete();
      final fresh = await _Device.create();
      await fresh.addProfile('device-default', makeActive: true);
      await importInto(fresh, archive);

      expect(await photo.readAsBytes(), [4, 2]);
    },
  );

  test(
    'fasting sessions travel per profile and replace those on the device',
    () async {
      final source = await twoProfileDevice();
      await source
          .boxesOf('partner')
          .fastingBox
          .put(
            'partner-fast',
            FastingSessionDBO(
              id: 'partner-fast',
              startedAt: DateTime(2026, 10, 1, 20),
              targetDurationMinutes: 960,
            ),
          );
      final archive = await exportFrom(source);
      final device = await _Device.create();
      final active = await device.addProfile('me', makeActive: true);
      await active.fastingBox.put(
        'only-on-device',
        FastingSessionDBO(
          id: 'only-on-device',
          startedAt: DateTime(2026, 9, 1, 20),
          targetDurationMinutes: 720,
        ),
      );

      await importInto(device, archive, replaceExisting: true);

      expect(active.fastingBox.isEmpty, isTrue);
      expect(device.boxesOf('partner').fastingBox.keys, ['partner-fast']);
    },
  );

  test('a backup without profiles.json imports as before', () async {
    final archive = await exportFrom(await twoProfileDevice());
    final upstreamShaped = Archive();
    for (final file in archive.files) {
      if (file.name == ProfilesBackup.profilesFileName ||
          file.name.startsWith(ProfilesBackup.folderPrefix)) {
        continue;
      }
      upstreamShaped.addFile(file);
    }
    final fresh = await _Device.create();
    await fresh.addProfile('device-default', makeActive: true);

    await importInto(fresh, upstreamShaped);

    expect(fresh.active.intakeBox.values.map((i) => i.id), ['me-1']);
    expect(fresh.profileBox.length, 1);
  });
}
