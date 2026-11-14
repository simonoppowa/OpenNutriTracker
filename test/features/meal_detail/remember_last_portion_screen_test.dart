import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:opennutritracker/core/data/data_source/remote_search_cache_data_source.dart';
import 'package:opennutritracker/core/data/dbo/meal_dbo.dart';
import 'package:opennutritracker/core/domain/entity/app_theme_entity.dart';
import 'package:opennutritracker/core/domain/entity/config_entity.dart';
import 'package:opennutritracker/core/domain/entity/intake_entity.dart';
import 'package:opennutritracker/core/domain/entity/intake_type_entity.dart';
import 'package:opennutritracker/core/domain/entity/tracked_day_entity.dart';
import 'package:opennutritracker/core/domain/usecase/add_intake_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/add_tracked_day_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_config_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_intake_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_kcal_goal_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_macro_goal_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_tracked_day_usecase.dart';
import 'package:opennutritracker/core/utils/energy_unit_provider.dart';
import 'package:opennutritracker/core/utils/navigation_options.dart';
import 'package:opennutritracker/features/add_meal/data/repository/products_repository.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_nutriments_entity.dart';
import 'package:opennutritracker/features/add_meal/presentation/bloc/favourite_toggle_bloc.dart';
import 'package:opennutritracker/features/add_meal/presentation/log_tray.dart';
import 'package:opennutritracker/features/diary/presentation/bloc/calendar_day_bloc.dart';
import 'package:opennutritracker/features/diary/presentation/bloc/diary_bloc.dart';
import 'package:opennutritracker/features/home/presentation/bloc/home_bloc.dart';
import 'package:opennutritracker/features/meal_detail/meal_detail_screen.dart';
import 'package:opennutritracker/features/meal_detail/presentation/bloc/meal_detail_bloc.dart';
import 'package:opennutritracker/features/meal_detail/presentation/widgets/meal_detail_bottom_sheet.dart';
import 'package:opennutritracker/generated/l10n.dart';
import 'package:provider/provider.dart';

import '../../helpers/fake_favourites.dart';

// #1265: a food opened to log again starts on the amount it was last logged
// with, when the food still offers that unit; otherwise on the usual default.

const _nutriments = MealNutrimentsEntity(
  energyKcal100: 100,
  carbohydrates100: 10,
  fat100: 5,
  proteins100: 5,
  sugars100: 2,
  saturatedFat100: 1,
  fiber100: 1,
);

MealEntity _cereal({double? servingQuantity = 30}) => MealEntity(
  code: 'cereal',
  name: 'Cereal',
  url: null,
  mealQuantity: '100',
  mealUnit: 'g',
  servingQuantity: servingQuantity,
  servingUnit: servingQuantity == null ? null : 'g',
  servingSize: servingQuantity == null ? null : '$servingQuantity g',
  nutriments: _nutriments,
  source: MealSourceEntity.off,
  detailed: true,
);

MealEntity _thinOffDrink() => MealEntity(
  code: 'thin-off-drink',
  name: 'Thin OFF drink',
  url: null,
  mealQuantity: '100',
  mealUnit: 'ml',
  servingQuantity: null,
  servingUnit: null,
  servingSize: null,
  nutriments: _nutriments,
  source: MealSourceEntity.off,
);

MealEntity _hydratedOffDrink() => MealEntity(
  code: 'thin-off-drink',
  name: 'Thin OFF drink',
  url: null,
  mealQuantity: '100',
  mealUnit: 'ml',
  servingQuantity: 250,
  servingUnit: 'ml',
  servingSize: '250 ml',
  nutriments: _nutriments,
  source: MealSourceEntity.off,
  detailed: true,
);

IntakeEntity _logged(MealEntity meal, String unit, double amount) =>
    IntakeEntity(
      id: 'last',
      unit: unit,
      amount: amount,
      type: IntakeTypeEntity.breakfast,
      meal: meal,
      dateTime: DateTime(2026, 9, 1),
    );

void main() {
  final getIt = GetIt.instance;
  MealDetailBloc? bloc;
  late bool defaultToRawFoodUnits;
  MealEntity? hydratedFor;
  late _FakeGetIntakeUsecase intakes;

  setUp(() {
    bloc = null;
    defaultToRawFoodUnits = false;
    hydratedFor = null;
    intakes = _FakeGetIntakeUsecase();
    getIt.registerLazySingleton<MealDetailBloc>(
      () => bloc = MealDetailBloc(
        _FakeAddIntakeUsecase(),
        _FakeAddTrackedDayUsecase(),
        _FakeGetKcalGoalUsecase(),
        _FakeGetMacroGoalUsecase(),
        _FakeGetTrackedDayUsecase(),
        _FakeProductsRepository(() => hydratedFor),
        _FakeRemoteSearchCacheDataSource(),
        getIntake: intakes,
      ),
    );
    getIt.registerLazySingleton<GetConfigUsecase>(
      () => _FakeGetConfigUsecase(() => defaultToRawFoodUnits),
    );
    getIt.registerLazySingleton<GetIntakeUsecase>(() => intakes);
    getIt.registerLazySingleton<CacheManager>(_FakeCacheManager.new);
    final favourites = FakeFavourites();
    getIt.registerFactory<FavouriteToggleBloc>(
      () => FavouriteToggleBloc(favourites.get, favourites.toggle),
    );
    getIt.registerLazySingleton<HomeBloc>(_FakeHomeBloc.new);
    getIt.registerLazySingleton<DiaryBloc>(_FakeDiaryBloc.new);
    getIt.registerLazySingleton<CalendarDayBloc>(_FakeCalendarDayBloc.new);
  });

  tearDown(() async {
    await getIt.reset();
  });

  Future<void> pumpMealDetail(
    WidgetTester tester,
    MealEntity meal, {
    LogTrayItem? editing,
    bool settle = true,
  }) async {
    tester.view.physicalSize = const Size(600, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final LogTray? tray = editing == null ? null : (LogTray()..add(editing));
    if (tray != null) addTearDown(tray.dispose);

    Route<void> routeFor(RouteSettings settings) => MaterialPageRoute<void>(
      settings: settings,
      builder: (_) => const MealDetailScreen(),
    );

    await tester.pumpWidget(
      ChangeNotifierProvider<EnergyUnitProvider>(
        create: (_) => EnergyUnitProvider(),
        child: MaterialApp(
          localizationsDelegates: const [S.delegate],
          supportedLocales: S.supportedLocales,
          initialRoute: NavigationOptions.mealDetailRoute,
          onGenerateInitialRoutes: (_) => [
            routeFor(
              RouteSettings(
                name: NavigationOptions.mealDetailRoute,
                arguments: MealDetailScreenArguments(
                  meal,
                  IntakeTypeEntity.breakfast,
                  DateTime(2026, 9, 14),
                  false,
                  logTray: tray,
                  editingTrayItem: editing,
                ),
              ),
            ),
          ],
          onGenerateRoute: routeFor,
        ),
      ),
    );
    if (settle) await tester.pumpAndSettle();
  }

  Finder quantityFinder() => find
      .descendant(
        of: find.byType(MealDetailBottomSheet),
        matching: find.byType(TextField),
      )
      .first;

  String quantityField(WidgetTester tester) =>
      tester.widget<TextField>(quantityFinder()).controller!.text;

  testWidgets('a food never logged opens on the usual default', (tester) async {
    await pumpMealDetail(tester, _cereal());

    expect(intakes.askedFor?.code, 'cereal');
    expect(bloc!.state.selectedUnit, 'serving');
    expect(quantityField(tester), '1');
    expect(bloc!.state.totalQuantityConverted, '30.0');
  });

  testWidgets('logged as two servings, it opens on two servings', (
    tester,
  ) async {
    intakes.last = _logged(_cereal(), 'serving', 60);
    await pumpMealDetail(tester, _cereal());

    expect(bloc!.state.selectedUnit, 'serving');
    expect(quantityField(tester), '2');
    expect(bloc!.state.totalQuantityConverted, '60.0');
    expect(bloc!.state.totalKcal, closeTo(60, 0.001));
  });

  testWidgets('logged as 45 g, it opens on 45 g instead of a serving', (
    tester,
  ) async {
    intakes.last = _logged(_cereal(), 'g', 45);
    await pumpMealDetail(tester, _cereal());

    expect(bloc!.state.selectedUnit, 'g');
    expect(quantityField(tester), '45');
    expect(bloc!.state.totalQuantityConverted, '45.0');
  });

  testWidgets('a serving the food no longer offers opens on the default', (
    tester,
  ) async {
    intakes.last = _logged(_cereal(), 'serving', 60);
    await pumpMealDetail(tester, _cereal(servingQuantity: null));

    expect(bloc!.state.selectedUnit, 'g');
    expect(quantityField(tester), '100');
    expect(bloc!.state.totalQuantityConverted, '100.0');
  });

  testWidgets('the last amount wins over the raw-units preference', (
    tester,
  ) async {
    defaultToRawFoodUnits = true;
    intakes.last = _logged(_cereal(), 'serving', 90);
    await pumpMealDetail(tester, _cereal());

    expect(bloc!.state.selectedUnit, 'serving');
    expect(quantityField(tester), '3');
  });

  testWidgets(
    'a serving that only the hydrated record has is picked up once it arrives',
    (tester) async {
      hydratedFor = _hydratedOffDrink();
      intakes.last = _logged(_hydratedOffDrink(), 'serving', 500);
      await pumpMealDetail(tester, _thinOffDrink());

      expect(bloc!.state.selectedUnit, 'serving');
      expect(quantityField(tester), '2');
      expect(bloc!.state.totalQuantityConverted, '500.0');
    },
  );

  testWidgets('a row reopened from the To-log list keeps its own amount', (
    tester,
  ) async {
    intakes.last = _logged(_cereal(), 'g', 45);
    final meal = _cereal();
    await pumpMealDetail(
      tester,
      meal,
      editing: LogTrayItem(
        meal: meal,
        unit: 'serving',
        amount: 60,
        amountLabel: '',
        quantity: 2,
        selectedUnit: 'serving',
      ),
    );

    expect(bloc!.state.selectedUnit, 'serving');
    expect(quantityField(tester), '2');
    expect(intakes.askedFor, isNull);
  });

  testWidgets('what the user types before the lookup returns is kept', (
    tester,
  ) async {
    intakes.gate = Completer<void>();
    intakes.last = _logged(_cereal(), 'g', 45);
    await pumpMealDetail(tester, _cereal(), settle: false);
    await tester.pump();

    await tester.enterText(quantityFinder(), '4');
    await tester.pump();
    intakes.gate!.complete();
    await tester.pumpAndSettle();

    expect(bloc!.state.selectedUnit, 'serving');
    expect(quantityField(tester), '4');
    expect(bloc!.state.totalQuantityConverted, '120.0');
  });

  testWidgets('a lookup that fails opens on the default', (tester) async {
    intakes.error = StateError('box closed');
    await pumpMealDetail(tester, _cereal());

    expect(bloc!.state.selectedUnit, 'serving');
    expect(quantityField(tester), '1');
  });

  testWidgets('a Quick Add entry opens on the 100 g it was logged with', (
    tester,
  ) async {
    final quickAdd = MealEntity(
      code: 'quick-add-1',
      name: 'Lunch out',
      url: null,
      mealQuantity: '100',
      mealUnit: 'gml',
      servingQuantity: null,
      servingUnit: 'gml',
      servingSize: '',
      nutriments: const MealNutrimentsEntity(
        energyKcal100: 650,
        carbohydrates100: null,
        fat100: null,
        proteins100: null,
        sugars100: null,
        saturatedFat100: null,
        fiber100: null,
      ),
      source: MealSourceEntity.custom,
    );
    intakes.last = _logged(quickAdd, 'g', 100);
    await pumpMealDetail(tester, quickAdd);

    expect(bloc!.state.selectedUnit, 'g');
    expect(quantityField(tester), '100');
    expect(bloc!.state.totalKcal, closeTo(650, 0.001));
  });

  testWidgets('a recipe logged by the serving opens by the serving', (
    tester,
  ) async {
    final recipe = MealEntity(
      code: 'recipe-1',
      name: 'Chili',
      url: null,
      mealQuantity: '1200',
      mealUnit: 'g',
      servingQuantity: 300,
      servingUnit: 'g',
      servingSize: '4 servings',
      nutriments: _nutriments,
      source: MealSourceEntity.recipe,
    );
    intakes.last = _logged(recipe, 'serving', 600);
    await pumpMealDetail(tester, recipe);

    expect(intakes.askedFor?.source, MealSourceEntity.recipe);
    expect(bloc!.state.selectedUnit, 'serving');
    expect(quantityField(tester), '2');
    expect(bloc!.state.totalQuantityConverted, '600.0');
  });
}

class _FakeGetIntakeUsecase implements GetIntakeUsecase {
  IntakeEntity? last;
  Object? error;
  Completer<void>? gate;
  MealEntity? askedFor;

  @override
  Future<IntakeEntity?> getLastIntakeOfMeal(MealEntity meal) async {
    askedFor = meal;
    await gate?.future;
    if (error != null) throw error!;
    return last;
  }

  @override
  Future<List<IntakeEntity>> getBreakfastIntakeByDay(
    DateTime day, {
    int dayStartOffsetHours = 0,
    int dayStartOffsetMinutes = 0,
  }) async => [];

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('Unexpected call: ${invocation.memberName}');
}

class _FakeGetConfigUsecase implements GetConfigUsecase {
  final bool Function() defaultToRawFoodUnitsProvider;

  _FakeGetConfigUsecase(this.defaultToRawFoodUnitsProvider);

  @override
  Future<ConfigEntity> getConfig() async {
    return ConfigEntity(
      true,
      true,
      false,
      AppThemeEntity.system,
      defaultToRawFoodUnits: defaultToRawFoodUnitsProvider(),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('Unexpected call: ${invocation.memberName}');
}

class _FakeAddIntakeUsecase implements AddIntakeUsecase {
  @override
  Future<void> addIntake(IntakeEntity intakeEntity) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('Unexpected call: ${invocation.memberName}');
}

class _FakeAddTrackedDayUsecase implements AddTrackedDayUsecase {
  @override
  Future<bool> hasTrackedDay(DateTime day) async => true;

  @override
  Future<void> addDayCaloriesTracked(DateTime day, double kcal) async {}

  @override
  Future<void> addDayMacrosTracked(
    DateTime day, {
    double? carbsTracked,
    double? fatTracked,
    double? proteinTracked,
  }) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('Unexpected call: ${invocation.memberName}');
}

class _FakeGetKcalGoalUsecase implements GetKcalGoalUsecase {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('Unexpected call: ${invocation.memberName}');
}

class _FakeGetMacroGoalUsecase implements GetMacroGoalUsecase {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('Unexpected call: ${invocation.memberName}');
}

class _FakeGetTrackedDayUsecase implements GetTrackedDayUsecase {
  @override
  Future<TrackedDayEntity?> getTrackedDay(DateTime day) async =>
      TrackedDayEntity(
        day: day,
        calorieGoal: 2200,
        caloriesTracked: 800,
        carbsGoal: 250,
        carbsTracked: 100,
        fatGoal: 70,
        fatTracked: 30,
        proteinGoal: 120,
        proteinTracked: 50,
      );

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('Unexpected call: ${invocation.memberName}');
}

class _FakeProductsRepository implements ProductsRepository {
  final MealEntity? Function() hydratedProvider;

  _FakeProductsRepository(this.hydratedProvider);

  @override
  Future<MealEntity> getOFFProductByBarcode(
    String barcode, {
    String? knownName,
  }) async {
    final hydrated = hydratedProvider();
    if (hydrated == null) {
      throw StateError('No hydrated product configured for barcode $barcode');
    }
    return hydrated;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('Unexpected call: ${invocation.memberName}');
}

class _FakeRemoteSearchCacheDataSource implements RemoteSearchCacheDataSource {
  @override
  Future<void> touch(String barcode) async {}

  @override
  MealDBO? getDetailedByBarcode(String barcode) => null;

  @override
  Future<void> cache(MealDBO meal) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('Unexpected call: ${invocation.memberName}');
}

class _FakeHomeBloc implements HomeBloc {
  @override
  void add(HomeEvent event) {}

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('Unexpected call: ${invocation.memberName}');
}

class _FakeDiaryBloc implements DiaryBloc {
  @override
  void add(DiaryEvent event) {}

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('Unexpected call: ${invocation.memberName}');
}

class _FakeCalendarDayBloc implements CalendarDayBloc {
  @override
  void add(CalendarDayEvent event) {}

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('Unexpected call: ${invocation.memberName}');
}

class _FakeCacheManager implements CacheManager {
  @override
  Stream<FileResponse> getFileStream(
    String url, {
    String? key,
    Map<String, String>? headers,
    bool withProgress = false,
  }) => const Stream<FileResponse>.empty();

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('Unexpected call: ${invocation.memberName}');
}
