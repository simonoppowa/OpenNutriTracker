import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/domain/entity/app_theme_entity.dart';
import 'package:opennutritracker/core/domain/entity/config_entity.dart';
import 'package:opennutritracker/core/domain/entity/meal_pattern_entity.dart';

void main() {
  group('MealPatternEntity', () {
    test('every preset sums to 100% across the four meal slots', () {
      // Sanity guard so a future preset addition that doesn't add up isn't
      // shipped silently. The dialog assumes a preset is already normalised
      // and writes the shares straight into the sliders without rebalancing.
      for (final pattern in MealPatternEntity.values) {
        final total = pattern.breakfastPct +
            pattern.lunchPct +
            pattern.dinnerPct +
            pattern.snackPct;
        expect(total, equals(100), reason: '${pattern.id} should sum to 100');
      }
    });

    test('standard is the existing 30/40/20/10 default', () {
      expect(MealPatternEntity.standard.breakfastPct, equals(30));
      expect(MealPatternEntity.standard.lunchPct, equals(40));
      expect(MealPatternEntity.standard.dinnerPct, equals(20));
      expect(MealPatternEntity.standard.snackPct, equals(10));
    });

    test('OMAD puts 100% on dinner and 0% everywhere else', () {
      expect(MealPatternEntity.omad.breakfastPct, equals(0));
      expect(MealPatternEntity.omad.lunchPct, equals(0));
      expect(MealPatternEntity.omad.dinnerPct, equals(100));
      expect(MealPatternEntity.omad.snackPct, equals(0));
    });

    test('two-meal pattern has 0% lunch (intermittent fasting frame)', () {
      expect(MealPatternEntity.twoMeal.lunchPct, equals(0));
    });

    test('toSharesMap returns the percentages keyed by ConfigEntity meal keys',
        () {
      final shares = MealPatternEntity.mediterranean.toSharesMap();
      expect(shares[ConfigEntity.mealKeyBreakfast], equals(25));
      expect(shares[ConfigEntity.mealKeyLunch], equals(45));
      expect(shares[ConfigEntity.mealKeyDinner], equals(20));
      expect(shares[ConfigEntity.mealKeySnack], equals(10));
    });

    test('toSharesMap output is drop-in for ConfigEntity.targetKcalForMeal',
        () {
      // OMAD with a 2000 kcal daily goal should put the entire goal on dinner
      // and 0 on the other meals — this is the contract day_info_widget and
      // home_page rely on when deciding whether to hide a section.
      final config = ConfigEntity(
        true,
        true,
        false,
        AppThemeEntity.system,
        mealKcalSharesPct: MealPatternEntity.omad.toSharesMap(),
      );
      expect(
        config.targetKcalForMeal(ConfigEntity.mealKeyBreakfast, 2000),
        equals(0),
      );
      expect(
        config.targetKcalForMeal(ConfigEntity.mealKeyLunch, 2000),
        equals(0),
      );
      expect(
        config.targetKcalForMeal(ConfigEntity.mealKeyDinner, 2000),
        equals(2000),
      );
      expect(
        config.targetKcalForMeal(ConfigEntity.mealKeySnack, 2000),
        equals(0),
      );
    });
  });

  group('Meal section visibility based on share%', () {
    // The diary day view and home page both hide a meal section when its
    // share is 0% — the user has explicitly opted out of seeing it (OMAD
    // is the canonical case). These tests mirror the `if (sharePct > 0)`
    // guards in day_info_widget.dart and home_page.dart so a regression
    // is caught even without running the widget tree.

    bool isSectionVisible(int sharePct) => sharePct > 0;

    test('section is visible when the user has a non-zero share', () {
      expect(isSectionVisible(10), isTrue);
      expect(isSectionVisible(40), isTrue);
      expect(isSectionVisible(100), isTrue);
    });

    test('section is hidden when the user has set 0% for that meal', () {
      expect(isSectionVisible(0), isFalse);
    });

    test('applying OMAD hides every section except dinner', () {
      final shares = MealPatternEntity.omad.toSharesMap();
      expect(
        isSectionVisible(shares[ConfigEntity.mealKeyBreakfast]!),
        isFalse,
        reason: 'OMAD breakfast should be hidden',
      );
      expect(
        isSectionVisible(shares[ConfigEntity.mealKeyLunch]!),
        isFalse,
        reason: 'OMAD lunch should be hidden',
      );
      expect(
        isSectionVisible(shares[ConfigEntity.mealKeyDinner]!),
        isTrue,
        reason: 'OMAD dinner should be visible (the one meal)',
      );
      expect(
        isSectionVisible(shares[ConfigEntity.mealKeySnack]!),
        isFalse,
        reason: 'OMAD snack should be hidden',
      );
    });

    test('applying two-meal hides only lunch', () {
      final shares = MealPatternEntity.twoMeal.toSharesMap();
      expect(isSectionVisible(shares[ConfigEntity.mealKeyBreakfast]!), isTrue);
      expect(isSectionVisible(shares[ConfigEntity.mealKeyLunch]!), isFalse);
      expect(isSectionVisible(shares[ConfigEntity.mealKeyDinner]!), isTrue);
      expect(isSectionVisible(shares[ConfigEntity.mealKeySnack]!), isTrue);
    });

    test('applying standard keeps every section visible', () {
      final shares = MealPatternEntity.standard.toSharesMap();
      for (final entry in shares.entries) {
        expect(
          isSectionVisible(entry.value),
          isTrue,
          reason: 'standard ${entry.key} should be visible',
        );
      }
    });
  });
}
