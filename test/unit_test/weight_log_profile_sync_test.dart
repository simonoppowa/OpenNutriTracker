import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/data/repository/user_repository.dart';
import 'package:opennutritracker/core/data/repository/weight_log_repository.dart';
import 'package:opennutritracker/core/domain/entity/user_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_gender_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_pal_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_weight_goal_entity.dart';
import 'package:opennutritracker/core/domain/entity/weight_log_entity.dart';
import 'package:opennutritracker/core/domain/usecase/add_weight_log_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/delete_weight_log_usecase.dart';

class _FakeWeightLogRepository extends Fake implements WeightLogRepository {
  final entries = <DateTime, WeightLogEntity>{};

  @override
  Future<void> addEntry(WeightLogEntity entry) async =>
      entries[entry.date] = entry;

  @override
  Future<void> deleteEntry(DateTime date) async => entries.remove(date);

  @override
  Future<List<WeightLogEntity>> getAllEntries() async => [...entries.values];
}

class _FakeUserRepository extends Fake implements UserRepository {
  UserEntity user = UserEntity(
    birthday: DateTime(1990),
    heightCM: 180,
    weightKG: 80,
    gender: UserGenderEntity.male,
    goal: UserWeightGoalEntity.loseWeight,
    pal: UserPALEntity.active,
  );
  var updates = 0;

  @override
  Future<UserEntity> getUserData() async => user;

  @override
  Future<void> updateUserData(UserEntity userEntity) async {
    user = userEntity;
    updates++;
  }
}

void main() {
  late _FakeWeightLogRepository log;
  late _FakeUserRepository users;
  late List<double> changes;
  late AddWeightLogUsecase add;
  late DeleteWeightLogUsecase delete;
  final today = DateTime.now();
  DateTime daysAgo(int days) =>
      DateTime(today.year, today.month, today.day - days);

  setUp(() {
    log = _FakeWeightLogRepository();
    users = _FakeUserRepository();
    changes = [];
    add = AddWeightLogUsecase(
      log,
      users,
      onProfileWeightChanged: (user) async => changes.add(user.weightKG),
    );
    delete = DeleteWeightLogUsecase(
      log,
      users,
      onProfileWeightChanged: (user) async => changes.add(user.weightKG),
    );
  });

  WeightLogEntity entry(int daysBack, double kg) =>
      WeightLogEntity(date: daysAgo(daysBack), weightKg: kg);

  test('a new latest entry sets the profile weight', () async {
    await add.addEntry(entry(0, 79.4));

    expect(users.user.weightKG, 79.4);
    expect(changes, [79.4]);
  });

  test('a backdated latest entry sets it too', () async {
    await log.addEntry(entry(10, 81));

    await add.addEntry(entry(3, 80.2));

    expect(users.user.weightKG, 80.2);
  });

  test('an older backdated entry changes nothing', () async {
    await add.addEntry(entry(1, 79.8));
    changes.clear();
    final updatesBefore = users.updates;

    await add.addEntry(entry(5, 82));

    expect(users.user.weightKG, 79.8);
    expect(users.updates, updatesBefore);
    expect(changes, isEmpty);
  });

  test('editing the latest entry updates the profile weight', () async {
    await add.addEntry(entry(0, 79.4));

    await add.addEntry(entry(0, 79.1));

    expect(users.user.weightKG, 79.1);
  });

  test('deleting the latest entry falls back to the one before', () async {
    await add.addEntry(entry(4, 80.5));
    await add.addEntry(entry(0, 79.4));

    await delete.deleteEntry(daysAgo(0));

    expect(users.user.weightKG, 80.5);
    expect(changes.last, 80.5);
  });

  test('deleting an older entry changes nothing', () async {
    await add.addEntry(entry(4, 80.5));
    await add.addEntry(entry(0, 79.4));
    changes.clear();

    await delete.deleteEntry(daysAgo(4));

    expect(users.user.weightKG, 79.4);
    expect(changes, isEmpty);
  });

  test('deleting the last entry keeps the profile weight', () async {
    await add.addEntry(entry(0, 79.4));

    await delete.deleteEntry(daysAgo(0));

    expect(users.user.weightKG, 79.4);
  });
}
