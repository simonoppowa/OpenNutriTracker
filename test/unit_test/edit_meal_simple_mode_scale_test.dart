import 'package:flutter_test/flutter_test.dart';

import 'package:opennutritracker/features/edit_meal/presentation/bloc/edit_meal_bloc.dart';

/// Regression test for the Simple-mode multiply-by-100 bug.
///
/// Simple mode (#232) lets a user type per-serving totals without
/// fussing with base-quantity or per-100g math. An earlier version of
/// the form passed `baseQuantity = "1"` to `createNewMealEntity`, which
/// made `factorTo100g` resolve to `100/1 = 100` and silently multiplied
/// every typed value by 100 before storing it on `energyKcal100` /
/// `carbohydrates100` / `fat100` / `proteins100`. Round-tripping a
/// 100 kcal save back into the form rendered 10000 kcal.
///
/// The fix passes `"100"` for mealQuantity / servingQuantity /
/// baseQuantity, so `factorTo100g` resolves to 1 and the entered values
/// land in the per-100g fields verbatim. These tests pin the scale
/// factor so the bug can't quietly come back.
void main() {
  group('factorTo100gFromBase (#232 regression)', () {
    test('"100" returns a factor of 1 — values round-trip unchanged', () {
      expect(factorTo100gFromBase('100'), 1.0);
    });

    test('"1" returns a factor of 100 — silently multiplies the typed value', () {
      // Pinned as documentation of the bug shape: any caller that
      // passes "1" while expecting per-100g semantics will store 100x
      // the typed value. Simple mode used to do exactly this.
      expect(factorTo100gFromBase('1'), 100.0);
    });

    test('a 200g base produces 0.5 — halves a per-200g total into per-100g', () {
      expect(factorTo100gFromBase('200'), 0.5);
    });

    test('a 50g base produces 2 — doubles a per-50g total into per-100g', () {
      expect(factorTo100gFromBase('50'), 2.0);
    });

    test('unparseable input falls back to a no-op factor of 1', () {
      expect(factorTo100gFromBase(''), 1.0);
      expect(factorTo100gFromBase('abc'), 1.0);
    });
  });
}
