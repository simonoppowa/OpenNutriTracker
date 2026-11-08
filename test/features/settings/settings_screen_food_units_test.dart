import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:opennutritracker/core/domain/entity/app_theme_entity.dart';
import 'package:opennutritracker/core/utils/ai_credential_storage.dart';
import 'package:opennutritracker/core/utils/locator.dart';
import 'package:opennutritracker/features/add_meal/domain/usecase/probe_ai_endpoint_usecase.dart';
import 'package:opennutritracker/features/add_meal/domain/usecase/run_ai_endpoint_probe_usecase.dart';
import 'package:opennutritracker/features/diary/presentation/bloc/calendar_day_bloc.dart';
import 'package:opennutritracker/features/diary/presentation/bloc/diary_bloc.dart';
import 'package:opennutritracker/features/home/presentation/bloc/home_bloc.dart';
import 'package:opennutritracker/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:opennutritracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:opennutritracker/features/settings/settings_screen.dart';
import 'package:opennutritracker/features/trends/presentation/bloc/trends_bloc.dart';
import 'package:opennutritracker/generated/l10n.dart';

import '../../helpers/test_l10n.dart';

/// Records what the screen asks of each bloc, in one shared log.
final List<String> _log = [];

class _SettingsBloc extends Fake implements SettingsBloc {
  final _controller = StreamController<SettingsState>.broadcast();

  @override
  SettingsState get state =>
      const SettingsLoadedState('1.0.0', false, AppThemeEntity.system, false);

  @override
  Stream<SettingsState> get stream => _controller.stream;

  @override
  void add(SettingsEvent event) => _log.add(event.runtimeType.toString());

  @override
  void setUsesImperialFoodUnits(bool usesImperial) =>
      _log.add('setUsesImperialFoodUnits($usesImperial)');

  Future<void> dispose() => _controller.close();
}

class _ProfileBloc extends Fake implements ProfileBloc {
  @override
  void add(ProfileEvent event) => _log.add(event.runtimeType.toString());
}

class _HomeBloc extends Fake implements HomeBloc {
  @override
  void add(HomeEvent event) => _log.add(event.runtimeType.toString());
}

class _DiaryBloc extends Fake implements DiaryBloc {
  @override
  void add(DiaryEvent event) => _log.add(event.runtimeType.toString());
}

class _CalendarDayBloc extends Fake implements CalendarDayBloc {
  @override
  void add(CalendarDayEvent event) => _log.add(event.runtimeType.toString());
}

class _TrendsBloc extends Fake implements TrendsBloc {
  @override
  void add(TrendsEvent event) => _log.add(event.runtimeType.toString());
}

class _EmptyStorage implements FlutterSecureStorage {
  @override
  Future<String?> read({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async => null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeProber extends Fake implements AiEndpointProber {}

void main() {
  late _SettingsBloc settingsBloc;

  setUp(() {
    _log.clear();
    settingsBloc = _SettingsBloc();
    final getIt = GetIt.instance;
    getIt.registerSingleton<SettingsBloc>(settingsBloc);
    getIt.registerSingleton<ProfileBloc>(_ProfileBloc());
    getIt.registerSingleton<HomeBloc>(_HomeBloc());
    getIt.registerSingleton<DiaryBloc>(_DiaryBloc());
    getIt.registerSingleton<CalendarDayBloc>(_CalendarDayBloc());
    getIt.registerSingleton<TrendsBloc>(_TrendsBloc());
    final credentials = AiCredentialStorage(_EmptyStorage());
    getIt.registerSingleton<AiCredentialStorage>(credentials);
    getIt.registerSingleton<AiEndpointProbeRunner>(
      AiEndpointProbeRunner(credentials, _FakeProber()),
    );
  });

  tearDown(() async {
    await settingsBloc.dispose();
    await locator.reset();
  });

  // Profile's water goal and the Trends water card follow the food unit
  // (#1306), and both blocs keep their loaded state, so switching the unit
  // must reload them as it reloads Home and the diary.
  testWidgets('switching the food unit reloads Profile and Trends', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [
          S.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: S.supportedLocales,
        home: const SettingsScreen(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text(l10nEn.settingsFoodUnitsLabel));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10nEn.settingsFoodUnitsImperial));
    await tester.pumpAndSettle();
    _log.clear();
    await tester.tap(find.text(l10nEn.dialogOKLabel));
    await tester.pumpAndSettle();

    expect(_log.first, 'setUsesImperialFoodUnits(true)');
    expect(_log, contains('LoadProfileEvent'));
    expect(_log, contains('RefreshTrendsEvent'));
    expect(_log, contains('LoadItemsEvent'));
    expect(_log, contains('LoadDiaryYearEvent'));
  });
}
