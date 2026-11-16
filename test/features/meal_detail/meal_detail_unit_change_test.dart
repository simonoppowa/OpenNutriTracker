import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/data/data_source/remote_search_cache_data_source.dart';
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
import 'package:opennutritracker/features/meal_detail/presentation/widgets/meal_detail_bottom_sheet.dart';
import 'package:opennutritracker/features/meal_detail/util/unit_change.dart';
import 'package:opennutritracker/generated/l10n.dart';

import '../../helpers/test_l10n.dart';

class _FakeAddIntakeUsecase extends Fake implements AddIntakeUsecase {}

class _FakeAddTrackedDayUsecase extends Fake implements AddTrackedDayUsecase {}

class _FakeGetKcalGoalUsecase extends Fake implements GetKcalGoalUsecase {}

class _FakeGetMacroGoalUsecase extends Fake implements GetMacroGoalUsecase {}

class _FakeGetTrackedDayUsecase extends Fake implements GetTrackedDayUsecase {}

class _FakeProductsRepository extends Fake implements ProductsRepository {}

class _FakeRemoteSearchCacheDataSource extends Fake
    implements RemoteSearchCacheDataSource {}

MealEntity _food({double? serving = 180}) => MealEntity(
  code: 'rice',
  name: 'Rice',
  url: null,
  mealQuantity: null,
  mealUnit: 'g',
  servingQuantity: serving,
  servingUnit: 'g',
  servingSize: null,
  nutriments: const MealNutrimentsEntity(
    energyKcal100: 130,
    carbohydrates100: 28,
    fat100: 0.3,
    proteins100: 2.7,
    sugars100: null,
    saturatedFat100: null,
    fiber100: null,
  ),
  source: MealSourceEntity.custom,
);

/// Changing the unit keeps the amount of food, not the number typed.
void main() {
  group('amountInUnit', () {
    test('keeps what the amount weighs', () {
      final food = _food();
      expect(amountInUnit('180', 'g', 'serving', food), '1');
      expect(amountInUnit('1', 'serving', 'g', food), '180');
      expect(amountInUnit('30', 'g', 'serving', food), '0.2');
      expect(amountInUnit('1', 'oz', 'g', food), '28');
      expect(amountInUnit('100,5', 'g', 'g/ml', food), '101');
    });

    test('never rounds a small amount to nothing', () {
      expect(amountInUnit('4', 'g', 'serving', _food(serving: 100)), '0.04');
      expect(amountInUnit('0.1', 'g', 'serving', _food(serving: 100)), '0.01');
      expect(amountInUnit('0.2', 'g', 'g/ml', _food()), '1');
    });

    test('converts no amount to nothing', () {
      expect(amountInUnit('', 'g', 'serving', _food()), isNull);
      expect(amountInUnit('0', 'g', 'serving', _food()), isNull);
      expect(amountInUnit('abc', 'g', 'serving', _food()), isNull);
    });
  });

  testWidgets('picking a serving for 180 g of a 180 g serving gives 1', (
    tester,
  ) async {
    final bloc = MealDetailBloc(
      _FakeAddIntakeUsecase(),
      _FakeAddTrackedDayUsecase(),
      _FakeGetKcalGoalUsecase(),
      _FakeGetMacroGoalUsecase(),
      _FakeGetTrackedDayUsecase(),
      _FakeProductsRepository(),
      _FakeRemoteSearchCacheDataSource(),
    );
    addTearDown(bloc.close);
    final controller = TextEditingController(text: '180');
    addTearDown(controller.dispose);
    final changes = <(String?, String?)>[];

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [S.delegate],
        supportedLocales: S.supportedLocales,
        home: Scaffold(
          body: MealDetailBottomSheet(
            product: _food(),
            day: DateTime(2026, 10, 5),
            intakeTypeEntity: IntakeTypeEntity.lunch,
            quantityTextController: controller,
            mealDetailBloc: bloc,
            selectedUnit: 'g',
            onQuantityOrUnitChanged: (quantity, unit) =>
                changes.add((quantity, unit)),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining(l10nEn.servingLabel).last);
    await tester.pumpAndSettle();

    expect(controller.text, '1');
    // One change, already in the new unit: never 1 g, never 180 servings.
    expect(changes, [('1', 'serving')]);
  });
}
