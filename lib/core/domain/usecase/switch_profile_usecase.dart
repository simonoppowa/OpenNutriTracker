import 'package:opennutritracker/core/data/data_source/config_data_source.dart';
import 'package:opennutritracker/core/domain/entity/profile_entity.dart';
import 'package:opennutritracker/core/utils/config_initializer.dart';
import 'package:opennutritracker/core/utils/hive_db_provider.dart';
import 'package:opennutritracker/core/utils/off_micronutrient_repair.dart';
import 'package:opennutritracker/core/utils/secure_app_storage_provider.dart';
import 'package:opennutritracker/core/utils/tracked_day_lock.dart';
import 'package:opennutritracker/core/utils/tracked_day_reconciler.dart';

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
  final Future<TrackedDayGoals> Function()? _currentTrackedDayGoals;

  SwitchProfileUsecase(
    this._hiveDBProvider,
    this._secureAppStorageProvider,
    this._configDataSource, {
    Future<TrackedDayGoals> Function()? currentTrackedDayGoals,
  }) : _currentTrackedDayGoals = currentTrackedDayGoals;

  /// Held under [withTrackedDayLock] from the box swap to the last repair
  /// (#1317). Data sources resolve their box through the provider on every
  /// call, so a writer paused between storing an entry and adding it to
  /// its row would otherwise resume after the swap and add the outgoing
  /// profile's entry to the incoming profile's row. Waiting for the lock
  /// lets every such writer finish on the profile it started on; UI writes
  /// queued behind this switch are discarded by [withProfileSwitchLock].
  Future<void> switchProfile(ProfileEntity profile) =>
      withProfileSwitchLock(() => _switchProfile(profile));

  Future<void> _switchProfile(ProfileEntity profile) async {
    await _hiveDBProvider.switchProfile(profile.id, profile.boxSuffix);
    await _secureAppStorageProvider.setActiveProfileId(profile.id);
    await ensureConfigInitialized(_configDataSource);
    // The target's intake log has not been opened since the upgrade if this
    // profile was never active on the new build; repair it before the tab
    // BLoCs reload against it (#1152).
    await ensureOffMicronutrientsRepaired(_hiveDBProvider);
    // Same reason: a day total this profile took a NaN into on an older
    // build is rebuilt from its intakes before the tabs read it (#1254).
    // And the boundary is app-wide: if it moved while another profile was
    // active, this profile's rows are still keyed by the old one (#1317).
    await ensureTrackedDaysRepaired(
      _hiveDBProvider,
      _configDataSource,
      currentGoals: _currentTrackedDayGoals,
    );
  }
}
