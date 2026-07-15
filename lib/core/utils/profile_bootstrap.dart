import 'package:logging/logging.dart';
import 'package:opennutritracker/core/data/dbo/profile_dbo.dart';
import 'package:opennutritracker/core/utils/hive_db_provider.dart';
import 'package:opennutritracker/core/utils/id_generator.dart';
import 'package:opennutritracker/core/utils/secure_app_storage_provider.dart';

final _log = Logger('ProfileBootstrap');

/// Resolves which profile is active at startup and opens its box-set.
///
/// On a fresh install — or the first launch after upgrading from a
/// single-user build — the registry is empty, so a default profile is
/// created with an empty box suffix. That empty suffix is the whole trick:
/// the default profile's boxes resolve to the original, unsuffixed names
/// already sitting on disk, so a long-time user's meals, weight history and
/// settings come across untouched, with nothing copied or migrated.
///
/// Must run after [HiveDBProvider.initHiveDB] (which opens the global
/// profile registry) and before any per-profile data is read.
Future<void> bootstrapActiveProfile(
  HiveDBProvider hiveDBProvider,
  SecureAppStorageProvider secureAppStorageProvider,
) async {
  final profileBox = hiveDBProvider.profileBox;

  if (profileBox.isEmpty) {
    _log.info('No profiles found — creating the default profile');
    final id = IdGenerator.getUniqueID();
    final defaultProfile = ProfileDBO(
      id: id,
      name: '',
      createdAt: DateTime.now(),
      boxSuffix: '',
    );
    await profileBox.put(id, defaultProfile);
    await secureAppStorageProvider.setActiveProfileId(id);
  }

  var activeId = await secureAppStorageProvider.getActiveProfileId();
  var activeProfile = activeId == null ? null : profileBox.get(activeId);

  // Pointer dangles (profile deleted, storage cleared, downgrade): fall
  // back to the first registered profile and repair the pointer.
  if (activeProfile == null) {
    activeProfile = profileBox.values.first;
    activeId = activeProfile.id;
    await secureAppStorageProvider.setActiveProfileId(activeId);
    _log.info('Active profile pointer was stale — fell back to $activeId');
  }

  await hiveDBProvider.openProfileBoxes(
    activeProfile.id,
    activeProfile.boxSuffix,
  );
}
