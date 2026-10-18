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

/// A settings bloc the test drives by hand: it records what the screen asks
/// for and emits whatever state the test pushes.
class _DrivenSettingsBloc extends Fake implements SettingsBloc {
  final _controller = StreamController<SettingsState>.broadcast();
  final List<SettingsEvent> events = [];

  SettingsState _state = _loaded();

  @override
  SettingsState get state => _state;

  @override
  Stream<SettingsState> get stream => _controller.stream;

  @override
  void add(SettingsEvent event) => events.add(event);

  void push(SettingsState state) {
    _state = state;
    _controller.add(state);
  }

  Future<void> dispose() => _controller.close();
}

SettingsLoadedState _loaded() =>
    const SettingsLoadedState('1.0.0', false, AppThemeEntity.system, false);

class _FakeProfileBloc extends Fake implements ProfileBloc {}

class _FakeHomeBloc extends Fake implements HomeBloc {}

class _FakeDiaryBloc extends Fake implements DiaryBloc {}

class _FakeCalendarDayBloc extends Fake implements CalendarDayBloc {}

class _FakeTrendsBloc extends Fake implements TrendsBloc {}

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

Widget _app() => MaterialApp(
  localizationsDelegates: const [
    S.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  supportedLocales: S.supportedLocales,
  home: const SettingsScreen(),
);

void main() {
  late _DrivenSettingsBloc settingsBloc;

  setUp(() {
    settingsBloc = _DrivenSettingsBloc();
    final getIt = GetIt.instance;
    getIt.registerSingleton<SettingsBloc>(settingsBloc);
    getIt.registerSingleton<ProfileBloc>(_FakeProfileBloc());
    getIt.registerSingleton<HomeBloc>(_FakeHomeBloc());
    getIt.registerSingleton<DiaryBloc>(_FakeDiaryBloc());
    getIt.registerSingleton<CalendarDayBloc>(_FakeCalendarDayBloc());
    getIt.registerSingleton<TrendsBloc>(_FakeTrendsBloc());
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

  testWidgets('a reload keeps the list and where it was scrolled to (#1368)', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    final list = find.byType(Scrollable).first;
    tester.state<ScrollableState>(list).position.jumpTo(600);
    await tester.pumpAndSettle();

    // What every save and toggle sets off: loading, then the fresh values.
    settingsBloc.push(SettingsLoadingState());
    await tester.pump();
    await tester.pump();

    expect(
      find.byType(CircularProgressIndicator),
      findsNothing,
      reason: 'a reload must not swap the list for a spinner',
    );

    settingsBloc.push(_loaded());
    await tester.pumpAndSettle();

    expect(
      tester
          .state<ScrollableState>(find.byType(Scrollable).first)
          .position
          .pixels,
      600,
    );
  });

  testWidgets('the first load still shows the spinner', (tester) async {
    settingsBloc.push(SettingsLoadingState());

    await tester.pumpWidget(_app());
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
  testWidgets('coming back from a pushed screen re-reads the cache count '
      '(#1368)', (tester) async {
    // The embedded form, as the You tab hosts it: it outlives the search and
    // scan screens that fill the cache, which are pushed over it.
    final navigatorKey = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigatorKey,
        localizationsDelegates: const [
          S.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: S.supportedLocales,
        home: const Scaffold(
          body: SingleChildScrollView(child: SettingsScreen(embedded: true)),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final loadsOnEntry = settingsBloc.events
        .whereType<LoadSettingsEvent>()
        .length;

    navigatorKey.currentState!.push(
      MaterialPageRoute<void>(builder: (_) => const Scaffold()),
    );
    await tester.pumpAndSettle();
    expect(
      settingsBloc.events.whereType<LoadSettingsEvent>(),
      hasLength(loadsOnEntry),
      reason: 'nothing to refresh while it is covered',
    );

    navigatorKey.currentState!.pop();
    await tester.pumpAndSettle();

    expect(
      settingsBloc.events.whereType<LoadSettingsEvent>(),
      hasLength(loadsOnEntry + 1),
    );
  });
  testWidgets('in kJ mode the adjustment row names kJ (#1368)', (tester) async {
    settingsBloc.push(
      const SettingsLoadedState(
        '1.0.0',
        false,
        AppThemeEntity.system,
        false,
        usesKilojoules: true,
      ),
    );

    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    expect(find.text(l10nEn.settingsKjAdjustmentLabel), findsOneWidget);
    expect(find.text(l10nEn.settingsKcalAdjustmentLabel), findsNothing);
  });
}
