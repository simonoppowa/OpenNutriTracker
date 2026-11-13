import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/domain/entity/app_theme_entity.dart';
import 'package:opennutritracker/core/styles/accent_colors.dart';
import 'package:opennutritracker/core/utils/locator.dart';
import 'package:opennutritracker/core/utils/theme_mode_provider.dart';
import 'package:opennutritracker/features/onboarding/presentation/widgets/onboarding_other_options_page_body.dart';
import 'package:opennutritracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:opennutritracker/features/settings/presentation/widgets/accent_colour_screen.dart';
import 'package:opennutritracker/generated/l10n.dart';
import 'package:provider/provider.dart';

/// WCAG 2.x contrast ratio, computed here so the test checks the formula
/// rather than the code under test.
double _contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

String _hex(Color c) => '0x${c.toARGB32().toRadixString(16).toUpperCase()}';

/// A settings bloc that answers with one loaded state with [accent] picked.
class _FakeSettingsBloc extends Fake implements SettingsBloc {
  _FakeSettingsBloc(this.accent);

  final Color accent;

  @override
  SettingsState get state => SettingsLoadedState(
    '1.0.0',
    false,
    AppThemeEntity.system,
    false,
    useMaterialYou: false,
    accentColor: accent.toARGB32(),
  );

  @override
  Stream<SettingsState> get stream => const Stream<SettingsState>.empty();

  @override
  void add(SettingsEvent event) {}
}

/// The selected swatch's tick must stay readable on its own colour: white on
/// yellow or amber is under 2:1.
void _expectReadableTick(WidgetTester tester, Color swatch) {
  final tick = tester.widget<Icon>(find.byIcon(Icons.check_rounded));
  final ratio = _contrast(tick.color!, swatch);
  expect(
    ratio,
    greaterThanOrEqualTo(4.5),
    reason:
        'tick ${_hex(tick.color!)} on ${_hex(swatch)} is '
        '${ratio.toStringAsFixed(2)}:1',
  );
}

Widget _app(Widget home) => ChangeNotifierProvider<ThemeModeProvider>(
  create: (_) => ThemeModeProvider(appTheme: AppThemeEntity.system),
  child: MaterialApp(
    localizationsDelegates: const [S.delegate],
    supportedLocales: S.supportedLocales,
    home: home,
  ),
);

void main() {
  tearDown(() async => locator.reset());

  testWidgets('Settings accent screen: tick is readable on every preset', (
    tester,
  ) async {
    for (final accent in accentPresetColors) {
      await locator.reset();
      locator.registerSingleton<SettingsBloc>(_FakeSettingsBloc(accent));
      await tester.pumpWidget(_app(const AccentColourScreen()));
      await tester.pumpAndSettle();
      _expectReadableTick(tester, accent);
      // Start the next preset from a fresh screen and bloc.
      await tester.pumpWidget(const SizedBox());
    }
  });

  testWidgets('onboarding options page: tick is readable on every preset', (
    tester,
  ) async {
    for (final accent in accentPresetColors) {
      await tester.pumpWidget(
        _app(
          Scaffold(
            body: OnboardingOtherOptionsPageBody(
              setPageContent: (_, _, _, _, _) {},
              initialTheme: AppThemeEntity.system,
              initialFoodSourceToggles: const {},
              initialDailyReminderEnabled: false,
              initialUseMaterialYou: false,
              initialAccentColor: accent.toARGB32(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      // The swatch row is a lazy horizontal list: later presets are only
      // built once scrolled into view.
      await tester.scrollUntilVisible(
        find.byIcon(Icons.check_rounded),
        100,
        scrollable: find.byWidgetPredicate(
          (w) => w is Scrollable && w.axisDirection == AxisDirection.right,
        ),
      );
      _expectReadableTick(tester, accent);
      await tester.pumpWidget(const SizedBox());
    }
  });
}
