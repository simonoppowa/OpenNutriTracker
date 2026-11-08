import 'dart:async';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/data/repository/config_repository.dart';
import 'package:opennutritracker/core/data/repository/user_repository.dart';
import 'package:opennutritracker/core/domain/entity/app_theme_entity.dart';
import 'package:opennutritracker/core/domain/entity/body_weight_unit_entity.dart';
import 'package:opennutritracker/core/domain/entity/config_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_gender_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_pal_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_weight_goal_entity.dart';
import 'package:opennutritracker/core/domain/usecase/add_config_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/add_user_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_config_usecase.dart';
import 'package:opennutritracker/core/utils/daily_reminder_scheduler.dart';
import 'package:opennutritracker/core/utils/notification_service.dart';
import 'package:opennutritracker/features/onboarding/presentation/bloc/onboarding_bloc.dart';

import '../helpers/fake_notification_platform.dart';
import '../helpers/recording_add_weight_log_usecase.dart';

/// The shared config, reduced to what the reminder reads and writes. Every
/// other onboarding write is accepted and recorded by name.
class _Config implements ConfigRepository {
  _Config({required this.notificationsEnabled});

  bool notificationsEnabled;
  final writes = <Symbol>[];

  /// When set, the next [getConfig] reads the config at once but holds the
  /// answer until this completes — a start-up refresh caught mid-flight.
  Completer<void>? gate;

  @override
  Future<ConfigEntity> getConfig() async {
    final read = ConfigEntity(
      true,
      true,
      false,
      AppThemeEntity.system,
      notificationsEnabled: notificationsEnabled,
    );
    final pending = gate;
    gate = null;
    if (pending != null) await pending.future;
    return read;
  }

  /// When set, saving "on" fails once and leaves the config as it was.
  bool failSavingOn = false;

  /// When set, saving "off" fails once and leaves the config as it was.
  bool failSavingOff = false;

  /// When set, saving "on" reaches the shared box, which the flag is read
  /// from, and then fails on the profile box.
  bool failAfterSavingOn = false;

  @override
  Future<void> setNotificationsEnabled(bool enabled) async {
    if (enabled && failSavingOn) {
      failSavingOn = false;
      throw StateError('config write failed');
    }
    if (!enabled && failSavingOff) {
      failSavingOff = false;
      throw StateError('config write failed');
    }
    notificationsEnabled = enabled;
    if (enabled && failAfterSavingOn) {
      failAfterSavingOn = false;
      throw StateError('profile config write failed');
    }
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    writes.add(invocation.memberName);
    return Future<void>.value();
  }
}

class _Users implements UserRepository {
  @override
  Future<void> updateUserData(UserEntity _) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeNotificationPlatform platform;

  setUp(() => (platform = FakeNotificationPlatform()).install());
  tearDown(() => platform.uninstall());

  ({OnboardingBloc bloc, DailyReminderScheduler scheduler}) build(
    _Config config,
  ) {
    final scheduler = DailyReminderScheduler(config, NotificationService());
    final bloc = OnboardingBloc(
      AddUserUsecase(_Users()),
      AddConfigUsecase(config),
      GetConfigUsecase(config),
      RecordingAddWeightLogUsecase(),
      scheduler,
    );
    addTearDown(bloc.close);
    return (bloc: bloc, scheduler: scheduler);
  }

  Future<void> finishOnboarding(
    OnboardingBloc bloc, {
    required bool dailyReminderEnabled,
  }) => bloc.saveOnboardingData(
    UserEntity(
      birthday: DateTime(1990, 6, 15),
      heightCM: 165,
      weightKG: 70,
      gender: UserGenderEntity.female,
      goal: UserWeightGoalEntity.loseWeight,
      pal: UserPALEntity.sedentary,
    ),
    false,
    false,
    BodyWeightUnit.kg,
    false,
    appTheme: AppThemeEntity.system,
    foodSourceToggles: const {},
    dailyReminderEnabled: dailyReminderEnabled,
    reminderLocale: const Locale('en'),
    useMaterialYou: true,
    accentColor: null,
  );

  group('the onboarding reminder goes through the scheduler (#1389)', () {
    test(
      'turning it on while the start-up refresh runs ends with an alarm',
      () async {
        final config = _Config(notificationsEnabled: false);
        final (:bloc, :scheduler) = build(config);

        // Start-up has read "off" and is still on its way to cancel when
        // onboarding turns the reminder on.
        final gate = config.gate = Completer<void>();
        final refresh = scheduler.refresh(locale: const Locale('en'));
        await pumpEventQueue();
        final save = finishOnboarding(bloc, dailyReminderEnabled: true);
        await pumpEventQueue();
        gate.complete();
        await Future.wait([refresh, save]);

        expect(platform.pending.keys, [0]);
        expect(config.notificationsEnabled, isTrue);
      },
    );

    test('leaving it off saves off and cancels a pending alarm', () async {
      // Onboarding a second profile, with the reminder already set.
      final config = _Config(notificationsEnabled: true);
      final (:bloc, :scheduler) = build(config);
      await scheduler.refresh(locale: const Locale('en'));
      expect(platform.pending, isNotEmpty);

      await finishOnboarding(bloc, dailyReminderEnabled: false);

      expect(platform.pending, isEmpty);
      expect(config.notificationsEnabled, isFalse);
    });

    test(
      'a schedule that fails leaves it off and onboarding finishes',
      () async {
        final config = _Config(notificationsEnabled: false);
        final (:bloc, scheduler: _) = build(config);

        platform.failNextSchedule = true;
        await finishOnboarding(bloc, dailyReminderEnabled: true);

        expect(platform.pending, isEmpty);
        expect(config.notificationsEnabled, isFalse);
        expect(
          config.writes,
          contains(#setIsDemoData),
          reason: 'the writes after the reminder must still happen',
        );
      },
    );

    test('saving "on" that fails leaves no alarm behind', () async {
      final config = _Config(notificationsEnabled: false)..failSavingOn = true;
      final (:bloc, scheduler: _) = build(config);

      await finishOnboarding(bloc, dailyReminderEnabled: true);

      // Settings will read off, so nothing may fire.
      expect(config.notificationsEnabled, isFalse);
      expect(platform.pending, isEmpty);
      expect(config.writes, contains(#setIsDemoData));
    });

    test('saving "on" that half-fails keeps the alarm it reads', () async {
      final config = _Config(notificationsEnabled: false)
        ..failAfterSavingOn = true;
      final (:bloc, scheduler: _) = build(config);

      await finishOnboarding(bloc, dailyReminderEnabled: true);

      // Settings will read on, so the alarm must be there.
      expect(config.notificationsEnabled, isTrue);
      expect(platform.pending.keys, [0]);
      expect(config.writes, contains(#setIsDemoData));
    });

    test('a stale alarm goes even when saving "off" fails', () async {
      // Reads off, but a delete-all whose cancel failed left the alarm.
      final config = _Config(notificationsEnabled: true);
      final (:bloc, :scheduler) = build(config);
      await scheduler.refresh(locale: const Locale('en'));
      config
        ..notificationsEnabled = false
        ..failSavingOff = true;

      await finishOnboarding(bloc, dailyReminderEnabled: false);

      expect(platform.pending, isEmpty);
      expect(config.notificationsEnabled, isFalse);
      expect(config.writes, contains(#setIsDemoData));
    });

    test('a stale alarm a cancel cannot clear leaves it on', () async {
      // Reads off, but a delete-all whose cancel failed left the alarm.
      final config = _Config(notificationsEnabled: true);
      final (:bloc, :scheduler) = build(config);
      await scheduler.refresh(locale: const Locale('en'));
      config.notificationsEnabled = false;

      platform.failNextCancel = true;
      await finishOnboarding(bloc, dailyReminderEnabled: false);

      expect(platform.pending.keys, [0]);
      expect(config.notificationsEnabled, isTrue);
      expect(config.writes, contains(#setIsDemoData));
    });

    test('a cancel that fails leaves it on, as the alarm still is', () async {
      // Onboarding a second profile, with the reminder already set.
      final config = _Config(notificationsEnabled: true);
      final (:bloc, :scheduler) = build(config);
      await scheduler.refresh(locale: const Locale('en'));

      platform.failNextCancel = true;
      await finishOnboarding(bloc, dailyReminderEnabled: false);

      expect(platform.pending.keys, [0]);
      expect(config.notificationsEnabled, isTrue);
      expect(config.writes, contains(#setIsDemoData));
    });
  });
}
