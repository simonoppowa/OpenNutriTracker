import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/domain/entity/app_theme_entity.dart';
import 'package:opennutritracker/core/presentation/widgets/section_group.dart';
import 'package:opennutritracker/core/utils/off_const.dart';
import 'package:opennutritracker/core/utils/theme_mode_provider.dart';
import 'package:opennutritracker/features/add_meal/data/dto/sp/sp_const.dart';
import 'package:opennutritracker/features/onboarding/presentation/widgets/onboarding_other_options_page_body.dart';
import 'package:opennutritracker/generated/l10n.dart';
import 'package:provider/provider.dart';

import '../../../../helpers/test_l10n.dart';

/// The "Other options" page groups its settings the way Profile and Settings
/// do, and keeps the long database list collapsed behind a summary.
void main() {
  Future<void> pumpPage(
    WidgetTester tester, {
    Map<String, bool> toggles = const {},
    void Function(Map<String, bool>)? onToggles,
  }) async {
    await tester.pumpWidget(
      ChangeNotifierProvider<ThemeModeProvider>(
        create: (_) => ThemeModeProvider(appTheme: AppThemeEntity.system),
        child: MaterialApp(
          localizationsDelegates: const [S.delegate],
          supportedLocales: S.supportedLocales,
          home: Scaffold(
            body: OnboardingOtherOptionsPageBody(
              setPageContent: (_, sources, _, _, _) => onToggles?.call(sources),
              initialTheme: AppThemeEntity.system,
              initialFoodSourceToggles: toggles,
              initialDailyReminderEnabled: false,
              initialUseMaterialYou: true,
              initialAccentColor: null,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('sections are grouped the way the rest of the app groups them', (
    tester,
  ) async {
    await pumpPage(tester);

    // Theme (with accent), food databases, notifications.
    expect(find.byType(SectionHeader), findsNWidgets(3));
    expect(find.byType(SectionGroup), findsNWidgets(3));
  });

  testWidgets('the database list starts collapsed', (tester) async {
    await pumpPage(tester);

    expect(find.byType(ExpansionTile), findsOneWidget);
    for (final source in SPConst.settingsSelectableFoodSources) {
      expect(
        find.text(SPConst.foodSourceDisplayNames[source]!),
        findsNothing,
        reason: '$source should be hidden until the tile is expanded',
      );
    }
  });

  testWidgets('the collapsed summary counts the enabled sources', (
    tester,
  ) async {
    // Four of five selectable sources on, plus Open Food Facts, which is
    // always searched and has no switch: 5 of 6.
    await pumpPage(
      tester,
      toggles: {
        'fdc_foundation': true,
        'fdc_sr_legacy': true,
        'fdc_survey': true,
        'fdc_branded': false,
        'bls': true,
      },
    );

    expect(
      find.text(l10nEn.onboardingFoodSourcesEnabledCount(5, 6)),
      findsOneWidget,
    );
  });

  testWidgets('expanding reveals every source, including the fixed one', (
    tester,
  ) async {
    await pumpPage(tester);

    await tester.tap(find.text(l10nEn.settingsFoodSourcesLabel).last);
    await tester.pumpAndSettle();

    expect(find.text(OFFConst.offSourceName), findsOneWidget);
    for (final source in SPConst.settingsSelectableFoodSources) {
      expect(
        find.text(SPConst.foodSourceDisplayNames[source]!),
        findsOneWidget,
      );
    }
  });

  testWidgets('toggling a source reports it and updates the summary', (
    tester,
  ) async {
    Map<String, bool>? reported;
    await pumpPage(
      tester,
      toggles: {for (final s in SPConst.settingsSelectableFoodSources) s: true},
      onToggles: (toggles) => reported = toggles,
    );

    expect(
      find.text(l10nEn.onboardingFoodSourcesEnabledCount(6, 6)),
      findsOneWidget,
    );

    await tester.tap(find.text(l10nEn.settingsFoodSourcesLabel).last);
    await tester.pumpAndSettle();
    final blsSwitch = find.bySemanticsIdentifier('onboarding-food-source-bls');
    // The expanded list runs past the bottom of the test surface.
    await tester.ensureVisible(blsSwitch);
    await tester.pumpAndSettle();
    await tester.tap(blsSwitch);
    await tester.pumpAndSettle();

    expect(reported?['bls'], isFalse);
    expect(
      find.text(l10nEn.onboardingFoodSourcesEnabledCount(5, 6)),
      findsOneWidget,
    );
  });
}
