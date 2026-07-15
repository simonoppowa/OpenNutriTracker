import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:opennutritracker/core/data/data_source/user_data_source.dart';
import 'package:opennutritracker/core/data/dbo/user_dbo.dart';
import 'package:opennutritracker/core/data/dbo/user_gender_dbo.dart';
import 'package:opennutritracker/core/data/dbo/user_pal_dbo.dart';
import 'package:opennutritracker/core/data/dbo/user_weight_goal_dbo.dart';

import '../helpers/hive_test_setup.dart';
import '../helpers/fake_hive_db_provider.dart';

void main() {
  group('UserDataSource race-condition guarantees', () {
    setUp(() {
      TestWidgetsFlutterBinding.ensureInitialized();
      Hive.init('.');
      registerHiveAdaptersOnce();
    });

    tearDown(() async {
      await Hive.deleteFromDisk();
    });

    UserDBO buildUser({double weight = 70}) => UserDBO(
          birthday: DateTime(1990, 6, 15),
          heightCM: 165,
          weightKG: weight,
          gender: UserGenderDBO.female,
          goal: UserWeightGoalDBO.loseWeight,
          pal: UserPALDBO.sedentary,
        );

    test('getUserData throws StateError before any save (no dummy fallback)',
        () async {
      // Regression: the data source used to fall back to a hardcoded
      // 80 kg / 180 cm / male / active dummy when the box was empty. That
      // silently produced an inflated kcal budget for any caller that hit
      // the box during the onboarding race. The data source must now fail
      // loudly so callers can diagnose the race instead of corrupting calcs.
      final box = await Hive.openBox<UserDBO>('user_data_source_test_empty');
      final source = UserDataSource(FakeHiveDBProvider(userBox: box));

      expect(source.getUserData, throwsStateError);
    });

    test('saveUserData future does not resolve until the put has landed',
        () async {
      // Regression: saveUserData used to be `async` but did not await the
      // inner `_userBox.put(...)`. The returned Future resolved immediately
      // and the actual write was left in flight, so an awaiting caller (e.g.
      // OnboardingBloc.saveOnboardingData) could navigate away before the
      // user landed in the box.
      final box = await Hive.openBox<UserDBO>('user_data_source_test_save');
      final source = UserDataSource(FakeHiveDBProvider(userBox: box));

      await source.saveUserData(buildUser());

      // After the await, the data must be readable.
      final loaded = await source.getUserData();
      expect(loaded.weightKG, 70);
      expect(loaded.gender, UserGenderDBO.female);
    });
  });
}
