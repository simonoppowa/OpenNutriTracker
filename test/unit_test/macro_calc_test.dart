import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/utils/calc/macro_calc.dart';

void main() {
  const totalKcal = 2000.0;

  group('MacroCalc defaults', () {
    test('the default split is 60 % carbs, 25 % fat, 15 % protein', () {
      expect(MacroCalc.defaultCarbsPercentageGoal, 0.6);
      expect(MacroCalc.defaultFatsPercentageGoal, 0.25);
      expect(MacroCalc.defaultProteinsPercentageGoal, 0.15);
    });

    test('the default split adds up to the whole calorie goal', () {
      expect(
        MacroCalc.defaultCarbsPercentageGoal +
            MacroCalc.defaultFatsPercentageGoal +
            MacroCalc.defaultProteinsPercentageGoal,
        closeTo(1.0, 1e-9),
      );
    });
  });

  group('MacroCalc.getTotalCarbsGoal', () {
    test('uses the default share when no goal is set', () {
      // 2000 * 0.6 / 4
      expect(MacroCalc.getTotalCarbsGoal(totalKcal), closeTo(300.0, 1e-9));
    });

    test('uses the user share when one is set', () {
      // 2000 * 0.5 / 4
      expect(
        MacroCalc.getTotalCarbsGoal(totalKcal, userCarbsGoal: 0.5),
        closeTo(250.0, 1e-9),
      );
    });

    test('a user share of 0 gives 0 g, not the default', () {
      expect(MacroCalc.getTotalCarbsGoal(totalKcal, userCarbsGoal: 0), 0);
    });
  });

  group('MacroCalc.getTotalFatsGoal', () {
    test('uses the default share when no goal is set', () {
      // 2000 * 0.25 / 9
      expect(MacroCalc.getTotalFatsGoal(totalKcal), closeTo(55.556, 0.001));
    });

    test('uses the user share when one is set', () {
      // 2000 * 0.3 / 9
      expect(
        MacroCalc.getTotalFatsGoal(totalKcal, userFatsGoal: 0.3),
        closeTo(66.667, 0.001),
      );
    });

    test('a user share of 0 gives 0 g, not the default', () {
      expect(MacroCalc.getTotalFatsGoal(totalKcal, userFatsGoal: 0), 0);
    });
  });

  group('MacroCalc.getTotalProteinsGoal', () {
    test('uses the default share when no goal is set', () {
      // 2000 * 0.15 / 4
      expect(MacroCalc.getTotalProteinsGoal(totalKcal), closeTo(75.0, 1e-9));
    });

    test('uses the user share when one is set', () {
      // 2000 * 0.3 / 4
      expect(
        MacroCalc.getTotalProteinsGoal(totalKcal, userProteinsGoal: 0.3),
        closeTo(150.0, 1e-9),
      );
    });

    test('a user share of 0 gives 0 g, not the default', () {
      expect(MacroCalc.getTotalProteinsGoal(totalKcal, userProteinsGoal: 0), 0);
    });
  });

  group('MacroCalc across all three macros', () {
    test('a 0 kcal goal gives 0 g of every macro', () {
      expect(MacroCalc.getTotalCarbsGoal(0), 0);
      expect(MacroCalc.getTotalFatsGoal(0), 0);
      expect(MacroCalc.getTotalProteinsGoal(0), 0);
    });

    test('the default gram goals convert back to the calorie goal', () {
      final kcalFromGrams =
          MacroCalc.getTotalCarbsGoal(totalKcal) * MacroCalc.carbsKcalPerGram +
          MacroCalc.getTotalFatsGoal(totalKcal) * MacroCalc.fatKcalPerGram +
          MacroCalc.getTotalProteinsGoal(totalKcal) *
              MacroCalc.proteinKcalPerGram;

      expect(kcalFromGrams, closeTo(totalKcal, 1e-9));
    });

    test('a custom split that adds up to 100 % converts back too', () {
      // 40 % carbs, 30 % fat, 30 % protein
      final kcalFromGrams =
          MacroCalc.getTotalCarbsGoal(totalKcal, userCarbsGoal: 0.4) *
              MacroCalc.carbsKcalPerGram +
          MacroCalc.getTotalFatsGoal(totalKcal, userFatsGoal: 0.3) *
              MacroCalc.fatKcalPerGram +
          MacroCalc.getTotalProteinsGoal(totalKcal, userProteinsGoal: 0.3) *
              MacroCalc.proteinKcalPerGram;

      expect(kcalFromGrams, closeTo(totalKcal, 1e-9));
    });

    test('gram goals scale linearly with the calorie goal', () {
      expect(
        MacroCalc.getTotalCarbsGoal(totalKcal * 2),
        closeTo(MacroCalc.getTotalCarbsGoal(totalKcal) * 2, 1e-9),
      );
      expect(
        MacroCalc.getTotalFatsGoal(totalKcal * 2),
        closeTo(MacroCalc.getTotalFatsGoal(totalKcal) * 2, 1e-9),
      );
      expect(
        MacroCalc.getTotalProteinsGoal(totalKcal * 2),
        closeTo(MacroCalc.getTotalProteinsGoal(totalKcal) * 2, 1e-9),
      );
    });
  });
}
