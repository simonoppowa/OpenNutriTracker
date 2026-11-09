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

import '../../helpers/test_l10n.dart';

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
  void add(HomeEvent event) => homeRefreshes++;
}

var homeRefreshes = 0;

class _FakeDiaryBloc extends Fake implements DiaryBloc {
  @override
  void add(DiaryEvent event) {}
}

class _FakeCalendarDayBloc extends Fake implements CalendarDayBloc {
  @override
  void add(CalendarDayEvent event) {}
}

/// Answers every add the way [outcome] says: stored, dropped by a profile
/// switch, or failed.
class _OutcomeMealDetailBloc extends MealDetailBloc {
  _OutcomeMealDetailBloc(this.outcome)
    : super(
        _FakeAddIntakeUsecase(),
        _FakeAddTrackedDayUsecase(),
        _FakeGetKcalGoalUsecase(),
        _FakeGetMacroGoalUsecase(),
        _FakeGetTrackedDayUsecase(),
        _FakeProductsRepository(),
        _FakeRemoteSearchCacheDataSource(),
      );

  final Future<bool> Function() outcome;

  @override
  Future<bool> addIntake(
    BuildContext context,
    String unit,
    String amountText,
    IntakeTypeEntity type,
    MealEntity meal,
    DateTime day,
  ) => outcome();
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

/// Add on the food page says "Added" only for a food that was stored.
void main() {
  setUp(() {
    homeRefreshes = 0;
    GetIt.instance
      ..registerFactory<GetIntakeUsecase>(_NothingLoggedGetIntakeUsecase.new)
      ..registerFactory<HomeBloc>(_FakeHomeBloc.new)
      ..registerFactory<DiaryBloc>(_FakeDiaryBloc.new)
      ..registerFactory<CalendarDayBloc>(_FakeCalendarDayBloc.new);
  });

  tearDown(() => GetIt.instance.reset());

  /// Opens the sheet on a page above Home, as the food page is, and taps
  /// Add.
  Future<void> tapAdd(WidgetTester tester, MealDetailBloc bloc) async {
    addTearDown(bloc.close);
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [S.delegate],
        supportedLocales: S.supportedLocales,
        onGenerateInitialRoutes: (_) => [
          MaterialPageRoute<void>(
            builder: (_) => const Scaffold(body: Text('home')),
          ),
          MaterialPageRoute<void>(
            builder: (_) => Scaffold(
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
        ],
        onGenerateRoute: (_) => null,
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.add_rounded));
    await tester.pumpAndSettle();
  }

  testWidgets('a stored food says Added and goes back', (tester) async {
    await tapAdd(tester, _OutcomeMealDetailBloc(() async => true));

    expect(find.text(l10nEn.infoAddedIntakeLabel), findsOneWidget);
    expect(find.text('home'), findsOneWidget);
    expect(homeRefreshes, 1);
  });

  testWidgets('a failed write says so and stays on the page', (tester) async {
    await tapAdd(
      tester,
      _OutcomeMealDetailBloc(() async => throw StateError('disk full')),
    );

    expect(find.text(l10nEn.infoIntakeNotSavedLabel), findsOneWidget);
    expect(find.text(l10nEn.infoAddedIntakeLabel), findsNothing);
    expect(find.byType(MealDetailBottomSheet), findsOneWidget);
    expect(homeRefreshes, 0);
    // Add can be tapped again.
    final button = tester.widget<ButtonStyleButton>(
      find.ancestor(
        of: find.byIcon(Icons.add_rounded),
        matching: find.bySubtype<ButtonStyleButton>(),
      ),
    );
    expect(button.onPressed, isNotNull);
  });

  testWidgets('a write a profile switch dropped says so and stays on the '
      'page', (tester) async {
    await tapAdd(tester, _OutcomeMealDetailBloc(() async => false));

    expect(find.text(l10nEn.infoIntakeProfileChangedLabel), findsOneWidget);
    expect(find.text(l10nEn.infoAddedIntakeLabel), findsNothing);
    expect(find.byType(MealDetailBottomSheet), findsOneWidget);
    expect(homeRefreshes, 0);
  });
}
