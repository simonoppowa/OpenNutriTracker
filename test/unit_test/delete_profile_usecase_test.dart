import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/data/repository/profile_repository.dart';
import 'package:opennutritracker/core/domain/entity/profile_entity.dart';
import 'package:opennutritracker/core/domain/usecase/delete_profile_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/export_meal_intake_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/switch_profile_usecase.dart';
import 'package:opennutritracker/core/utils/hive_db_provider.dart';

/// Every step the deletion takes, in order, across the fakes below.
final _steps = <String>[];

ProfileEntity _profile(String id) => ProfileEntity(
  id: id,
  name: id,
  createdAt: DateTime(2026, 1, 1),
  boxSuffix: 'suffix_$id',
);

class _FakeProfileRepository extends Fake implements ProfileRepository {
  final profiles = [_profile('a'), _profile('b')];

  @override
  List<ProfileEntity> getAllProfiles() => profiles;

  @override
  Future<void> deleteProfile(String id) async => _steps.add('unregister $id');
}

class _FakeHiveDBProvider extends HiveDBProvider {
  @override
  String activeProfileId = 'a';

  @override
  Future<void> deleteProfileBoxes(String boxSuffix) async =>
      _steps.add('delete boxes $boxSuffix');
}

class _FakeSwitchProfileUsecase extends Fake implements SwitchProfileUsecase {
  @override
  Future<void> switchProfile(ProfileEntity profile) async =>
      _steps.add('switch to ${profile.id}');
}

class _FakeExportMealIntakeUsecase extends Fake
    implements ExportMealIntakeUsecase {
  @override
  Future<void> forgetProfile(String profileId) async =>
      _steps.add('forget $profileId');
}

void main() {
  late DeleteProfileUsecase usecase;

  setUp(() {
    _steps.clear();
    usecase = DeleteProfileUsecase(
      _FakeProfileRepository(),
      _FakeHiveDBProvider(),
      _FakeSwitchProfileUsecase(),
      _FakeExportMealIntakeUsecase(),
    );
  });

  // #1393 review: the exported Health records are addressed by the diary the
  // deleted box-set takes with it, so they are read out before anything
  // moves.
  test('an inactive profile\'s health records are read out first', () async {
    await usecase.deleteProfile(_profile('b'));

    expect(_steps, ['forget b', 'delete boxes suffix_b', 'unregister b']);
  });

  test('the active profile is read out before switching away', () async {
    await usecase.deleteProfile(_profile('a'));

    expect(_steps, [
      'forget a',
      'switch to b',
      'delete boxes suffix_a',
      'unregister a',
    ]);
  });
}
