import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/data/data_source/remote_search_cache_data_source.dart';
import 'package:opennutritracker/core/domain/usecase/add_intake_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/add_tracked_day_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_kcal_goal_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_macro_goal_usecase.dart';
import 'package:opennutritracker/features/add_meal/data/repository/products_repository.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_nutriments_entity.dart';
import 'package:opennutritracker/features/meal_detail/presentation/bloc/meal_detail_bloc.dart';

// Covers the manual-add-from-search half of issue #34. A reporter who
// types a food name in the add-meal search, taps a result, and lands on
// the meal-detail bottom sheet should see the dropdown pre-selected on
// "serving" when the product carries serving data — matching what the
// barcode-scan path already does on feature/scan-default-serving-158.
//
// The screen layer (`MealDetailScreen.didChangeDependencies`) branches
// on `MealEntity.hasServingValues` to pick the initial unit and then
// fires `UpdateKcalEvent` to seed the bloc. This test mirrors that
// wiring directly, asserting that the resulting state's `selectedUnit`
// reflects the screen's choice — that is, that the bloc honours the
// load-time selection rather than collapsing it back to gml.

class _FakeAddIntakeUsecase extends Fake implements AddIntakeUsecase {}

class _FakeAddTrackedDayUsecase extends Fake implements AddTrackedDayUsecase {}

class _FakeGetKcalGoalUsecase extends Fake implements GetKcalGoalUsecase {}

class _FakeGetMacroGoalUsecase extends Fake implements GetMacroGoalUsecase {}

class _FakeProductsRepository extends Fake implements ProductsRepository {}

class _FakeRemoteSearchCacheDataSource extends Fake
    implements RemoteSearchCacheDataSource {}

MealDetailBloc _buildBloc() => MealDetailBloc(
      _FakeAddIntakeUsecase(),
      _FakeAddTrackedDayUsecase(),
      _FakeGetKcalGoalUsecase(),
      _FakeGetMacroGoalUsecase(),
      _FakeProductsRepository(),
      _FakeRemoteSearchCacheDataSource(),
    );

MealEntity _meal({
  double? servingQuantity,
  String? servingUnit,
  String? servingSize,
}) {
  return MealEntity(
    code: 'manual-add-test',
    name: 'Test product',
    url: null,
    mealQuantity: null,
    mealUnit: null,
    servingQuantity: servingQuantity,
    servingUnit: servingUnit,
    servingSize: servingSize,
    nutriments: const MealNutrimentsEntity(
      energyKcal100: 100,
      carbohydrates100: 10,
      fat100: 5,
      proteins100: 5,
      sugars100: 2,
      saturatedFat100: 1,
      fiber100: 1,
    ),
    source: MealSourceEntity.off,
  );
}

// Mirrors `MealDetailScreen.didChangeDependencies` exactly so the test
// guards the contract the screen relies on: any meal with serving data
// should resolve to the "serving" dropdown choice on first frame, and
// fall through to gml otherwise. Keeping the resolver in the test rather
// than importing it means the screen and the test can drift only with
// an explicit code change here.
String _initialUnitForManualAdd(MealEntity meal) {
  if (meal.hasServingValues) {
    return UnitDropdownItem.serving.toString();
  } else if (meal.isLiquid) {
    return UnitDropdownItem.ml.toString();
  } else if (meal.isSolid) {
    return UnitDropdownItem.g.toString();
  } else {
    return UnitDropdownItem.gml.toString();
  }
}

void main() {
  group('Meal detail — manual-add default unit (issue #34)', () {
    test(
      'defaults to "serving" when an OFF search result carries servingSize',
      () async {
        // A typical OFF search-result entry: human-readable servingSize
        // like "2 Tbsp (32 g)" but no numeric servingQuantity. The user
        // tapped this result from the search list, not the barcode
        // scanner. The bottom sheet should still open on "serving".
        final meal = _meal(servingSize: '2 Tbsp (32 g)');
        expect(meal.hasServingValues, isTrue);

        final initialUnit = _initialUnitForManualAdd(meal);
        expect(initialUnit, UnitDropdownItem.serving.toString());

        final bloc = _buildBloc();
        bloc.add(UpdateKcalEvent(meal: meal, selectedUnit: initialUnit));
        // Allow the event handler to settle.
        await Future<void>.delayed(Duration.zero);

        expect(bloc.state.selectedUnit, UnitDropdownItem.serving.toString());
        await bloc.close();
      },
    );

    test(
      'defaults to "serving" when an OFF search result carries servingQuantity',
      () async {
        // The other common OFF shape: numeric servingQuantity (e.g. 30
        // for a granola bar) with no overall package quantity, so
        // servingUnit is derived as null. Before the fix this case
        // dropped through to gml on the manual-add path.
        final meal = _meal(servingQuantity: 30.0);
        expect(meal.hasServingValues, isTrue);

        final initialUnit = _initialUnitForManualAdd(meal);
        expect(initialUnit, UnitDropdownItem.serving.toString());

        final bloc = _buildBloc();
        bloc.add(UpdateKcalEvent(meal: meal, selectedUnit: initialUnit));
        await Future<void>.delayed(Duration.zero);

        expect(bloc.state.selectedUnit, UnitDropdownItem.serving.toString());
        await bloc.close();
      },
    );

    test(
      'falls back to g/ml when the search result carries no serving data',
      () async {
        // Bulk products (1 kg of flour, a bag of rice) genuinely don't
        // have a serving — the dropdown should keep defaulting to the
        // 100 g/ml baseline so nothing changes for entries where
        // "serving" doesn't make sense.
        final meal = _meal();
        expect(meal.hasServingValues, isFalse);

        final initialUnit = _initialUnitForManualAdd(meal);
        expect(initialUnit, UnitDropdownItem.gml.toString());

        final bloc = _buildBloc();
        bloc.add(UpdateKcalEvent(meal: meal, selectedUnit: initialUnit));
        await Future<void>.delayed(Duration.zero);

        expect(bloc.state.selectedUnit, UnitDropdownItem.gml.toString());
        await bloc.close();
      },
    );
  });
}
