import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:opennutritracker/core/domain/entity/app_theme_entity.dart';
import 'package:opennutritracker/core/utils/ai_credential_storage.dart';
import 'package:opennutritracker/core/utils/locator.dart';
import 'package:opennutritracker/core/utils/navigation_options.dart';
import 'package:opennutritracker/features/add_meal/domain/usecase/probe_ai_endpoint_usecase.dart';
import 'package:opennutritracker/features/add_meal/domain/usecase/run_ai_endpoint_probe_usecase.dart';
import 'package:opennutritracker/features/diary/presentation/bloc/calendar_day_bloc.dart';
import 'package:opennutritracker/features/diary/presentation/bloc/diary_bloc.dart';
import 'package:opennutritracker/features/home/presentation/bloc/home_bloc.dart';
import 'package:opennutritracker/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:opennutritracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:opennutritracker/features/settings/presentation/widgets/ai_assist_dialog.dart';
import 'package:opennutritracker/features/settings/settings_screen.dart';
import 'package:opennutritracker/features/trends/presentation/bloc/trends_bloc.dart';
import 'package:opennutritracker/generated/l10n.dart';

import '../../helpers/test_l10n.dart';

/// A loaded settings screen without the config box behind it.
///
/// The screen only ever reads the state and posts `LoadSettingsEvent`, so a
/// bloc that answers with one fixed loaded state renders exactly what the
/// real one renders — and skips Hive, `package_info`, and the cache size
/// read, none of which are what these tests are about.
class _FakeSettingsBloc extends Fake implements SettingsBloc {
  @override
  SettingsState get state =>
      const SettingsLoadedState('1.0.0', false, AppThemeEntity.system, false);

  @override
  Stream<SettingsState> get stream => const Stream<SettingsState>.empty();

  @override
  void add(SettingsEvent event) {}
}

/// The screen resolves these in `initState` and only calls them from
/// controls no test here touches.
class _FakeProfileBloc extends Fake implements ProfileBloc {}

class _FakeHomeBloc extends Fake implements HomeBloc {}

class _FakeDiaryBloc extends Fake implements DiaryBloc {}

class _FakeCalendarDayBloc extends Fake implements CalendarDayBloc {}

class _FakeTrendsBloc extends Fake implements TrendsBloc {}

/// Nothing is configured, which is the state a user arrives in from a
/// rejected key or a refused destination.
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

/// The runner is real; only the thing that would talk to a server is not.
/// Nothing here presses the check, so it is never asked anything.
class _FakeProber extends Fake implements AiEndpointProber {}

void _register() {
  final getIt = GetIt.instance;
  getIt.registerSingleton<SettingsBloc>(_FakeSettingsBloc());
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
}

/// Pushes the settings route the way the app does, so the screen reads its
/// arguments off a real `ModalRoute` rather than a constructor.
Widget _app({Object? arguments}) => MaterialApp(
  localizationsDelegates: const [
    S.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  supportedLocales: S.supportedLocales,
  initialRoute: NavigationOptions.settingsRoute,
  onGenerateRoute: (settings) => MaterialPageRoute<void>(
    settings: RouteSettings(name: settings.name, arguments: arguments),
    builder: (_) => const SettingsScreen(),
  ),
);

void main() {
  // A handset, because the point of #852 is where the AI row sits on one.
  setUp(() => _register());
  tearDown(() async => locator.reset());

  group('the embedded form is not a scrollable (#974)', () {
    /// The You tab hosts the screen inside its own scrollable, so anything
    /// scrollable here is a viewport nested in a viewport.
    Widget embeddedIn(Widget child) => MaterialApp(
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: S.supportedLocales,
      home: Scaffold(body: SingleChildScrollView(child: child)),
    );

    testWidgets('embedded, it creates no viewport of its own', (tester) async {
      // The fix, stated as the thing that can be checked without a device.
      //
      // It used to be a `ListView` with `shrinkWrap` and
      // `NeverScrollableScrollPhysics`: a viewport that cannot scroll,
      // inside the You tab's viewport that can. Rows outside the outer
      // viewport are flagged `isHidden`, and which of them cleared depended
      // on the outer list's offset — flung, it jumps in large
      // non-overlapping steps, and four rows in the middle were never
      // uncovered for a screen reader.
      //
      // The device behaviour cannot be reproduced here: a widget test
      // scrolls to a computed offset, which a fling never rests at. So this
      // pins the structural property the fix rests on instead, and says so
      // rather than implying wider cover.
      await tester.pumpWidget(
        embeddedIn(const SettingsScreen(embedded: true)),
      );
      await tester.pumpAndSettle();

      final scrollables = tester.widgetList(find.byType(Scrollable));
      expect(
        scrollables,
        hasLength(1),
        reason: 'only the host scrollable — the embedded settings must add '
            'none of its own',
      );
    });

    testWidgets('pushed, it still scrolls itself', (tester) async {
      // The other half: the standalone screen is the one that must keep its
      // viewport, and it is the arrangement that was always reachable.
      await tester.pumpWidget(_app());
      await tester.pumpAndSettle();

      expect(find.byType(Scrollable), findsWidgets);
      expect(
        tester.widget<ListView>(find.byType(ListView).first).physics,
        isNot(isA<NeverScrollableScrollPhysics>()),
      );
    });
  });

  testWidgets('the AI row is nowhere near the top of a plain Settings', (
    tester,
  ) async {
    // The premise of #852, pinned so the fix cannot be read as cosmetic: on
    // a Pixel-sized screen the Data group is far enough down that the tile
    // is not even built, let alone visible. A user sent here by the notice
    // has to scroll past four category groups to find the one control that
    // answers their failure.
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    expect(find.text(l10nEn.settingsAiAssistLabel), findsNothing);
    expect(find.byType(AiAssistDialog), findsNothing);
  });

  testWidgets('asked for the AI settings, it opens the AI dialog', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      _app(arguments: const SettingsScreenArguments(openAiAssist: true)),
    );
    await tester.pumpAndSettle();

    expect(
      find.byType(AiAssistDialog),
      findsOneWidget,
      reason: 'the caller named the control the user came to change',
    );
  });

  testWidgets('the dialog is opened once, not on every rebuild', (
    tester,
  ) async {
    // `didChangeDependencies` runs again for a theme change, a locale
    // change, a keyboard. Reading the arguments each time would reopen a
    // dialog over the one already up, and closing it would leave a second
    // behind.
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      _app(arguments: const SettingsScreenArguments(openAiAssist: true)),
    );
    await tester.pumpAndSettle();

    // Anything that makes the screen's dependencies change: a new
    // MediaQuery is the cheapest.
    tester.view.physicalSize = const Size(1080, 2000);
    await tester.pumpAndSettle();

    expect(find.byType(AiAssistDialog), findsOneWidget);
  });

  testWidgets('arguments that ask for nothing leave the screen alone', (
    tester,
  ) async {
    // Every other way into Settings pushes the route plain. A screen that
    // opened the AI dialog for them would be a worse bug than the one #852
    // fixes.
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_app(arguments: const SettingsScreenArguments()));
    await tester.pumpAndSettle();

    expect(find.byType(AiAssistDialog), findsNothing);
  });
}
