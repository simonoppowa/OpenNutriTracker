import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/domain/entity/kcal_goal_breakdown_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_gender_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_pal_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_weight_goal_entity.dart';
import 'package:opennutritracker/core/utils/calc/calorie_goal_calc.dart';
import 'package:opennutritracker/core/utils/calc/unit_calc.dart';

/// The short "how today's target is built" summary (#1308). Its rows must
/// add up to the target the rest of the app shows, in whole display units,
/// and must leave out any term that contributes nothing.
void main() {
  // Yesterday (not `day - 1`) so the date stays valid on the 1st of the
  // month; captured once so components can't straddle a midnight rollover.
  final yesterday = DateTime.now().subtract(const Duration(days: 1));

  UserEntity buildUser({
    UserWeightGoalEntity goal = UserWeightGoalEntity.loseWeight,
    double? weeklyWeightGoalKg,
    double? targetWeightKg,
    bool taperEnabled = false,
    double weightKG = 80.0,
  }) {
    return UserEntity(
      birthday: DateTime(yesterday.year - 30, yesterday.month, yesterday.day),
      heightCM: 180.0,
      weightKG: weightKG,
      gender: UserGenderEntity.male,
      goal: goal,
      pal: UserPALEntity.active,
      weeklyWeightGoalKg: weeklyWeightGoalKg,
      targetWeightKg: targetWeightKg,
      caloriesTaperEnabled: taperEnabled,
    );
  }

  KcalGoalBreakdownEntity breakdownFor(
    UserEntity user, {
    double? manual,
    double activities = 0,
  }) => KcalGoalBreakdownEntity.compute(
    user: user,
    userKcalAdjustment: manual,
    totalKcalActivities: activities,
  );

  List<KcalGoalSummaryTerm> termsOf(KcalGoalSummary summary) =>
      summary.rows.map((row) => row.term).toList();

  int sumOf(KcalGoalSummary summary) =>
      summary.rows.fold(0, (sum, row) => sum + row.value);

  void expectRowsAddUp(KcalGoalBreakdownEntity breakdown) {
    for (final kilojoules in [false, true]) {
      final summary = breakdown.summary(kilojoules: kilojoules);
      final shownTotal =
          (kilojoules
                  ? UnitCalc.kcalToKj(breakdown.totalKcalGoal)
                  : breakdown.totalKcalGoal)
              .round();
      expect(summary.total, shownTotal, reason: 'kilojoules: $kilojoules');
      expect(sumOf(summary), summary.total, reason: 'kilojoules: $kilojoules');
    }
  }

  // Reference male profile (see kcal_goal_info_screen_test.dart):
  // TDEE = 864 − 9.72×30 + 1.27×(14.2×80 + 503×1.80) = 3164.98 kcal.
  group('rows', () {
    test('lose weight: maintenance, the deficit, and the target', () {
      final breakdown = breakdownFor(buildUser());
      final summary = breakdown.summary();

      expect(termsOf(summary), [
        KcalGoalSummaryTerm.maintenance,
        KcalGoalSummaryTerm.weightGoal,
      ]);
      expect(summary.rows[0].value, 3165);
      expect(summary.rows[1].value, -500);
      expect(summary.total, 2665);
      expectRowsAddUp(breakdown);
    });

    test('gain weight: the surplus is a positive row', () {
      final breakdown = breakdownFor(
        buildUser(goal: UserWeightGoalEntity.gainWeight),
      );
      final summary = breakdown.summary();

      expect(termsOf(summary), [
        KcalGoalSummaryTerm.maintenance,
        KcalGoalSummaryTerm.weightGoal,
      ]);
      expect(summary.rows[1].value, 500);
      expect(summary.total, 3665);
      expectRowsAddUp(breakdown);
    });

    test('maintain weight: no zero goal row', () {
      final breakdown = breakdownFor(
        buildUser(goal: UserWeightGoalEntity.maintainWeight),
      );
      final summary = breakdown.summary();

      expect(termsOf(summary), [KcalGoalSummaryTerm.maintenance]);
      expect(summary.total, 3165);
      expectRowsAddUp(breakdown);
    });

    test('logged activities add a positive row', () {
      final breakdown = breakdownFor(buildUser(), activities: 180);
      final summary = breakdown.summary();

      expect(termsOf(summary), [
        KcalGoalSummaryTerm.maintenance,
        KcalGoalSummaryTerm.weightGoal,
        KcalGoalSummaryTerm.activities,
      ]);
      expect(summary.rows[2].value, 180);
      expect(summary.total, 2845);
      expectRowsAddUp(breakdown);
    });

    test('without logged activities there is no activity row', () {
      final summary = breakdownFor(buildUser(), activities: 0).summary();

      expect(termsOf(summary), isNot(contains(KcalGoalSummaryTerm.activities)));
    });

    test('a user kcal adjustment gets its own signed row', () {
      final breakdown = breakdownFor(buildUser(), manual: -150);
      final summary = breakdown.summary();

      expect(termsOf(summary), [
        KcalGoalSummaryTerm.maintenance,
        KcalGoalSummaryTerm.weightGoal,
        KcalGoalSummaryTerm.manualAdjustment,
      ]);
      expect(summary.rows[2].value, -150);
      expect(summary.total, 2515);
      expectRowsAddUp(breakdown);
    });

    test('a zero user kcal adjustment adds no row', () {
      final summary = breakdownFor(buildUser(), manual: 0).summary();

      expect(
        termsOf(summary),
        isNot(contains(KcalGoalSummaryTerm.manualAdjustment)),
      );
    });

    test('a weekly pace sets the goal row', () {
      // −0.5 kg/week × 1100 = −550 kcal/day.
      final breakdown = breakdownFor(buildUser(weeklyWeightGoalKg: -0.5));
      final summary = breakdown.summary();

      expect(summary.rows[1].term, KcalGoalSummaryTerm.weightGoal);
      expect(summary.rows[1].value, -550);
      expect(summary.total, 2615);
      expectRowsAddUp(breakdown);
    });

    test('the taper shows the scaled-down adjustment, not the full one', () {
      // 3 kg above a 75 kg target → factor 0.5 → −250.
      final breakdown = breakdownFor(
        buildUser(weightKG: 78.0, targetWeightKg: 75.0, taperEnabled: true),
      );
      final summary = breakdown.summary();

      expect(summary.rows[1].value, -250);
      expectRowsAddUp(breakdown);
    });

    test('a fully tapered goal (target reached) has no goal row', () {
      final breakdown = breakdownFor(
        buildUser(weightKG: 75.0, targetWeightKg: 75.0, taperEnabled: true),
      );

      expect(termsOf(breakdown.summary()), [KcalGoalSummaryTerm.maintenance]);
      expectRowsAddUp(breakdown);
    });

    test('everything at once keeps the calculation order', () {
      final breakdown = breakdownFor(
        buildUser(
          weeklyWeightGoalKg: -0.25,
          weightKG: 78.3,
          targetWeightKg: 75.0,
          taperEnabled: true,
        ),
        manual: 120,
        activities: 312.5,
      );

      expect(termsOf(breakdown.summary()), [
        KcalGoalSummaryTerm.maintenance,
        KcalGoalSummaryTerm.weightGoal,
        KcalGoalSummaryTerm.manualAdjustment,
        KcalGoalSummaryTerm.activities,
      ]);
      expectRowsAddUp(breakdown);
    });
  });

  group('total', () {
    test('is the same number the goal calculation returns, rounded', () {
      final user = buildUser(weeklyWeightGoalKg: -0.4);
      final breakdown = breakdownFor(user, manual: 75, activities: 212.3);

      expect(
        breakdown.summary().total,
        CalorieGoalCalc.getTotalKcalGoal(
          user,
          212.3,
          kcalUserAdjustment: 75,
        ).round(),
      );
    });

    test('is not clamped: a goal below zero shows as calculated', () {
      // The app does not clamp the goal anywhere (CalorieGoalCalc,
      // GetKcalGoalUsecase, the dashboard), so the summary must not either,
      // or it would disagree with Home.
      final breakdown = breakdownFor(buildUser(), manual: -4000);
      final summary = breakdown.summary();

      expect(breakdown.totalKcalGoal, lessThan(0));
      expect(summary.total, breakdown.totalKcalGoal.round());
      expect(summary.total, -1335);
      expectRowsAddUp(breakdown);
    });

    test('a goal of exactly zero keeps its rows and sums to 0', () {
      final user = buildUser();
      final tdee = CalorieGoalCalc.getTdee(user);
      // Cancel TDEE − 500 with the manual offset.
      final breakdown = breakdownFor(user, manual: -(tdee - 500));
      final summary = breakdown.summary();

      expect(summary.total, 0);
      expect(termsOf(summary), [
        KcalGoalSummaryTerm.maintenance,
        KcalGoalSummaryTerm.weightGoal,
        KcalGoalSummaryTerm.manualAdjustment,
      ]);
      expectRowsAddUp(breakdown);
    });
  });

  group('rounding', () {
    test('rows always add up to the shown target, in kcal and kJ', () {
      // Fractional TDEE, tapered adjustment and activity kcal: rounding
      // each row on its own drifts from the rounded total for some of
      // these. The summary must not.
      var naiveMismatches = 0;
      for (var weight = 76.0; weight <= 80.0; weight += 0.1) {
        for (var activities = 0.0; activities <= 1.0; activities += 0.1) {
          final breakdown = breakdownFor(
            buildUser(
              weightKG: weight,
              targetWeightKg: 75.0,
              taperEnabled: true,
            ),
            manual: 10.4,
            activities: 100 + activities,
          );
          final naive =
              breakdown.tdeeKcal.round() +
              breakdown.effectiveAdjustmentKcal.round() +
              breakdown.manualKcalAdjustment.round() +
              breakdown.activityKcal.round();
          if (naive != breakdown.totalKcalGoal.round()) naiveMismatches++;
          expectRowsAddUp(breakdown);
        }
      }
      // Guards the test itself: the inputs must include cases where
      // rounding each row separately would not add up.
      expect(naiveMismatches, greaterThan(0));
    });

    test('the first row matches the TDEE shown in step 1', () {
      final breakdown = breakdownFor(buildUser(), activities: 99.6);

      expect(breakdown.summary().rows.first.value, breakdown.tdeeKcal.round());
    });
  });
}
