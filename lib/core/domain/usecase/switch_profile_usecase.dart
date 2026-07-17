import 'package:opennutritracker/core/data/data_source/config_data_source.dart';
import 'package:opennutritracker/core/domain/entity/profile_entity.dart';
import 'package:opennutritracker/core/utils/config_initializer.dart';
import 'package:opennutritracker/core/utils/hive_db_provider.dart';
import 'package:opennutritracker/core/utils/secure_app_storage_provider.dart';

/// Makes [profile] the active profile: swaps the open box-set, persists
/// the active pointer, and seeds the target's config if it's brand new.
///
/// This is the data-layer half of a switch. Reloading the on-screen BLoCs
/// and routing the user belong to the presentation layer
/// (`ProfileSwitchCoordinator`).
class SwitchProfileUsecase {
  final HiveDBProvider _hiveDBProvider;
  final SecureAppStorageProvider _secureAppStorageProvider;
  final ConfigDataSource _configDataSource;

  SwitchProfileUsecase(
    this._hiveDBProvider,
    this._secureAppStorageProvider,
    this._configDataSource,
  );

  Future<void> switchProfile(ProfileEntity profile) async {
    await _hiveDBProvider.switchProfile(profile.id, profile.boxSuffix);
    await _secureAppStorageProvider.setActiveProfileId(profile.id);
    await ensureConfigInitialized(_configDataSource);
  }
}
