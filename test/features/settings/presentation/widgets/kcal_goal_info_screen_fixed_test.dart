import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/domain/entity/kcal_goal_breakdown_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_gender_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_pal_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_weight_goal_entity.dart';
import 'package:opennutritracker/core/utils/energy_unit_provider.dart';
import 'package:opennutritracker/features/settings/presentation/widgets/kcal_goal_info_screen.dart';
import 'package:opennutritracker/generated/l10n.dart';
import 'package:provider/provider.dart';

import '../../../../helpers/test_l10n.dart';

/// #671: with a fixed daily goal the transparency screen has to say so, and
/// its total has to match the goal Home shows.
void main() {
  // Same reference user as kcal_goal_info_screen_test.dart: TDEE 3164.98.
  KcalGoalBreakdownEntity breakdown({double? fixed}) {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return KcalGoalBreakdownEntity.compute(
      user: UserEntity(
        birthday: DateTime(yesterday.year - 30, yesterday.month, yesterday.day),
        heightCM: 180.0,
        weightKG: 80.0,
        gender: UserGenderEntity.male,
        goal: UserWeightGoalEntity.loseWeight,
        pal: UserPALEntity.active,
      ),
      userKcalAdjustment: 150,
      fixedKcalGoal: fixed,
      totalKcalActivities: 320,
    );
  }

  Future<void> pump(
    WidgetTester tester,
    KcalGoalBreakdownEntity b, {
    bool usesKilojoules = false,
  }) async {
    tester.view.physicalSize = const Size(1200, 4500);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => EnergyUnitProvider(usesKilojoules: usesKilojoules),
        child: MaterialApp(
          localizationsDelegates: const [
            S.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: S.supportedLocales,
          home: KcalGoalInfoScreen(breakdown: b),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows the fixed goal and adds only the activities to it', (
    tester,
  ) async {
    await pump(tester, breakdown(fixed: 2000));

    expect(find.text(l10nEn.kcalGoalInfoFixedExplanation), findsOneWidget);
    // Fixed-goal card plus its line in the result card.
    expect(find.text('2000 kcal'), findsNWidgets(2));
    // 2000 + 320.
    expect(find.text('2320 kcal'), findsOneWidget);
    // The TDEE is still shown in its own step, but no longer in the sum.
    expect(find.text('3165 kcal'), findsOneWidget);
    expect(find.textContaining('2320 × 60 % ÷ 4 = 348 g'), findsOneWidget);
  });

  testWidgets('shows the fixed goal in kJ', (tester) async {
    await pump(tester, breakdown(fixed: 2000), usesKilojoules: true);

    // 2000 × 4.184 = 8368; 2320 × 4.184 = 9706.9.
    expect(find.text('8368 kJ'), findsNWidgets(2));
    expect(find.text('9707 kJ'), findsOneWidget);
  });

  testWidgets('without a fixed goal there is no fixed-goal card', (
    tester,
  ) async {
    await pump(tester, breakdown());

    expect(find.text(l10nEn.kcalGoalInfoFixedExplanation), findsNothing);
    expect(find.text('3135 kcal'), findsOneWidget);
  });
}
