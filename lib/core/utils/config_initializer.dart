import 'package:opennutritracker/core/data/data_source/config_data_source.dart';

/// Seeds an empty config with its defaults if it hasn't been seeded yet.
///
/// Runs at startup for the active profile and again whenever a new profile
/// is created or switched to, since every profile owns its own ConfigBox
/// and a freshly opened one starts empty. The `configInitialized` check
/// keeps it idempotent, so calling it on an already-seeded profile is a
/// cheap no-op.
Future<void> ensureConfigInitialized(ConfigDataSource configDataSource) async {
  // Carry an existing single-user install's settings into the shared app
  // config before seeding any defaults.
  await configDataSource.migrateAppConfigFromProfile();
  if (!await configDataSource.configInitialized()) {
    await configDataSource.initializeConfig();
  }
}
