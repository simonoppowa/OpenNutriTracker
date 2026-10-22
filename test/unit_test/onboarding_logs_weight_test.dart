import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:opennutritracker/core/data/data_source/config_data_source.dart';
import 'package:opennutritracker/core/data/data_source/health/external_weight.dart';
import 'package:opennutritracker/core/data/data_source/health/health_service.dart';
import 'package:opennutritracker/core/data/data_source/user_data_source.dart';
import 'package:opennutritracker/core/data/data_source/weight_log_data_source.dart';
import 'package:opennutritracker/core/data/dbo/config_dbo.dart';
import 'package:opennutritracker/core/data/dbo/profile_dbo.dart';
import 'package:opennutritracker/core/data/dbo/user_dbo.dart';
import 'package:opennutritracker/core/data/dbo/weight_log_dbo.dart';
import 'package:opennutritracker/core/data/repository/config_repository.dart';
import 'package:opennutritracker/core/data/repository/health_import_repository.dart';
import 'package:opennutritracker/core/data/repository/user_repository.dart';
import 'package:opennutritracker/core/data/repository/weight_log_repository.dart';
import 'package:opennutritracker/core/domain/entity/app_theme_entity.dart';
import 'package:opennutritracker/core/domain/entity/body_weight_unit_entity.dart';
import 'package:opennutritracker/core/domain/usecase/add_config_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/add_user_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_config_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/import_weights_usecase.dart';
import 'package:opennutritracker/core/utils/daily_reminder_scheduler.dart';
import 'package:opennutritracker/core/utils/notification_service.dart';
import 'package:opennutritracker/features/onboarding/presentation/bloc/onboarding_bloc.dart';

import '../fixture/user_entity_fixtures.dart';
import '../helpers/fake_hive_db_provider.dart';
import '../helpers/hive_test_setup.dart';

class _FakeHealthService extends Fake implements HealthService {
  List<ExternalWeight> weights = const [];

  @override
  Future<List<ExternalWeight>> readWeights({
    required DateTime from,
    required DateTime to,
  }) async => weights;
}

/// The reminder is left off in this test, which cancels it; nothing to do.
class _NoNotifications extends NotificationService {
  @override
  Future<void> cancelDailyReminder() async {}
}

void main() {
  late Box<ConfigDBO> configBox;
  late Box<WeightLogDBO> weightLogBox;
  late Box<UserDBO> userBox;
  late Box<ProfileDBO> profileBox;
  late FakeHiveDBProvider provider;
  late ConfigDataSource configDataSource;
  late WeightLogRepository weightLogRepository;
  late UserRepository userRepository;
  late OnboardingBloc bloc;

  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);

  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    registerHiveAdaptersOnce();
  });

  setUp(() async {
    Hive.init('.');
    configBox = await Hive.openBox<ConfigDBO>('onboarding_weight_config');
    weightLogBox = await Hive.openBox<WeightLogDBO>('onboarding_weight_log');
    userBox = await Hive.openBox<UserDBO>('onboarding_weight_user');
    profileBox = await Hive.openBox<ProfileDBO>('onboarding_weight_profile');
    for (final box in [configBox, weightLogBox, userBox, profileBox]) {
      await box.clear();
    }
    // Created ten days before onboarding finished, as the default profile
    // is on a first launch that does not go straight through onboarding.
    await profileBox.put(
      'profile-a',
      ProfileDBO(
        id: 'profile-a',
        name: '',
        createdAt: now.subtract(const Duration(days: 10)),
        boxSuffix: '',
      ),
    );
    provider = FakeHiveDBProvider(
      activeProfileId: 'profile-a',
      configBox: configBox,
      weightLogBox: weightLogBox,
      userBox: userBox,
      profileBox: profileBox,
    );
    configDataSource = ConfigDataSource(provider);
    await configDataSource.initializeConfig();
    final configRepository = ConfigRepository(configDataSource);
    weightLogRepository = WeightLogRepository(WeightLogDataSource(provider));
    userRepository = UserRepository(UserDataSource(provider));
    bloc = OnboardingBloc(
      AddUserUsecase(userRepository),
      AddConfigUsecase(configRepository),
      GetConfigUsecase(configRepository),
      DailyReminderScheduler(configRepository, _NoNotifications()),
      weightLogRepository: weightLogRepository,
    );
  });

  tearDown(() async {
    await bloc.close();
    await Hive.close();
    await Hive.deleteFromDisk();
  });

  Future<void> onboard() => bloc.saveOnboardingData(
    UserEntityFixtures.youngSedentaryMaleWantingToMaintainWeight,
    false,
    false,
    BodyWeightUnit.kg,
    false,
    appTheme: AppThemeEntity.system,
    foodSourceToggles: const {},
    dailyReminderEnabled: false,
    reminderLocale: const Locale('en'),
    useMaterialYou: true,
    accentColor: null,
  );

  test('onboarding logs its weight as today\'s manual entry', () async {
    await onboard();

    final entry = await weightLogRepository.getEntry(today);
    expect(entry!.weightKg, equals(80.0));
    expect(entry.isImported, isFalse);
  });

  test(
    'a reading from between profile creation and onboarding does not '
    'replace the onboarding weight',
    () async {
      await onboard();
      await configDataSource.setConfigHealthWeightImportEnabled(true);
      final healthService = _FakeHealthService()
        ..weights = [
          ExternalWeight(
            id: 'scale-1',
            measuredAt: now.subtract(const Duration(days: 5)),
            weightKg: 84.0,
            sourceAppName: 'Scale',
          ),
        ];
      final usecase = ImportWeightsUsecase(
        HealthImportRepository(healthService),
        ConfigRepository(configDataSource),
        weightLogRepository,
        userRepository,
        provider,
      );

      expect(await usecase.importNow(), equals(1));

      expect((await userRepository.getUserData()).weightKG, equals(80.0));
    },
  );
}
