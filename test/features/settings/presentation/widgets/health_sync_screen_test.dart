import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:opennutritracker/core/data/repository/health_import_repository.dart';
import 'package:opennutritracker/core/domain/entity/app_theme_entity.dart';
import 'package:opennutritracker/core/domain/entity/config_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_entity.dart';
import 'package:opennutritracker/core/domain/usecase/get_config_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_user_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/import_workouts_usecase.dart';
import 'package:opennutritracker/core/utils/calc/workout_compensation_calc.dart';
import 'package:opennutritracker/core/utils/locator.dart';
import 'package:opennutritracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:opennutritracker/features/settings/presentation/widgets/health_disclosure_dialog.dart';
import 'package:opennutritracker/features/settings/presentation/widgets/health_sync_screen.dart';
import 'package:opennutritracker/generated/l10n.dart';

import '../../../../fixture/user_entity_fixtures.dart';
import '../../../../helpers/test_l10n.dart';

class _FakeSettingsBloc extends Fake implements SettingsBloc {
  final List<bool> importEnabledCalls = [];
  final List<double> multiplierCalls = [];

  @override
  Future<void> setHealthImportEnabled(bool enabled) async {
    importEnabledCalls.add(enabled);
  }

  @override
  Future<void> setHealthWorkoutKcalMultiplier(double multiplier) async {
    multiplierCalls.add(multiplier);
  }
}

class _FakeGetConfigUsecase extends Fake implements GetConfigUsecase {
  ConfigEntity config = const ConfigEntity(
    true,
    true,
    false,
    AppThemeEntity.system,
  );

  @override
  Future<ConfigEntity> getConfig() async => config;
}

class _FakeHealthImportRepository extends Fake
    implements HealthImportRepository {
  bool available = true;
  bool granted = true;
  double? bodyFatPercent;
  int requestPermissionsCalls = 0;

  @override
  Future<bool> isAvailable() async => available;

  @override
  Future<bool> requestPermissions() async {
    requestPermissionsCalls++;
    return granted;
  }

  @override
  Future<double?> getLatestBodyFatPercent() async => bodyFatPercent;
}

class _FakeImportWorkoutsUsecase extends Fake implements ImportWorkoutsUsecase {
  int importedCount = 0;
  int importNowCalls = 0;

  @override
  Future<int> importNow() async {
    importNowCalls++;
    return importedCount;
  }
}

class _FakeGetUserUsecase extends Fake implements GetUserUsecase {
  final UserEntity user;

  _FakeGetUserUsecase(this.user);

  @override
  Future<UserEntity> getUserData() async => user;
}

Widget _wrap(Widget child) {
  return MaterialApp(
    localizationsDelegates: const [S.delegate],
    supportedLocales: S.supportedLocales,
    home: child,
  );
}

/// Finds the widget carrying an accessibility identifier, which is how the
/// screen's interactive rows are addressed.
Finder _byIdentifier(String identifier) => find.byWidgetPredicate(
  (widget) => widget is Semantics && widget.properties.identifier == identifier,
);

void main() {
  late _FakeSettingsBloc settingsBloc;
  late _FakeGetConfigUsecase getConfigUsecase;
  late _FakeHealthImportRepository healthImportRepository;
  late _FakeImportWorkoutsUsecase importWorkoutsUsecase;

  final user = UserEntityFixtures.youngSedentaryMaleWantingToMaintainWeight;

  /// What the screen should be offering this user. Read from the calculator
  /// rather than restated, so the tests follow it if the anchors move.
  final suggestedMultiplier = WorkoutCompensationCalc.suggestedMultiplier(
    user: user,
  );
  final suggestedPercent = (suggestedMultiplier * 100).round();

  setUp(() {
    settingsBloc = _FakeSettingsBloc();
    getConfigUsecase = _FakeGetConfigUsecase();
    healthImportRepository = _FakeHealthImportRepository();
    importWorkoutsUsecase = _FakeImportWorkoutsUsecase();

    locator.registerSingleton<SettingsBloc>(settingsBloc);
    locator.registerSingleton<GetConfigUsecase>(getConfigUsecase);
    locator.registerSingleton<HealthImportRepository>(healthImportRepository);
    locator.registerSingleton<ImportWorkoutsUsecase>(importWorkoutsUsecase);
    locator.registerSingleton<GetUserUsecase>(_FakeGetUserUsecase(user));
  });

  tearDown(() async {
    await GetIt.instance.reset();
  });

  /// Rewrites the stored config the screen loads from. Positional arguments
  /// mirror ConfigEntity's disclaimer / policy / anonymous-data / theme head.
  void storeConfig({
    required bool healthImportEnabled,
    double? healthWorkoutKcalMultiplier,
  }) {
    getConfigUsecase.config = ConfigEntity(
      true,
      true,
      false,
      AppThemeEntity.system,
      healthImportEnabled: healthImportEnabled,
      healthWorkoutKcalMultiplier: healthWorkoutKcalMultiplier,
    );
  }

  Future<void> pumpScreen(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(_wrap(const HealthSyncScreen()));
    await tester.pumpAndSettle();
  }

  /// Taps the opt-in switch and confirms the disclosure that #926 put in front
  /// of the permission request. Every opt-in goes through it, so the tests that
  /// exercise opting in have to as well.
  Future<void> optIn(WidgetTester tester) async {
    await tester.tap(_byIdentifier('health-sync-auto-import'));
    await tester.pumpAndSettle();
    expect(
      find.byType(HealthDisclosureDialog),
      findsOneWidget,
      reason: 'the platform must not be asked before the user is told',
    );
    await tester.tap(find.text(l10nEn.healthSyncDisclosureContinueAction));
    await tester.pumpAndSettle();
  }

  testWidgets('import is off and the credit slider inert until opted in', (
    tester,
  ) async {
    storeConfig(healthImportEnabled: false);

    await pumpScreen(tester);

    expect(
      tester.widget<SwitchListTile>(find.byType(SwitchListTile)).value,
      isFalse,
    );
    // A null onChanged is what makes a Slider unusable, so it is the honest
    // assertion for "disabled while import is off".
    expect(tester.widget<Slider>(find.byType(Slider)).onChanged, isNull);
    expect(healthImportRepository.requestPermissionsCalls, 0);
    expect(
      find.text(l10nEn.healthSyncSuggestedLabel(suggestedPercent)),
      findsNothing,
    );
  });

  testWidgets('opting in seeds the credit with the suggested multiplier', (
    tester,
  ) async {
    storeConfig(healthImportEnabled: false);
    healthImportRepository.granted = true;

    await pumpScreen(tester);
    await optIn(tester);

    expect(healthImportRepository.requestPermissionsCalls, 1);
    expect(settingsBloc.importEnabledCalls, [true]);
    expect(settingsBloc.multiplierCalls, [suggestedMultiplier]);
    expect(
      tester.widget<SwitchListTile>(find.byType(SwitchListTile)).value,
      isTrue,
    );
    expect(
      tester.widget<Slider>(find.byType(Slider)).value,
      suggestedMultiplier,
    );
    // Opting in imports straight away rather than waiting for the next
    // app start.
    expect(importWorkoutsUsecase.importNowCalls, 1);
  });

  testWidgets('a denied permission leaves import off and says so', (
    tester,
  ) async {
    storeConfig(healthImportEnabled: false);
    healthImportRepository.granted = false;

    await pumpScreen(tester);
    await optIn(tester);

    expect(
      tester.widget<SwitchListTile>(find.byType(SwitchListTile)).value,
      isFalse,
    );
    expect(settingsBloc.importEnabledCalls, isEmpty);
    expect(importWorkoutsUsecase.importNowCalls, 0);
    expect(
      find.text(l10nEn.healthSyncPermissionDeniedLabel(healthPlatformName)),
      findsOneWidget,
    );
  });

  testWidgets('the suggestion is offered only when it differs from the '
      'stored credit', (tester) async {
    storeConfig(
      healthImportEnabled: true,
      healthWorkoutKcalMultiplier: ConfigEntity.maxHealthWorkoutKcalMultiplier,
    );

    await pumpScreen(tester);

    expect(
      find.text(l10nEn.healthSyncSuggestedLabel(suggestedPercent)),
      findsOneWidget,
    );
  });

  testWidgets('no suggestion is offered once the credit already matches it', (
    tester,
  ) async {
    storeConfig(
      healthImportEnabled: true,
      healthWorkoutKcalMultiplier: suggestedMultiplier,
    );

    await pumpScreen(tester);

    expect(
      find.text(l10nEn.healthSyncSuggestedLabel(suggestedPercent)),
      findsNothing,
    );
  });

  testWidgets('every interactive widget carries an accessibility identifier', (
    tester,
  ) async {
    storeConfig(
      healthImportEnabled: true,
      healthWorkoutKcalMultiplier: ConfigEntity.maxHealthWorkoutKcalMultiplier,
    );

    await pumpScreen(tester);

    expect(_byIdentifier('health-sync-auto-import'), findsOneWidget);
    expect(_byIdentifier('health-sync-import-now'), findsOneWidget);
    expect(_byIdentifier('health-sync-kcal-multiplier'), findsOneWidget);
    expect(_byIdentifier('health-sync-sources'), findsOneWidget);
    expect(_byIdentifier('health-sync-apply-suggestion'), findsOneWidget);
  });

  testWidgets('the credit section title cannot overflow its row', (
    tester,
  ) async {
    storeConfig(healthImportEnabled: true);

    // Narrow enough that the label, the percentage and the sources button
    // genuinely compete for the width.
    await tester.binding.setSurfaceSize(const Size(320, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(_wrap(const HealthSyncScreen()));
    await tester.pumpAndSettle();

    final title = tester.widget<AutoSizeText>(
      find.widgetWithText(AutoSizeText, l10nEn.healthSyncKcalMultiplierLabel),
    );
    expect(title.maxLines, 1);
    expect(title.minFontSize, lessThan(title.style?.fontSize ?? 16));
    expect(title.overflow, TextOverflow.ellipsis);
    expect(tester.takeException(), isNull);
  });

  // #926: Play's User Data policy wants the disclosure in front of the
  // permission request, resolved by an affirmative action. These pin the part
  // that matters — that a refusal really does ask the platform for nothing.

  testWidgets('cancelling the disclosure asks the platform for nothing', (
    tester,
  ) async {
    storeConfig(healthImportEnabled: false);
    // Granted, so a wrongly-proceeding implementation would succeed loudly
    // rather than be masked by a denial.
    healthImportRepository.granted = true;

    await pumpScreen(tester);
    await tester.tap(_byIdentifier('health-sync-auto-import'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10nEn.dialogCancelLabel));
    await tester.pumpAndSettle();

    expect(healthImportRepository.requestPermissionsCalls, 0);
    expect(settingsBloc.importEnabledCalls, isEmpty);
    expect(importWorkoutsUsecase.importNowCalls, 0);
    expect(
      tester.widget<SwitchListTile>(find.byType(SwitchListTile)).value,
      isFalse,
    );
  });

  // A dialog that a stray tap could dismiss into a permission prompt would not
  // be consent, so the barrier has to hold.
  testWidgets('the disclosure ignores a tap outside it', (tester) async {
    storeConfig(healthImportEnabled: false);
    healthImportRepository.granted = true;

    await pumpScreen(tester);
    await tester.tap(_byIdentifier('health-sync-auto-import'));
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(5, 5));
    await tester.pumpAndSettle();

    expect(find.byType(HealthDisclosureDialog), findsOneWidget);
    expect(healthImportRepository.requestPermissionsCalls, 0);
  });

  testWidgets('turning import off discloses nothing', (tester) async {
    storeConfig(healthImportEnabled: true);

    await pumpScreen(tester);
    await tester.tap(_byIdentifier('health-sync-auto-import'));
    await tester.pumpAndSettle();

    expect(find.byType(HealthDisclosureDialog), findsNothing);
    expect(settingsBloc.importEnabledCalls, [false]);
  });

  // The four things the disclosure owes a reader. Asserted against the source
  // language so that rewriting the copy for tone cannot quietly drop one of
  // them — which is the failure mode, since all four read as reassurance
  // rather than as requirements.
  test('the disclosure covers what it has to cover', () {
    final body = l10nEn.healthSyncDisclosureBody(healthPlatformName);

    expect(
      body,
      contains(healthPlatformName),
      reason: 'must name the store the data comes from',
    );
    expect(
      body,
      contains('body fat'),
      reason:
          'body fat is read as well as workouts, and is the more '
          'sensitive of the two',
    );
    expect(
      body.toLowerCase(),
      contains('written back'),
      reason: 'read-only access is a disclosure element, not a detail',
    );
    expect(
      body.toLowerCase(),
      contains('stays on this device'),
      reason:
          'that nothing is transmitted is the claim the whole Play '
          'declaration rests on',
    );
  });
}
