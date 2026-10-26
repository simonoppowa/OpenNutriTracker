import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/domain/entity/tracked_day_entity.dart';
import 'package:opennutritracker/core/data/data_source/remote_search_cache_data_source.dart';
import 'package:opennutritracker/core/data/dbo/meal_dbo.dart';
import 'package:opennutritracker/core/domain/entity/intake_entity.dart';
import 'package:opennutritracker/core/domain/entity/intake_type_entity.dart';
import 'package:opennutritracker/core/domain/usecase/add_intake_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/add_tracked_day_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_kcal_goal_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_macro_goal_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_tracked_day_usecase.dart';
import 'package:opennutritracker/features/add_meal/data/repository/products_repository.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_nutriments_entity.dart';
import 'package:opennutritracker/features/meal_detail/presentation/bloc/meal_detail_bloc.dart';

import '../../helpers/fake_favourites.dart';

class _FakeAddIntakeUsecase extends Fake implements AddIntakeUsecase {
  @override
  Future<void> addIntake(IntakeEntity intakeEntity) async {}
}

class _FakeAddTrackedDayUsecase extends Fake implements AddTrackedDayUsecase {
  @override
  Future<bool> hasTrackedDay(DateTime day) async => true;

  @override
  Future<void> addDayCaloriesTracked(
    DateTime day,
    double caloriesTracked,
  ) async {}

  @override
  Future<void> addDayMacrosTracked(
    DateTime day, {
    double? carbsTracked,
    double? fatTracked,
    double? proteinTracked,
  }) async {}
}

class _FakeGetKcalGoalUsecase extends Fake implements GetKcalGoalUsecase {}

class _FakeGetMacroGoalUsecase extends Fake implements GetMacroGoalUsecase {}

/// `addIntake` reads the day's totals before adding to them, to restore
/// them if the update fails (#1461); nothing here exercises that.
class _FakeGetTrackedDayUsecase extends Fake implements GetTrackedDayUsecase {
  @override
  Future<TrackedDayEntity?> getTrackedDay(DateTime day) async => null;
}

class _FakeProductsRepository extends Fake implements ProductsRepository {
  _FakeProductsRepository(this.fresh);

  final MealEntity fresh;

  @override
  Future<MealEntity> getOFFProductByBarcode(
    String barcode, {
    String? knownName,
  }) async => fresh;
}

class _FakeRemoteSearchCache extends Fake
    implements RemoteSearchCacheDataSource {
  final cached = Completer<void>();

  @override
  Future<void> cache(MealDBO meal) async {
    if (!cached.isCompleted) cached.complete();
  }
}

class _FakeContext extends Fake implements BuildContext {}

MealEntity _offMeal(double kcal) => MealEntity(
  code: '0080457761112',
  name: 'Crisps',
  url: null,
  mealQuantity: '100',
  mealUnit: 'g',
  servingQuantity: 30,
  servingUnit: 'g',
  servingSize: null,
  nutriments: MealNutrimentsEntity(
    energyKcal100: kcal,
    carbohydrates100: null,
    fat100: null,
    proteins100: null,
    sugars100: null,
    saturatedFat100: null,
    fiber100: null,
  ),
  source: MealSourceEntity.off,
  detailed: true,
);

/// #1307: logging an Open Food Facts food fetches the product again in the
/// background. A favourite on it takes the fresh record, as a live scan
/// does, rather than logging and exporting the figures it was starred with.
void main() {
  late FakeFavourites favourites;
  late _FakeRemoteSearchCache cache;

  setUp(() {
    favourites = FakeFavourites();
    cache = _FakeRemoteSearchCache();
  });

  tearDown(() => favourites.dispose());

  MealDetailBloc build(MealEntity fresh) => MealDetailBloc(
    _FakeAddIntakeUsecase(),
    _FakeAddTrackedDayUsecase(),
    _FakeGetKcalGoalUsecase(),
    _FakeGetMacroGoalUsecase(),
    _FakeGetTrackedDayUsecase(),
    _FakeProductsRepository(fresh),
    cache,
    favourites: favourites.toggle,
  );

  Future<void> log(MealDetailBloc bloc, MealEntity meal) async {
    await bloc.addIntake(
      _FakeContext(),
      'g',
      '100',
      IntakeTypeEntity.breakfast,
      meal,
      DateTime(2026, 10, 4, 12),
    );
    // The refresh runs unawaited after the intake is written.
    await cache.cached.future;
    for (var i = 0; i < 3; i++) {
      await Future<void>.delayed(Duration.zero);
    }
  }

  test('a starred food logged from its stored snapshot takes the fresh '
      'record', () async {
    final starred = _offMeal(100);
    favourites.add(starred);
    final bloc = build(_offMeal(120));
    addTearDown(bloc.close);

    await log(bloc, starred);

    expect(favourites.stored(starred)!.nutriments.energyKcal100, 120);
  });

  test('a food that is not starred stays unstarred', () async {
    final bloc = build(_offMeal(120));
    addTearDown(bloc.close);

    await log(bloc, _offMeal(100));

    expect(favourites.all, isEmpty);
  });
}
