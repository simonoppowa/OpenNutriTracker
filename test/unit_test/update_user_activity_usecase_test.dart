import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:opennutritracker/core/data/data_source/user_activity_data_source.dart';
import 'package:opennutritracker/core/data/data_source/user_activity_dbo.dart';
import 'package:opennutritracker/core/data/data_source/user_data_source.dart';
import 'package:opennutritracker/core/data/dbo/physical_activity_dbo.dart';
import 'package:opennutritracker/core/data/dbo/user_dbo.dart';
import 'package:opennutritracker/core/data/repository/user_activity_repository.dart';
import 'package:opennutritracker/core/data/repository/user_repository.dart';
import 'package:opennutritracker/core/domain/entity/user_activity_entity.dart';
import 'package:opennutritracker/core/domain/usecase/get_user_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/update_user_activity_usecase.dart';
import 'package:opennutritracker/core/utils/calc/met_calc.dart';

import '../fixture/user_entity_fixtures.dart';
import '../helpers/fake_hive_db_provider.dart';
import '../helpers/hive_test_setup.dart';

final _running = PhysicalActivityDBO(
  '12150',
  'running',
  'running, general',
  8.0,
  const <String>[],
  PhysicalActivityTypeDBO.running,
);

void main() {
  final user = UserEntityFixtures.youngSedentaryMaleWantingToMaintainWeight;

  late Box<UserActivityDBO> activityBox;
  late Box<UserDBO> userBox;
  late UserActivityRepository userActivityRepository;
  late UpdateUserActivityUsecase usecase;

  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    registerHiveAdaptersOnce();
  });

  setUp(() async {
    Hive.init('.');
    activityBox = await Hive.openBox<UserActivityDBO>(
      'update_activity_activity_test',
    );
    userBox = await Hive.openBox<UserDBO>('update_activity_user_test');
    await activityBox.clear();
    await userBox.clear();

    final provider = FakeHiveDBProvider(
      userActivityBox: activityBox,
      userBox: userBox,
    );
    userActivityRepository = UserActivityRepository(
      UserActivityDataSource(provider),
    );
    final userRepository = UserRepository(UserDataSource(provider));
    await userRepository.updateUserData(user);

    usecase = UpdateUserActivityUsecase(
      userActivityRepository,
      GetUserUsecase(userRepository),
    );
  });

  tearDown(() async {
    await Hive.close();
    await Hive.deleteFromDisk();
  });

  Future<UserActivityEntity> storeActivity({
    required double duration,
    required double burnedKcal,
    double? userKcal,
    String? externalId,
    double? sourceReportedKcal,
  }) async {
    final dbo = UserActivityDBO(
      'activity-1',
      duration,
      burnedKcal,
      DateTime(2026, 5, 23, 7, 0),
      _running,
      userKcal: userKcal,
      externalId: externalId,
      sourceReportedKcal: sourceReportedKcal,
    );
    await activityBox.add(dbo);
    return UserActivityEntity.fromUserActivityDBO(dbo);
  }

  group('UpdateUserActivityUsecase on an imported workout', () {
    test(
      'the device figure is scaled with the duration, not replaced',
      () async {
        // 500 kcal reported by the watch, credited at 70%. Editing an hour
        // down to 40 minutes has to keep crediting the measurement — a MET
        // recompute would substitute a formula estimate off the compendium
        // value the importer never consulted in the first place.
        final activity = await storeActivity(
          duration: 60,
          burnedKcal: 350,
          userKcal: 350,
          externalId: 'record-1',
          sourceReportedKcal: 500,
        );

        final updated = await usecase.updateUserActivity(activity, 40);

        expect(updated, isNotNull);
        expect(updated!.duration, closeTo(40, 0.001));
        expect(updated.burnedKcal, closeTo(350 * 40 / 60, 0.001));
        expect(updated.userKcal, closeTo(350 * 40 / 60, 0.001));
        expect(
          updated.burnedKcal,
          isNot(
            closeTo(
              METCalc.getTotalBurnedKcal(
                user,
                activity.physicalActivityEntity,
                40,
              ),
              0.001,
            ),
          ),
        );
      },
    );

    test('the provenance fields survive the edit', () async {
      final activity = await storeActivity(
        duration: 60,
        burnedKcal: 350,
        userKcal: 350,
        externalId: 'record-1',
        sourceReportedKcal: 500,
      );

      final updated = await usecase.updateUserActivity(activity, 40);

      // What the device said does not change because the user corrected the
      // session's length, and the dedupe key has to stay put or the next
      // import files the workout a second time.
      expect(updated!.sourceReportedKcal, closeTo(500, 0.001));
      expect(updated.externalId, equals('record-1'));
    });

    test(
      'a zero-length record keeps its credit rather than dividing by it',
      () async {
        final activity = await storeActivity(
          duration: 0,
          burnedKcal: 350,
          userKcal: 350,
          externalId: 'record-1',
          sourceReportedKcal: 500,
        );

        final updated = await usecase.updateUserActivity(activity, 40);

        expect(updated!.burnedKcal, closeTo(350, 0.001));
      },
    );
  });

  group('UpdateUserActivityUsecase on a manually logged activity', () {
    test('burned kcal is still recomputed from MET', () async {
      final activity = await storeActivity(duration: 60, burnedKcal: 350);

      final updated = await usecase.updateUserActivity(activity, 40);

      expect(
        updated!.burnedKcal,
        closeTo(
          METCalc.getTotalBurnedKcal(user, activity.physicalActivityEntity, 40),
          0.001,
        ),
      );
    });
  });
}
