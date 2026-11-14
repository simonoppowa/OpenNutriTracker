import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/data/data_source/remote_search_cache_data_source.dart';
import 'package:opennutritracker/core/domain/usecase/add_intake_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/add_tracked_day_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_kcal_goal_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_macro_goal_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_tracked_day_usecase.dart';
import 'package:opennutritracker/features/add_meal/data/repository/products_repository.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_nutriments_entity.dart';
import 'package:opennutritracker/features/meal_detail/presentation/bloc/meal_detail_bloc.dart';

// A unit picked while the amount field is blank used to be dropped: the
// bloc returned early on the blank amount without storing the unit, so the
// amount typed next (sent with the bloc's own selectedUnit) was read in the
// old unit.

class _FakeAddIntakeUsecase extends Fake implements AddIntakeUsecase {}

class _FakeAddTrackedDayUsecase extends Fake implements AddTrackedDayUsecase {}

class _FakeGetKcalGoalUsecase extends Fake implements GetKcalGoalUsecase {}

class _FakeGetMacroGoalUsecase extends Fake implements GetMacroGoalUsecase {}

class _FakeGetTrackedDayUsecase extends Fake implements GetTrackedDayUsecase {}

class _FakeProductsRepository extends Fake implements ProductsRepository {}

class _FakeRemoteSearchCacheDataSource extends Fake
    implements RemoteSearchCacheDataSource {}

MealDetailBloc _buildBloc() => MealDetailBloc(
  _FakeAddIntakeUsecase(),
  _FakeAddTrackedDayUsecase(),
  _FakeGetKcalGoalUsecase(),
  _FakeGetMacroGoalUsecase(),
  _FakeGetTrackedDayUsecase(),
  _FakeProductsRepository(),
  _FakeRemoteSearchCacheDataSource(),
);

MealEntity _food() => MealEntity(
  code: 'unit-blank-amount-test',
  name: 'Test product',
  url: null,
  mealQuantity: null,
  mealUnit: 'g',
  servingQuantity: 180,
  servingUnit: 'g',
  servingSize: null,
  nutriments: const MealNutrimentsEntity(
    energyKcal100: 100,
    carbohydrates100: 10,
    fat100: 5,
    proteins100: 5,
    sugars100: 2,
    saturatedFat100: 1,
    fiber100: 1,
  ),
  source: MealSourceEntity.custom,
);

void main() {
  test('a unit picked while the amount is blank is kept', () async {
    final bloc = _buildBloc();
    addTearDown(bloc.close);
    final serving = UnitDropdownItem.serving.toString();

    bloc.add(
      UpdateKcalEvent(meal: _food(), totalQuantity: '', selectedUnit: serving),
    );
    await Future<void>.delayed(Duration.zero);

    expect(bloc.state.selectedUnit, serving);
  });

  test('the amount typed next is read in the picked unit', () async {
    final bloc = _buildBloc();
    addTearDown(bloc.close);
    final serving = UnitDropdownItem.serving.toString();

    bloc.add(
      UpdateKcalEvent(meal: _food(), totalQuantity: '', selectedUnit: serving),
    );
    await Future<void>.delayed(Duration.zero);
    // The screen sends a typed amount with the bloc's current unit.
    bloc.add(
      UpdateKcalEvent(
        meal: _food(),
        totalQuantity: '1',
        selectedUnit: bloc.state.selectedUnit,
      ),
    );
    await Future<void>.delayed(Duration.zero);

    expect(bloc.state.selectedUnit, serving);
    expect(double.parse(bloc.state.totalQuantityConverted), 180);
    expect(bloc.state.totalKcal, 180);
  });
}
