import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:opennutritracker/core/data/data_source/user_activity_dbo.dart';
import 'package:opennutritracker/core/data/dbo/config_dbo.dart';
import 'package:opennutritracker/core/data/dbo/fasting_session_dbo.dart';
import 'package:opennutritracker/core/data/dbo/intake_dbo.dart';
import 'package:opennutritracker/core/data/dbo/tracked_day_dbo.dart';
import 'package:opennutritracker/core/data/dbo/user_dbo.dart';
import 'package:opennutritracker/core/data/dbo/water_intake_dbo.dart';
import 'package:opennutritracker/core/data/dbo/weight_log_dbo.dart';
import 'package:opennutritracker/core/domain/usecase/delete_all_user_data_usecase.dart';
import 'package:opennutritracker/core/utils/ai_credential_storage.dart';
import 'package:opennutritracker/core/utils/hive_db_provider.dart';

import '../helpers/hive_test_setup.dart';

/// In-memory stand-in for the platform keystore. The AI credentials live
/// there rather than in Hive, which is the whole reason #892 existed: a wipe
/// written against the box list could not see them.
class _MemoryStorage implements FlutterSecureStorage {
  final store = <String, String>{};

  @override
  Future<String?> read({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async => store[key];

  @override
  Future<void> write({
    required String key,
    required String? value,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (value == null) {
      store.remove(key);
    } else {
      store[key] = value;
    }
  }

  @override
  Future<void> delete({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async => store.remove(key);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Hands the usecase pre-opened, unencrypted boxes so it can run without the
/// Hive/encryption bootstrap. The shared content libraries are deliberately
/// left unset — the usecase must never reach for them, and a `late final`
/// that was never assigned throws loudly if it does.
class _TestHiveDBProvider extends HiveDBProvider {
  final Box<ConfigDBO> config;
  final Box<IntakeDBO> intake;
  final Box<UserActivityDBO> activity;
  final Box<UserDBO> user;
  final Box<TrackedDayDBO> trackedDay;
  final Box<WeightLogDBO> weight;
  final Box<WaterIntakeDBO> water;
  final Box<FastingSessionDBO> fasting;
  final Box<ConfigDBO> sharedAppConfig;

  _TestHiveDBProvider({
    required this.config,
    required this.intake,
    required this.activity,
    required this.user,
    required this.trackedDay,
    required this.weight,
    required this.water,
    required this.fasting,
    required this.sharedAppConfig,
  });

  @override
  Box<ConfigDBO> get configBox => config;
  @override
  Box<IntakeDBO> get intakeBox => intake;
  @override
  Box<UserActivityDBO> get userActivityBox => activity;
  @override
  Box<UserDBO> get userBox => user;
  @override
  Box<TrackedDayDBO> get trackedDayBox => trackedDay;
  @override
  Box<WeightLogDBO> get weightLogBox => weight;
  @override
  Box<WaterIntakeDBO> get waterIntakeBox => water;
  @override
  Box<FastingSessionDBO> get fastingBox => fasting;
  @override
  Box<ConfigDBO> get appConfigBox => sharedAppConfig;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _TestHiveDBProvider provider;
  late _MemoryStorage backing;
  late AiCredentialStorage credentials;
  late DeleteAllUserDataUsecase sut;
  late Box<ConfigDBO> configBox;
  late Box<ConfigDBO> appConfigBox;

  setUp(() async {
    Hive.init('.');
    registerHiveAdaptersOnce();
    final tag = DateTime.now().microsecondsSinceEpoch;

    configBox = await Hive.openBox<ConfigDBO>('wipe_config_$tag');
    appConfigBox = await Hive.openBox<ConfigDBO>('wipe_app_config_$tag');

    provider = _TestHiveDBProvider(
      config: configBox,
      intake: await Hive.openBox<IntakeDBO>('wipe_intake_$tag'),
      activity: await Hive.openBox<UserActivityDBO>('wipe_activity_$tag'),
      user: await Hive.openBox<UserDBO>('wipe_user_$tag'),
      trackedDay: await Hive.openBox<TrackedDayDBO>('wipe_tracked_$tag'),
      weight: await Hive.openBox<WeightLogDBO>('wipe_weight_$tag'),
      water: await Hive.openBox<WaterIntakeDBO>('wipe_water_$tag'),
      fasting: await Hive.openBox<FastingSessionDBO>('wipe_fasting_$tag'),
      sharedAppConfig: appConfigBox,
    );

    backing = _MemoryStorage();
    credentials = AiCredentialStorage(backing);
    sut = DeleteAllUserDataUsecase(provider, credentials);
  });

  tearDown(() async {
    await Hive.deleteFromDisk();
  });

  test('takes the AI credentials with it', () async {
    // #892. Every one of these survived the wipe, so a reset landed on
    // onboarding with the provider still selected, still enabled, and a
    // working paid key behind it.
    await credentials.writeApiKey('sk-ant', provider: AiProvider.anthropic);
    await credentials.setActiveProvider(AiProvider.openrouter);
    await credentials.writeApiKey('sk-or', provider: AiProvider.openrouter);
    await credentials.setTermsAccepted(true);
    await credentials.setEnabled(true);
    expect(await credentials.isEnabled(), isTrue, reason: 'setup');

    await sut.deleteAll();

    expect(backing.store, isEmpty);
    expect(
      await credentials.readApiKey(provider: AiProvider.anthropic),
      isNull,
    );
    expect(await credentials.isEnabled(), isFalse);
    // The agreement is a record of consent, not a setting. #836 already
    // refused to let one outlive the credential it authorised; a wipe is the
    // strongest case of that.
    expect(await credentials.hasAcceptedTerms(), isFalse);
  });

  test('takes the address of a server the user runs', () async {
    // The endpoint is the one credential that is not a key, and it names a
    // machine on someone's own network. #732 put it in this store so it
    // could not be left behind on its own.
    await credentials.setActiveProvider(AiProvider.ownServer);
    await credentials.writeOwnServerConfiguration(
      endpoint: 'http://192.168.1.4:11434',
      model: 'llama3.2',
      provider: AiProvider.ownServer,
    );
    expect(
      await credentials.readEndpoint(provider: AiProvider.ownServer),
      isNotNull,
      reason: 'setup',
    );

    await sut.deleteAll();

    expect(
      await credentials.readEndpoint(provider: AiProvider.ownServer),
      isNull,
    );
    expect(await credentials.readModel(provider: AiProvider.ownServer), isNull);
  });

  test('still clears the active profile boxes', () async {
    await configBox.put('ConfigKey', ConfigDBO.empty());

    await sut.deleteAll();

    expect(configBox.isEmpty, isTrue);
  });

  test('leaves the shared app settings alone', () async {
    // The exclusions #892 warned against widening. App-wide settings are
    // shared by every profile, so a per-profile reset must not touch them —
    // the AI store is the single deliberate exception, and it is the one
    // thing here the confirmation dialog names.
    await appConfigBox.put('ConfigKey', ConfigDBO.empty());

    await sut.deleteAll();

    expect(appConfigBox.isNotEmpty, isTrue);
  });
}
