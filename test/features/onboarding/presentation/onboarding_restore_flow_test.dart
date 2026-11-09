import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/domain/entity/app_theme_entity.dart';
import 'package:opennutritracker/core/domain/entity/body_weight_unit_entity.dart';
import 'package:opennutritracker/core/domain/entity/config_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_gender_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_weight_goal_entity.dart';
import 'package:opennutritracker/core/domain/usecase/add_config_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/add_user_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/add_weight_log_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_config_usecase.dart';
import 'package:opennutritracker/core/utils/ai_credential_storage.dart';
import 'package:opennutritracker/core/utils/daily_reminder_scheduler.dart';
import 'package:opennutritracker/core/utils/locator.dart';
import 'package:opennutritracker/core/utils/navigation_options.dart';
import 'package:opennutritracker/features/add_meal/domain/usecase/run_ai_endpoint_probe_usecase.dart';
import 'package:opennutritracker/features/diary/presentation/bloc/calendar_day_bloc.dart';
import 'package:opennutritracker/features/diary/presentation/bloc/diary_bloc.dart';
import 'package:opennutritracker/features/home/presentation/bloc/home_bloc.dart';
import 'package:opennutritracker/features/onboarding/domain/usecase/restore_backup_usecase.dart';
import 'package:opennutritracker/features/onboarding/onboarding_screen.dart';
import 'package:opennutritracker/features/onboarding/presentation/bloc/onboarding_bloc.dart';
import 'package:opennutritracker/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:opennutritracker/features/settings/presentation/bloc/custom_meals_bloc.dart';
import 'package:opennutritracker/features/recipes/presentation/bloc/recipes_bloc.dart';
import 'package:opennutritracker/features/settings/domain/export_import_failure.dart';
import 'package:opennutritracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:opennutritracker/generated/l10n.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Metric units, so the height and weight pages show one field each
/// whatever the test machine's locale.
class _MetricConfig extends Fake implements ConfigEntity {
  @override
  bool get usesImperialHeightUnits => false;

  @override
  BodyWeightUnit get bodyWeightUnit => BodyWeightUnit.kg;

  @override
  bool get usesImperialFoodUnits => false;
}

/// Answers the unit seeding with a stored metric choice and the
/// food-source seeding with "nothing stored yet".
class _FirstRunConfig extends Fake implements GetConfigUsecase {
  @override
  Future<bool> hasExplicitUnitPreferences() async => true;

  @override
  Future<ConfigEntity> getConfig() async => _MetricConfig();

  @override
  Future<bool> hasExplicitFoodSourceToggles() async => false;
}

class _UnusedAddUser extends Fake implements AddUserUsecase {}

class _UnusedAddConfig extends Fake implements AddConfigUsecase {}

class _UnusedAddWeightLog extends Fake implements AddWeightLogUsecase {}

class _UnusedScheduler extends Fake implements DailyReminderScheduler {}

/// Records the save instead of writing it. The writes themselves are
/// covered against real Hive boxes in `restore_backup_usecase_test.dart`.
class _RecordingOnboardingBloc extends OnboardingBloc {
  _RecordingOnboardingBloc(this.log)
    : super(
        _UnusedAddUser(),
        _UnusedAddConfig(),
        _FirstRunConfig(),
        _UnusedAddWeightLog(),
        _UnusedScheduler(),
      );

  final List<String> log;
  UserEntity? savedUser;

  @override
  Future<void> saveOnboardingData(
    UserEntity userEntity,
    bool hasAcceptedDataCollection,
    bool heightImperial,
    BodyWeightUnit bodyWeightUnit,
    bool foodImperial, {
    required AppThemeEntity appTheme,
    required Map<String, bool> foodSourceToggles,
    required bool dailyReminderEnabled,
    required Locale reminderLocale,
    required bool useMaterialYou,
    required int? accentColor,
  }) async {
    savedUser = userEntity;
    log.add('save');
  }
}

class _FakeRestore extends Fake implements RestoreBackupUsecase {
  _FakeRestore(this.log);

  final List<String> log;
  RestoreBackupResult result = const RestoreBackupResult(
    RestoreBackupOutcome.restored,
  );

  @override
  Future<RestoreBackupResult> restore() async {
    log.add('restore');
    return result;
  }

  @override
  Future<void> syncTodayGoals() async => log.add('syncTodayGoals');
}

/// Nothing configured. The Other options page reads this as soon as it is
/// built, which happens once the goal page next to it is on screen.
class _NoAiCredentials extends Fake implements AiCredentialStorage {
  @override
  Future<AiAssistSummary> readSummary() async =>
      const AiAssistSummary(provider: null, configured: false, enabled: false);

  @override
  Future<bool> isHidden() async => false;
}

class _UnusedProbeRunner extends Fake implements AiEndpointProbeRunner {}

class _NoopHomeBloc extends Fake implements HomeBloc {
  @override
  void add(HomeEvent event) {}
}

class _NoopDiaryBloc extends Fake implements DiaryBloc {
  @override
  void add(DiaryEvent event) {}
}

class _NoopCalendarDayBloc extends Fake implements CalendarDayBloc {
  @override
  void add(CalendarDayEvent event) {}
}

class _NoopProfileBloc extends Fake implements ProfileBloc {
  @override
  void add(ProfileEvent event) {}
}

class _NoopRecipesBloc extends Fake implements RecipesBloc {
  @override
  void add(RecipesEvent event) {}
}

class _NoopCustomMealsBloc extends Fake implements CustomMealsBloc {
  @override
  void add(CustomMealsEvent event) {}
}

class _NoopSettingsBloc extends Fake implements SettingsBloc {
  @override
  void add(SettingsEvent event) {}
}

const _homeStandIn = 'home stand-in';

Finder _byId(String identifier) => find.byWidgetPredicate(
  (widget) => widget is Semantics && widget.properties.identifier == identifier,
);

void main() {
  late List<String> log;
  late _RecordingOnboardingBloc bloc;
  late _FakeRestore restore;

  setUpAll(() {
    PackageInfo.setMockInitialValues(
      appName: 'OpenNutriTracker',
      packageName: 'com.example.opennutritracker',
      version: '1.2.0',
      buildNumber: '46',
      buildSignature: '',
    );
  });

  setUp(() {
    log = [];
    bloc = _RecordingOnboardingBloc(log);
    restore = _FakeRestore(log);
    locator
      ..registerSingleton<OnboardingBloc>(bloc)
      ..registerSingleton<RestoreBackupUsecase>(restore)
      ..registerSingleton<AiCredentialStorage>(_NoAiCredentials())
      ..registerSingleton<AiEndpointProbeRunner>(_UnusedProbeRunner())
      ..registerSingleton<HomeBloc>(_NoopHomeBloc())
      ..registerSingleton<DiaryBloc>(_NoopDiaryBloc())
      ..registerSingleton<CalendarDayBloc>(_NoopCalendarDayBloc())
      ..registerSingleton<ProfileBloc>(_NoopProfileBloc())
      ..registerSingleton<RecipesBloc>(_NoopRecipesBloc())
      ..registerSingleton<CustomMealsBloc>(_NoopCustomMealsBloc())
      ..registerSingleton<SettingsBloc>(_NoopSettingsBloc());
  });

  tearDown(() async {
    await bloc.close();
    await locator.reset();
  });

  Future<void> pumpOnboarding(WidgetTester tester) async {
    // Tall enough that each page fits without scrolling.
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [
          S.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: S.supportedLocales,
        home: const OnboardingScreen(),
        routes: {
          NavigationOptions.mainRoute: (_) =>
              const Scaffold(body: Text(_homeStandIn)),
        },
      ),
    );
    // The bloc's load runs outside the fake clock; let it land before
    // settling, or the loading spinner never stops.
    if (bloc.state is! OnboardingLoadedState) {
      await tester.runAsync(
        () => bloc.stream
            .firstWhere((state) => state is OnboardingLoadedState)
            .timeout(const Duration(seconds: 5)),
      );
    }
    await tester.pumpAndSettle();
  }

  Future<void> tapId(WidgetTester tester, String identifier) async {
    final target = _byId(identifier).hitTestable();
    await tester.ensureVisible(target.first);
    await tester.tap(target.first);
    await tester.pumpAndSettle();
  }

  /// The footer button of the page on screen.
  Future<void> tapFooter(WidgetTester tester) =>
      tapId(tester, 'onboarding-button');

  Future<void> acceptPolicy(WidgetTester tester) =>
      tapId(tester, 'onboarding-checkbox-privacy');

  Future<void> tapRestore(WidgetTester tester) =>
      tapId(tester, 'onboarding-restore-backup');

  /// About you, then height and weight, then activity, then the goal: the
  /// body profile a backup does not carry.
  Future<void> enterBodyProfile(WidgetTester tester) async {
    await tapId(tester, 'onboarding-gender-genderMale');
    await tapId(tester, 'onboarding-birthday-field');
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    await tapFooter(tester);

    await tester.enterText(
      find.descendant(
        of: _byId('onboarding-height-field').first,
        matching: find.byType(TextFormField),
      ),
      '180',
    );
    await tester.enterText(
      find.descendant(
        of: _byId('onboarding-weight-field').first,
        matching: find.byType(TextFormField),
      ),
      '78',
    );
    await tester.pumpAndSettle();
    await tapFooter(tester);

    await tapId(tester, 'onboarding-activity-active');
    await tapFooter(tester);

    await tapId(tester, 'onboarding-goal-lose');
  }

  testWidgets('the first page offers the restore, with a Semantics '
      'identifier', (tester) async {
    await pumpOnboarding(tester);

    expect(_byId('onboarding-restore-backup'), findsOneWidget);
    expect(find.text('Restore from backup'), findsOneWidget);
  });

  testWidgets('without the privacy policy the restore explains itself and '
      'opens no picker', (tester) async {
    await pumpOnboarding(tester);

    await tapRestore(tester);

    expect(
      find.text('Accept the privacy policy to restore a backup'),
      findsOneWidget,
    );
    expect(log, isEmpty);
  });

  testWidgets('a restore leads through the body profile only, then '
      'finishes on the goal page and lands on Home', (tester) async {
    await pumpOnboarding(tester);
    await acceptPolicy(tester);

    await tapRestore(tester);

    expect(log, ['restore']);
    expect(
      find.text(
        'Backup restored. Enter your body details to finish setting up.',
      ),
      findsOneWidget,
    );
    expect(_byId('onboarding-gender-genderMale').hitTestable(), findsWidgets);

    await enterBodyProfile(tester);

    // The goal page's button finishes onboarding: the other options keep
    // their defaults and the overview, which would ignore the restored goal
    // settings, is skipped.
    expect(
      find.descendant(
        of: _byId('onboarding-button').hitTestable(),
        matching: find.text('START'),
      ),
      findsOneWidget,
    );
    await tapFooter(tester);

    expect(log, ['restore', 'save', 'syncTodayGoals']);
    expect(bloc.savedUser?.gender, UserGenderEntity.male);
    expect(bloc.savedUser?.heightCM, 180);
    expect(bloc.savedUser?.weightKG, 78);
    expect(bloc.savedUser?.goal, UserWeightGoalEntity.loseWeight);
    expect(find.text(_homeStandIn), findsOneWidget);
  });

  testWidgets('without a restore the goal page still moves on to the other '
      'options', (tester) async {
    await pumpOnboarding(tester);
    await acceptPolicy(tester);
    await tapFooter(tester);

    await enterBodyProfile(tester);

    expect(
      find.descendant(
        of: _byId('onboarding-button').hitTestable(),
        matching: find.text('NEXT'),
      ),
      findsOneWidget,
    );
    await tapFooter(tester);
    expect(log, isEmpty);
    expect(find.text(_homeStandIn), findsNothing);
  });

  testWidgets('a cancelled pick stays on the first page without a message', (
    tester,
  ) async {
    restore.result = const RestoreBackupResult(RestoreBackupOutcome.cancelled);
    await pumpOnboarding(tester);
    await acceptPolicy(tester);

    await tapRestore(tester);

    expect(log, ['restore']);
    expect(find.byType(SnackBar), findsNothing);
    expect(_byId('onboarding-restore-backup').hitTestable(), findsOneWidget);
  });

  testWidgets('an unreadable file says so and stays on the first page', (
    tester,
  ) async {
    restore.result = const RestoreBackupResult(
      RestoreBackupOutcome.failed,
      ExportImportFailureReason.unreadableOrWrongFormat,
    );
    await pumpOnboarding(tester);
    await acceptPolicy(tester);

    await tapRestore(tester);

    expect(
      find.text(
        'The selected file could not be read. Choose the .zip backup that '
        'OpenNutriTracker exported.',
      ),
      findsOneWidget,
    );
    expect(_byId('onboarding-restore-backup').hitTestable(), findsOneWidget);
  });

  testWidgets('a profile that is already set up is refused with a pointer '
      'to Settings', (tester) async {
    restore.result = const RestoreBackupResult(
      RestoreBackupOutcome.profileHasData,
    );
    await pumpOnboarding(tester);
    await acceptPolicy(tester);

    await tapRestore(tester);

    expect(
      find.text(
        'This profile is already set up. Import the backup from Settings '
        'instead.',
      ),
      findsOneWidget,
    );
    expect(_byId('onboarding-restore-backup').hitTestable(), findsOneWidget);
  });
}
