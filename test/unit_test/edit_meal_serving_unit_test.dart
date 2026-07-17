import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/data/data_source/custom_meal_data_source.dart';
import 'package:opennutritracker/core/data/repository/config_repository.dart';
import 'package:opennutritracker/core/domain/usecase/get_config_usecase.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/edit_meal/presentation/bloc/edit_meal_bloc.dart';

/// Regression test for #495 — custom-food serving size.
///
/// The custom-meal form has a single unit selector shared by the meal size
/// and the serving size. `createNewMealEntity` used to store the serving
/// *quantity* text in `servingUnit` (so a 50 g serving saved its unit as the
/// string "50"). The meal-detail serving option then read "Serving (50.0 50)"
/// instead of "Serving (50 g)", and the per-serving header carried the same
/// garbled unit. This pins the serving unit to the selected unit.
///
/// The fakes are unused stand-ins — `createNewMealEntity` is a pure transform
/// over its arguments and touches none of the bloc's dependencies.
class _FakeGetConfigUsecase implements GetConfigUsecase {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeCustomMealDataSource implements CustomMealDataSource {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeConfigRepository implements ConfigRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('createNewMealEntity serving unit (#495)', () {
    late EditMealBloc bloc;

    setUp(() {
      bloc = EditMealBloc(
        _FakeGetConfigUsecase(),
        _FakeCustomMealDataSource(),
        _FakeConfigRepository(),
      );
    });

    tearDown(() async {
      await bloc.close();
    });

    MealEntity build({required String servingQuantity, required String unit}) {
      return bloc.createNewMealEntity(
        MealEntity.empty(),
        'Tomato',
        '',
        '100', // meal size
        servingQuantity,
        '100', // base quantity
        unit,
        '18', // kcal
        '4', // carbs
        '0', // fat
        '1', // protein
      );
    }

    test('serving unit is the selected unit, not the serving quantity text',
        () {
      final meal = build(servingQuantity: '50', unit: 'g');
      expect(meal.servingUnit, 'g');
      expect(meal.servingQuantity, 50);
      // The old bug stored the quantity text as the unit.
      expect(meal.servingUnit, isNot('50'));
    });

    test('serving and meal units agree (one shared selector)', () {
      final meal = build(servingQuantity: '30', unit: 'ml');
      expect(meal.servingUnit, 'ml');
      expect(meal.mealUnit, 'ml');
    });

    test('the g/ml default unit is preserved on the serving', () {
      final meal = build(servingQuantity: '100', unit: 'g/ml');
      expect(meal.servingUnit, 'g/ml');
    });
  });
}
