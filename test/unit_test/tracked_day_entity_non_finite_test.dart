import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/data/dbo/tracked_day_dbo.dart';
import 'package:opennutritracker/core/domain/entity/tracked_day_entity.dart';

/// A day that took in a NaN intake keeps NaN in its running totals on disk
/// (#1254). NaN.toInt() throws in the Trends and Diary cards, so the entity
/// reads a non-finite total as nothing tracked.
void main() {
  group('TrackedDayEntity.fromTrackedDayDBO (#1254)', () {
    test('reads non-finite tracked totals as untracked', () {
      final entity = TrackedDayEntity.fromTrackedDayDBO(
        TrackedDayDBO(
          day: DateTime(2026, 9, 24),
          calorieGoal: 2000,
          caloriesTracked: double.nan,
          carbsGoal: 250,
          carbsTracked: double.nan,
          fatGoal: 70,
          fatTracked: double.infinity,
          proteinGoal: 100,
          proteinTracked: double.nan,
        ),
      );

      expect(entity.caloriesTracked, 0);
      expect(entity.carbsTracked, isNull);
      expect(entity.fatTracked, isNull);
      expect(entity.proteinTracked, isNull);
      // Goals are untouched.
      expect(entity.calorieGoal, 2000);
      expect(entity.carbsGoal, 250);
      expect(entity.fatGoal, 70);
      expect(entity.proteinGoal, 100);
    });

    test('keeps finite tracked totals as they are', () {
      final entity = TrackedDayEntity.fromTrackedDayDBO(
        TrackedDayDBO(
          day: DateTime(2026, 9, 24),
          calorieGoal: 2000,
          caloriesTracked: 1500,
          carbsTracked: 180,
          fatTracked: 0,
          proteinTracked: 90,
        ),
      );

      expect(entity.caloriesTracked, 1500);
      expect(entity.carbsTracked, 180);
      expect(entity.fatTracked, 0);
      expect(entity.proteinTracked, 90);
    });
  });
}
