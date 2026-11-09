import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
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

// #1494: the serving text in the unit field may wrap to three lines at a
// large font. That has to hold in the closed field too, which a dense
// dropdown keeps to one line, without growing the field past the quantity
// field beside it at the default size.

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

MealEntity _product() => MealEntity(
  code: 'unit-field-test',
  name: 'Test product',
  url: null,
  mealQuantity: null,
  mealUnit: 'g',
  servingQuantity: 45,
  servingUnit: 'g',
  servingSize: '1 cup (45 g)',
  nutriments: _nutriments,
  source: MealSourceEntity.off,
);

Future<void> _pumpSheet(WidgetTester tester, double textScale) async {
  // The test font sets every glyph a full em wide, 32 pt at 200%. At this
  // width the serving wraps to two lines: more than a dense field shows,
  // within the three the item allows.
  tester.view.physicalSize = const Size(560, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: const [S.delegate],
      supportedLocales: S.supportedLocales,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      home: Scaffold(
        body: SingleChildScrollView(
          child: MealDetailBottomSheet(
            product: _product(),
            day: DateTime(2026, 9, 13),
            intakeTypeEntity: IntakeTypeEntity.breakfast,
            quantityTextController: TextEditingController(text: '1'),
            mealDetailBloc: _buildBloc(),
            selectedUnit: 'serving',
            usesImperialUnits: false,
            onQuantityOrUnitChanged: (_, _) {},
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Finder _unitField() => find.descendant(
  of: find.byType(DropdownButtonFormField<String>),
  matching: find.byType(InputDecorator),
);

void main() {
  testWidgets('at 200% the closed field shows the whole serving', (
    tester,
  ) async {
    await _pumpSheet(tester, 2.0);

    final paragraph = tester.renderObject<RenderParagraph>(
      find.textContaining('(45').first,
    );
    // A dense field squeezes the text's box to one line and clips the
    // rest; the box has to hold every line the text lays out.
    expect(paragraph.didExceedMaxLines, isFalse);
    expect(
      paragraph.size.height,
      paragraph.getMaxIntrinsicHeight(paragraph.size.width),
    );
  });

  testWidgets('at 100% the unit field is as tall as the quantity field', (
    tester,
  ) async {
    await _pumpSheet(tester, 1.0);

    final quantity = find.descendant(
      of: find.byType(TextFormField),
      matching: find.byType(InputDecorator),
    );
    expect(
      tester.getSize(_unitField().first).height,
      tester.getSize(quantity.first).height,
    );
  });
}
