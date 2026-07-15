import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:logging/logging.dart';
import 'package:opennutritracker/core/data/dbo/profile_dbo.dart';
import 'package:opennutritracker/core/utils/hive_db_provider.dart';

/// Reads and writes the profile registry. The registry is a single global
/// box keyed by profile id; it never changes when the active profile
/// changes, so it is always available straight off the provider.
class ProfileDataSource {
  final _log = Logger('ProfileDataSource');
  final HiveDBProvider _db;

  ProfileDataSource(this._db);

  Box<ProfileDBO> get _profileBox => _db.profileBox;

  List<ProfileDBO> getAllProfiles() => _profileBox.values.toList();

  ProfileDBO? getProfile(String id) => _profileBox.get(id);

  Future<void> saveProfile(ProfileDBO profile) async {
    _log.fine('Saving profile ${profile.id}');
    await _profileBox.put(profile.id, profile);
  }

  Future<void> deleteProfile(String id) async {
    _log.fine('Deleting profile $id');
    await _profileBox.delete(id);
  }
}
