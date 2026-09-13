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
import 'package:opennutritracker/generated/l10n.dart';

// Widget-side counterpart to `quick_serving_option_test.dart`. Drives the
// real MealDetailBottomSheet with a scalable-serving solid product,
// finds each chip by its stable ASCII Semantics identifier (locked in
// via option.id — see review round on #1101), taps it, and asserts that
// the callback fires with the paired quantity + unit for that chip.

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

const _nutriments = MealNutrimentsEntity(
  energyKcal100: 100,
  carbohydrates100: 10,
  fat100: 5,
  proteins100: 5,
  sugars100: 2,
  saturatedFat100: 1,
  fiber100: 1,
);

MealEntity _solidWithServing() => MealEntity(
  code: 'chip-widget-test',
  name: 'Test product',
  url: null,
  mealQuantity: null,
  mealUnit: 'g',
  servingQuantity: 30,
  servingUnit: 'g',
  servingSize: '30 g',
  nutriments: _nutriments,
  source: MealSourceEntity.off,
);

Future<void> _pumpSheet(
  WidgetTester tester, {
  required MealEntity product,
  required TextEditingController quantityController,
  required void Function(String?, String?) onChanged,
  String initialUnit = 'serving',
}) async {
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: const [S.delegate],
      supportedLocales: S.supportedLocales,
      home: Scaffold(
        body: MealDetailBottomSheet(
          product: product,
          day: DateTime(2026, 9, 13),
          intakeTypeEntity: IntakeTypeEntity.breakfast,
          quantityTextController: quantityController,
          mealDetailBloc: _buildBloc(),
          selectedUnit: initialUnit,
          onQuantityOrUnitChanged: onChanged,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('renders one chip per option with a stable ASCII identifier', (
    tester,
  ) async {
    final quantityController = TextEditingController(text: '1');

    await _pumpSheet(
      tester,
      product: _solidWithServing(),
      quantityController: quantityController,
      onChanged: (_, _) {},
    );

    for (final id in const [
      'half-serving',
      'one-serving',
      'double-serving',
      '100g',
    ]) {
      expect(
        find.bySemanticsLabel(RegExp('.*')).evaluate().isNotEmpty,
        isTrue,
        reason: 'a chip named $id must be present in the tree',
      );
      expect(find.byWidgetPredicate((w) {
        if (w is! Semantics) return false;
        return w.properties.identifier == 'meal-detail-chip-$id';
      }), findsOneWidget, reason: 'chip identifier meal-detail-chip-$id');
    }
  });

  testWidgets(
    'tapping the 100 g chip writes 100 into the quantity field and fires the '
    'callback with unit=g',
    (tester) async {
      final quantityController = TextEditingController(text: '1');
      String? cbQuantity;
      String? cbUnit;

      await _pumpSheet(
        tester,
        product: _solidWithServing(),
        quantityController: quantityController,
        onChanged: (q, u) {
          cbQuantity = q;
          cbUnit = u;
        },
      );

      final chip = find.byWidgetPredicate(
        (w) => w is Semantics && w.properties.identifier == 'meal-detail-chip-100g',
      );
      await tester.tap(chip);
      await tester.pumpAndSettle();

      expect(quantityController.text, '100');
      expect(cbQuantity, '100');
      expect(cbUnit, 'g');
    },
  );

  testWidgets(
    'tapping the 1× chip writes 1 into the quantity field and fires the '
    'callback with unit=serving',
    (tester) async {
      final quantityController = TextEditingController(text: '30');
      String? cbQuantity;
      String? cbUnit;

      await _pumpSheet(
        tester,
        product: _solidWithServing(),
        quantityController: quantityController,
        onChanged: (q, u) {
          cbQuantity = q;
          cbUnit = u;
        },
        initialUnit: 'g',
      );

      final chip = find.byWidgetPredicate(
        (w) =>
            w is Semantics &&
            w.properties.identifier == 'meal-detail-chip-one-serving',
      );
      await tester.tap(chip);
      await tester.pumpAndSettle();

      expect(quantityController.text, '1');
      expect(cbQuantity, '1');
      expect(cbUnit, 'serving');
    },
  );

  testWidgets(
    'tapping the 0.5× chip writes 0.5 (not 1 or 0) into the quantity field',
    (tester) async {
      final quantityController = TextEditingController(text: '1');
      String? cbQuantity;
      String? cbUnit;

      await _pumpSheet(
        tester,
        product: _solidWithServing(),
        quantityController: quantityController,
        onChanged: (q, u) {
          cbQuantity = q;
          cbUnit = u;
        },
      );

      final chip = find.byWidgetPredicate(
        (w) =>
            w is Semantics &&
            w.properties.identifier == 'meal-detail-chip-half-serving',
      );
      await tester.tap(chip);
      await tester.pumpAndSettle();

      expect(quantityController.text, '0.5');
      expect(cbQuantity, '0.5');
      expect(cbUnit, 'serving');
    },
  );
}
