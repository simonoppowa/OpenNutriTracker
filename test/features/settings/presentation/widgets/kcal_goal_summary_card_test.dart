import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/domain/entity/kcal_goal_breakdown_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_gender_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_pal_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_weight_goal_entity.dart';
import 'package:opennutritracker/core/domain/usecase/get_kcal_goal_breakdown_usecase.dart';
import 'package:opennutritracker/core/utils/energy_unit_provider.dart';
import 'package:opennutritracker/features/settings/presentation/widgets/kcal_goal_info_screen.dart';
import 'package:opennutritracker/generated/l10n.dart';
import 'package:provider/provider.dart';

import '../../../../helpers/test_l10n.dart';

/// The short summary at the top of the calorie-goal screen (#1308): one
/// row per term that applies, rows that add up to the target, a plain
/// note that logged activities add to it, and a link to the equation.
class _FakeBreakdownUsecase extends Fake
    implements GetKcalGoalBreakdownUsecase {
  final KcalGoalBreakdownEntity breakdown;

  _FakeBreakdownUsecase(this.breakdown);

  @override
  Future<KcalGoalBreakdownEntity> getBreakdown() async => breakdown;
}

UserEntity _buildUser({
  UserWeightGoalEntity goal = UserWeightGoalEntity.loseWeight,
  double? targetWeightKg,
  bool taperEnabled = false,
  double weightKG = 80.0,
}) {
  final yesterday = DateTime.now().subtract(const Duration(days: 1));
  return UserEntity(
    birthday: DateTime(yesterday.year - 30, yesterday.month, yesterday.day),
    heightCM: 180.0,
    weightKG: weightKG,
    gender: UserGenderEntity.male,
    goal: goal,
    pal: UserPALEntity.active,
    targetWeightKg: targetWeightKg,
    caloriesTaperEnabled: taperEnabled,
  );
}

Future<void> _pump(
  WidgetTester tester,
  KcalGoalBreakdownEntity breakdown, {
  bool usesKilojoules = false,
  double textScale = 1.0,
  Size size = const Size(1200, 4500),
}) async {
  tester.view.physicalSize = size;
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
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: KcalGoalInfoScreen(usecase: _FakeBreakdownUsecase(breakdown)),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Finder _summary() => find.byKey(const ValueKey('kcal-goal-summary'));

Finder _inSummary(Finder finder) =>
    find.descendant(of: _summary(), matching: finder);

String _textOf(WidgetTester tester, Key key) =>
    tester.widget<Text>(_inSummary(find.byKey(key))).data!;

/// Parses "+180 kcal", "−500 kcal", "3165 kcal" or "-12 kJ" to its number.
int _parse(String text) {
  final number = text.split(' ').first.replaceAll('−', '-');
  return int.parse(number.replaceAll('+', ''));
}

void main() {
  group('calorie goal summary', () {
    testWidgets('is the first card, above the step-by-step cards', (
      tester,
    ) async {
      await _pump(
        tester,
        KcalGoalBreakdownEntity.compute(
          user: _buildUser(),
          totalKcalActivities: 0,
        ),
      );

      final summaryTop = tester.getTopLeft(_summary()).dy;
      final tdeeStepTop = tester
          .getTopLeft(find.text(l10nEn.kcalGoalInfoTdeeSection))
          .dy;
      expect(summaryTop, lessThan(tdeeStepTop));
    });

    testWidgets('lose weight with an activity: the issue example rows', (
      tester,
    ) async {
      // TDEE 3164.98 − 500 + 180 = 2844.98 → 2845.
      await _pump(
        tester,
        KcalGoalBreakdownEntity.compute(
          user: _buildUser(),
          totalKcalActivities: 180,
        ),
      );

      expect(
        _inSummary(find.text(l10nEn.kcalGoalInfoSummaryMaintenanceRow)),
        findsOneWidget,
      );
      expect(
        _inSummary(
          find.text(l10nEn.kcalGoalInfoSummaryGoalRow(l10nEn.goalLoseWeight)),
        ),
        findsOneWidget,
      );
      expect(
        _inSummary(find.text(l10nEn.kcalGoalInfoSummaryActivitiesRow)),
        findsOneWidget,
      );
      expect(
        _textOf(tester, const ValueKey('kcal-goal-summary-maintenance')),
        '3165 kcal',
      );
      expect(
        _textOf(tester, const ValueKey('kcal-goal-summary-weightGoal')),
        '−500 kcal',
      );
      expect(
        _textOf(tester, const ValueKey('kcal-goal-summary-activities')),
        '+180 kcal',
      );
      expect(
        _textOf(tester, const ValueKey('kcal-goal-summary-total')),
        '2845 kcal',
      );
      // Says plainly that the deficit is already in the number and that
      // activities add to it.
      expect(
        _inSummary(find.text(l10nEn.kcalGoalInfoSummaryIncludedNote)),
        findsOneWidget,
      );
      expect(
        _inSummary(find.text(l10nEn.kcalGoalInfoActivityExplanation)),
        findsOneWidget,
      );
    });

    testWidgets('maintain with nothing logged: no zero rows', (tester) async {
      await _pump(
        tester,
        KcalGoalBreakdownEntity.compute(
          user: _buildUser(goal: UserWeightGoalEntity.maintainWeight),
          userKcalAdjustment: 0,
          totalKcalActivities: 0,
        ),
      );

      expect(
        _inSummary(find.byKey(const ValueKey('kcal-goal-summary-weightGoal'))),
        findsNothing,
      );
      expect(
        _inSummary(
          find.byKey(const ValueKey('kcal-goal-summary-manualAdjustment')),
        ),
        findsNothing,
      );
      expect(
        _inSummary(find.byKey(const ValueKey('kcal-goal-summary-activities'))),
        findsNothing,
      );
      expect(_inSummary(find.textContaining('+0 ')), findsNothing);
      expect(_inSummary(find.textContaining('−0 ')), findsNothing);
      expect(
        _inSummary(find.text(l10nEn.kcalGoalInfoSummaryIncludedNote)),
        findsNothing,
      );
      expect(
        _textOf(tester, const ValueKey('kcal-goal-summary-total')),
        '3165 kcal',
      );
    });

    testWidgets('a user kcal adjustment uses the Settings label', (
      tester,
    ) async {
      await _pump(
        tester,
        KcalGoalBreakdownEntity.compute(
          user: _buildUser(),
          userKcalAdjustment: -150,
          totalKcalActivities: 0,
        ),
      );

      expect(
        _inSummary(find.text(l10nEn.settingsKcalAdjustmentLabel)),
        findsOneWidget,
      );
      expect(
        _textOf(tester, const ValueKey('kcal-goal-summary-manualAdjustment')),
        '−150 kcal',
      );
    });

    for (final usesKilojoules in [false, true]) {
      testWidgets('shown rows add up to the shown target '
          '(${usesKilojoules ? 'kJ' : 'kcal'})', (tester) async {
        // Tapered (−287.5) adjustment, fractional TDEE, manual offset and
        // activity: each row rounded on its own would be off by one.
        final breakdown = KcalGoalBreakdownEntity.compute(
          user: _buildUser(
            weightKG: 78.3,
            targetWeightKg: 75.0,
            taperEnabled: true,
          ),
          userKcalAdjustment: 10.4,
          totalKcalActivities: 100.4,
        );
        await _pump(tester, breakdown, usesKilojoules: usesKilojoules);

        final rowKeys = KcalGoalSummaryTerm.values
            .map((term) => ValueKey('kcal-goal-summary-${term.name}'))
            .where((key) => _inSummary(find.byKey(key)).evaluate().isNotEmpty);
        final sum = rowKeys.fold(
          0,
          (sum, key) => sum + _parse(_textOf(tester, key)),
        );
        final total = _parse(
          _textOf(tester, const ValueKey('kcal-goal-summary-total')),
        );
        expect(rowKeys, hasLength(4));
        expect(sum, total);
      });
    }

    testWidgets('a goal below zero is shown as calculated, not clamped', (
      tester,
    ) async {
      await _pump(
        tester,
        KcalGoalBreakdownEntity.compute(
          user: _buildUser(),
          userKcalAdjustment: -4000,
          totalKcalActivities: 0,
        ),
      );

      expect(
        _textOf(tester, const ValueKey('kcal-goal-summary-total')),
        '−1335 kcal',
      );
    });

    testWidgets('names and links the cited equation', (tester) async {
      await _pump(
        tester,
        KcalGoalBreakdownEntity.compute(
          user: _buildUser(),
          totalKcalActivities: 0,
        ),
      );

      final link = find.byWidgetPredicate(
        (widget) =>
            widget is Semantics &&
            widget.properties.identifier == 'kcal-goal-summary-equation',
      );
      expect(link, findsOneWidget);
      expect(
        find.descendant(
          of: link,
          matching: find.text(l10nEn.kcalGoalInfoSummaryEquationLink),
        ),
        findsOneWidget,
      );
      expect(l10nEn.kcalGoalInfoSummaryEquationLink, contains('IOM 2005'));
    });

    testWidgets('text scale 2.0 on a narrow phone does not overflow', (
      tester,
    ) async {
      await _pump(
        tester,
        KcalGoalBreakdownEntity.compute(
          user: _buildUser(
            weightKG: 78.3,
            targetWeightKg: 75.0,
            taperEnabled: true,
          ),
          userKcalAdjustment: -150,
          totalKcalActivities: 180,
        ),
        textScale: 2.0,
        size: const Size(320, 6000),
      );

      expect(tester.takeException(), isNull);
      expect(_summary(), findsOneWidget);
    });
  });
}
