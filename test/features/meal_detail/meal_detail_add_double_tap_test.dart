import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:opennutritracker/core/data/data_source/remote_search_cache_data_source.dart';
import 'package:opennutritracker/core/domain/entity/intake_entity.dart';
import 'package:opennutritracker/core/domain/entity/intake_type_entity.dart';
import 'package:opennutritracker/core/domain/usecase/add_intake_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/add_tracked_day_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_intake_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_kcal_goal_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_macro_goal_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_tracked_day_usecase.dart';
import 'package:opennutritracker/features/add_meal/data/repository/products_repository.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_nutriments_entity.dart';
import 'package:opennutritracker/features/diary/presentation/bloc/calendar_day_bloc.dart';
import 'package:opennutritracker/features/diary/presentation/bloc/diary_bloc.dart';
import 'package:opennutritracker/features/home/presentation/bloc/home_bloc.dart';
import 'package:opennutritracker/features/meal_detail/presentation/bloc/meal_detail_bloc.dart';
import 'package:opennutritracker/features/meal_detail/presentation/widgets/meal_detail_bottom_sheet.dart';
import 'package:opennutritracker/generated/l10n.dart';

class _FakeAddIntakeUsecase extends Fake implements AddIntakeUsecase {}

class _FakeAddTrackedDayUsecase extends Fake implements AddTrackedDayUsecase {}

class _FakeGetKcalGoalUsecase extends Fake implements GetKcalGoalUsecase {}

class _FakeGetMacroGoalUsecase extends Fake implements GetMacroGoalUsecase {}

class _FakeGetTrackedDayUsecase extends Fake implements GetTrackedDayUsecase {}

class _FakeProductsRepository extends Fake implements ProductsRepository {}

class _FakeRemoteSearchCacheDataSource extends Fake
    implements RemoteSearchCacheDataSource {}

/// Nothing logged yet, so the duplicate check lets every tap through.
class _NothingLoggedGetIntakeUsecase extends Fake implements GetIntakeUsecase {
  @override
  Future<List<IntakeEntity>> getBreakfastIntakeByDay(
    DateTime day, {
    int dayStartOffsetHours = 0,
    int dayStartOffsetMinutes = 0,
  }) async => [];
}

class _FakeHomeBloc extends Fake implements HomeBloc {
  @override
  void add(HomeEvent event) {}
}

class _FakeDiaryBloc extends Fake implements DiaryBloc {
  @override
  void add(DiaryEvent event) {}
}

class _FakeCalendarDayBloc extends Fake implements CalendarDayBloc {
  @override
  void add(CalendarDayEvent event) {}
}

/// Counts the intakes it is asked to store, and holds each save open
/// until [save] completes, as a write waiting for the tracked-day lock.
class _GatedMealDetailBloc extends MealDetailBloc {
  _GatedMealDetailBloc()
    : super(
        _FakeAddIntakeUsecase(),
        _FakeAddTrackedDayUsecase(),
        _FakeGetKcalGoalUsecase(),
        _FakeGetMacroGoalUsecase(),
        _FakeGetTrackedDayUsecase(),
        _FakeProductsRepository(),
        _FakeRemoteSearchCacheDataSource(),
      );

  final save = Completer<void>();
  var saves = 0;

  @override
  Future<void> addIntake(
    BuildContext context,
    String unit,
    String amountText,
    IntakeTypeEntity type,
    MealEntity meal,
    DateTime day,
  ) {
    saves++;
    return save.future;
  }
}

final _toast = MealEntity(
  code: 'toast',
  name: 'Toast',
  url: null,
  mealQuantity: null,
  mealUnit: 'g',
  servingQuantity: null,
  servingUnit: 'g',
  servingSize: null,
  nutriments: const MealNutrimentsEntity(
    energyKcal100: 200,
    carbohydrates100: 40,
    fat100: 2,
    proteins100: 6,
    sugars100: null,
    saturatedFat100: null,
    fiber100: null,
  ),
  source: MealSourceEntity.custom,
);

/// #1317 review: the save can wait for the tracked-day lock with the sheet
/// still open, so Add has to take one tap per meal.
void main() {
  setUp(() {
    GetIt.instance
      ..registerFactory<GetIntakeUsecase>(_NothingLoggedGetIntakeUsecase.new)
      ..registerFactory<HomeBloc>(_FakeHomeBloc.new)
      ..registerFactory<DiaryBloc>(_FakeDiaryBloc.new)
      ..registerFactory<CalendarDayBloc>(_FakeCalendarDayBloc.new);
  });

  tearDown(() => GetIt.instance.reset());

  testWidgets('a second tap while the save is pending logs the meal once', (
    tester,
  ) async {
    final bloc = _GatedMealDetailBloc();
    addTearDown(bloc.close);
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [S.delegate],
        supportedLocales: S.supportedLocales,
        home: Scaffold(
          body: MealDetailBottomSheet(
            product: _toast,
            day: DateTime(2026, 10, 5),
            intakeTypeEntity: IntakeTypeEntity.breakfast,
            quantityTextController: TextEditingController(text: '100'),
            mealDetailBloc: bloc,
            selectedUnit: 'g',
            onQuantityOrUnitChanged: (_, _) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final add = find.byIcon(Icons.add_rounded);

    await tester.tap(add);
    await tester.tap(add, warnIfMissed: false);
    await tester.pump();
    await tester.tap(add, warnIfMissed: false);
    await tester.pump();

    expect(bloc.saves, 1);
    final button = tester.widget<ButtonStyleButton>(
      find.ancestor(of: add, matching: find.bySubtype<ButtonStyleButton>()),
    );
    expect(button.onPressed, isNull);

    bloc.save.complete();
    await tester.pumpAndSettle();
    expect(bloc.saves, 1);
  });
}
