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
    await tester.tap(_byIdentifier('health-sync-auto-import'));
    await tester.pumpAndSettle();

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
    await tester.tap(_byIdentifier('health-sync-auto-import'));
    await tester.pumpAndSettle();

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
}
