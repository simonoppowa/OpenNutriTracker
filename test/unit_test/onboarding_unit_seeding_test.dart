import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/data/dbo/app_theme_dbo.dart';
import 'package:opennutritracker/core/data/dbo/config_dbo.dart';
import 'package:opennutritracker/core/data/repository/config_repository.dart';
import 'package:opennutritracker/core/data/repository/user_repository.dart';
import 'package:opennutritracker/core/domain/entity/body_weight_unit_entity.dart';
import 'package:opennutritracker/core/domain/entity/config_entity.dart';
import 'package:opennutritracker/core/domain/usecase/add_config_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/add_user_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_config_usecase.dart';
import 'package:opennutritracker/core/utils/locale_units.dart';
import 'package:opennutritracker/features/onboarding/presentation/bloc/onboarding_bloc.dart';

/// Serves one canned config, standing in for the shared app config box.
class _FakeConfigRepository implements ConfigRepository {
  _FakeConfigRepository(this.dbo);

  final ConfigDBO dbo;

  @override
  Future<ConfigDBO> getConfigDBO() async => dbo;

  @override
  Future<ConfigEntity> getConfig() async => ConfigEntity.fromConfigDBO(dbo);

  @override
  noSuchMethod(Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}

/// Only needed to build AddUserUsecase; the onboarding load never writes.
class _FakeUserRepository implements UserRepository {
  @override
  noSuchMethod(Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}

void main() {
  /// The freshly-installed shape: the three split unit fields are null and
  /// the legacy flag has never been set either.
  ConfigDBO freshConfig() => ConfigDBO(
    false,
    false,
    false,
    AppThemeDBO.system,
    usesImperialUnits: null,
  );

  Future<OnboardingBloc> loadedBloc(ConfigDBO config) async {
    final configRepo = _FakeConfigRepository(config);
    final bloc = OnboardingBloc(
      AddUserUsecase(_FakeUserRepository()),
      AddConfigUsecase(configRepo),
      GetConfigUsecase(configRepo),
    );
    bloc.add(LoadOnboardingEvent());
    await bloc.stream.firstWhere((state) => state is OnboardingLoadedState);
    return bloc;
  }

  group('first run — no stored preference', () {
    test('seeds the unit toggles from the device locale', () async {
      final bloc = await loadedBloc(freshConfig());
      addTearDown(bloc.close);

      final expected = LocaleUnitDefaults.fromLocale(Platform.localeName);
      expect(
        bloc.userSelection.heightUsesImperial,
        expected.heightUsesImperial,
      );
      expect(bloc.userSelection.bodyWeightUnit, expected.bodyWeightUnit);
      expect(bloc.userSelection.foodUsesImperial, expected.foodUsesImperial);
    });
  });

  group('a preference already exists — it wins over the locale', () {
    test('stored imperial height and stones are restored', () async {
      final bloc = await loadedBloc(
        ConfigDBO(
          false,
          false,
          false,
          AppThemeDBO.system,
          usesImperialHeightUnits: true,
          usesImperialFoodUnits: false,
          bodyWeightUnitIndex: BodyWeightUnit.st.index,
        ),
      );
      addTearDown(bloc.close);

      expect(bloc.userSelection.heightUsesImperial, isTrue);
      expect(bloc.userSelection.bodyWeightUnit, BodyWeightUnit.st);
      expect(bloc.userSelection.foodUsesImperial, isFalse);
    });

    test('a deliberate metric choice is not overridden', () async {
      // The case the guard exists for: someone on a US device who switched
      // to metric, then adds a second profile. Units live in the shared app
      // box, so re-guessing here would also rewrite profile one's units.
      final bloc = await loadedBloc(
        ConfigDBO(
          false,
          false,
          false,
          AppThemeDBO.system,
          usesImperialHeightUnits: false,
          usesImperialFoodUnits: false,
          bodyWeightUnitIndex: BodyWeightUnit.kg.index,
        ),
      );
      addTearDown(bloc.close);

      expect(bloc.userSelection.heightUsesImperial, isFalse);
      expect(bloc.userSelection.bodyWeightUnit, BodyWeightUnit.kg);
      expect(bloc.userSelection.foodUsesImperial, isFalse);
    });

    test('the legacy imperial flag alone counts as a choice', () async {
      // Pre-split install: only usesImperialUnits was ever written.
      final bloc = await loadedBloc(
        ConfigDBO(
          false,
          false,
          false,
          AppThemeDBO.system,
          usesImperialUnits: true,
        ),
      );
      addTearDown(bloc.close);

      expect(bloc.userSelection.heightUsesImperial, isTrue);
      expect(bloc.userSelection.bodyWeightUnit, BodyWeightUnit.lb);
      expect(bloc.userSelection.foodUsesImperial, isTrue);
    });
  });

  group('hasExplicitUnitPreferences', () {
    test('is false on a fresh install', () async {
      final usecase = GetConfigUsecase(_FakeConfigRepository(freshConfig()));

      expect(await usecase.hasExplicitUnitPreferences(), isFalse);
    });

    test('legacy usesImperialUnits=false is not treated as a choice', () async {
      // ConfigDBO.empty() writes false here, so it cannot distinguish an
      // untouched install from a deliberate metric one.
      final usecase = GetConfigUsecase(
        _FakeConfigRepository(
          ConfigDBO(
            false,
            false,
            false,
            AppThemeDBO.system,
            usesImperialUnits: false,
          ),
        ),
      );

      expect(await usecase.hasExplicitUnitPreferences(), isFalse);
    });

    test('any split unit field being set counts', () async {
      final usecase = GetConfigUsecase(
        _FakeConfigRepository(
          ConfigDBO(
            false,
            false,
            false,
            AppThemeDBO.system,
            usesImperialUnits: null,
            bodyWeightUnitIndex: 0,
          ),
        ),
      );

      expect(await usecase.hasExplicitUnitPreferences(), isTrue);
    });
  });

  group('food databases follow the same first-run rule', () {
    test('a fresh install gets the locale-appropriate sources', () async {
      final bloc = await loadedBloc(freshConfig());
      addTearDown(bloc.close);

      expect(
        bloc.userSelection.foodSourceToggles,
        defaultFoodSourceToggles(Platform.localeName),
      );
    });

    test('a stored set of toggles is restored untouched', () async {
      final stored = {
        'fdc_foundation': false,
        'fdc_sr_legacy': true,
        'fdc_survey': false,
        'fdc_branded': false,
        'bls': true,
      };
      final bloc = await loadedBloc(
        ConfigDBO(
          false,
          false,
          false,
          AppThemeDBO.system,
          usesImperialUnits: null,
          foodSourceToggles: stored,
        ),
      );
      addTearDown(bloc.close);

      expect(bloc.userSelection.foodSourceToggles, stored);
    });
  });
}
