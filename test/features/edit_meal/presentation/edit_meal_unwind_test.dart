import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:opennutritracker/core/data/data_source/custom_meal_data_source.dart';
import 'package:opennutritracker/core/data/data_source/remote_search_cache_data_source.dart';
import 'package:opennutritracker/core/data/repository/config_repository.dart';
import 'package:opennutritracker/core/domain/entity/app_theme_entity.dart';
import 'package:opennutritracker/core/domain/entity/config_entity.dart';
import 'package:opennutritracker/core/domain/entity/intake_entity.dart';
import 'package:opennutritracker/core/domain/entity/intake_type_entity.dart';
import 'package:opennutritracker/core/domain/entity/recipe_entity.dart';
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
import 'package:opennutritracker/features/add_meal/domain/entity/meal_nutriments_entity.dart';
import 'package:opennutritracker/features/diary/presentation/bloc/calendar_day_bloc.dart';
import 'package:opennutritracker/features/diary/presentation/bloc/diary_bloc.dart';
import 'package:opennutritracker/features/edit_meal/presentation/bloc/edit_meal_bloc.dart';
import 'package:opennutritracker/features/edit_meal/presentation/edit_meal_screen.dart';
import 'package:opennutritracker/features/home/presentation/bloc/home_bloc.dart';
import 'package:opennutritracker/features/meal_detail/meal_detail_screen.dart';
import 'package:opennutritracker/features/meal_detail/presentation/bloc/meal_detail_bloc.dart';
import 'package:opennutritracker/generated/l10n.dart';
import 'package:provider/provider.dart';

import '../../../helpers/test_l10n.dart';

/// End-to-end cover for the black screen after logging a recipe.
///
/// The Edit Meal save unwind names `addMealRoute` and the intake sheet's
/// unwind names `mainRoute`, but both screens are reachable on stacks that
/// have neither. Recipes tab → recipe → Log → intake type pushes
/// `mealDetailRoute` straight onto the main screen
/// (`recipe_detail_screen.dart` `_onLogPressed`), so nothing below it is an
/// Add Meal route.
///
/// From there this test drives the real screens: the real
/// [MealDetailScreen]'s edit pencil, the real [EditMealScreen]'s save, and
/// the real `MealDetailBottomSheet`'s Add. With
/// `ModalRoute.withName(addMealRoute)` the save removes every route beneath
/// the new meal detail — `main` included — and Add's `popUntil(mainRoute)`
/// then finds no match either and empties the navigator: a black screen,
/// with the intake already written to the database.
///
/// Only the main screen is stubbed, because all these unwinds want from it
/// is a route named `main` to survive.
void main() {
  final getIt = GetIt.instance;
  final loggedIntakes = <IntakeEntity>[];

  final recipe = RecipeEntity(
    id: 'a3f1c0de-0000-4000-8000-000000000001',
    name: 'Chicken curry',
    description: null,
    ingredients: const [],
    totalWeightG: 800,
    aggregatedNutrimentsPer100: const MealNutrimentsEntity(
      energyKcal100: 120,
      carbohydrates100: 10,
      fat100: 5,
      proteins100: 8,
      sugars100: null,
      saturatedFat100: null,
      fiber100: null,
      sodium100: null,
      calcium100: null,
      iron100: null,
      potassium100: null,
      magnesium100: null,
      vitaminD100: null,
      vitaminB12100: null,
    ),
    createdAt: DateTime(2026, 8, 1),
    updatedAt: DateTime(2026, 8, 1),
    servingsCount: 4,
  );
  final day = DateTime(2026, 8, 19);

  setUp(() {
    loggedIntakes.clear();
    getIt.registerFactory<MealDetailBloc>(
      () => MealDetailBloc(
        _FakeAddIntakeUsecase(loggedIntakes),
        _FakeAddTrackedDayUsecase(),
        _FakeGetKcalGoalUsecase(),
        _FakeGetMacroGoalUsecase(),
        _FakeGetTrackedDayUsecase(),
        _FakeProductsRepository(),
        _FakeRemoteSearchCacheDataSource(),
      ),
    );
    getIt.registerFactory<EditMealBloc>(
      () => EditMealBloc(
        _FakeGetConfigUsecase(),
        _FakeCustomMealDataSource(),
        _FakeConfigRepository(),
      ),
    );
    getIt.registerLazySingleton<GetConfigUsecase>(_FakeGetConfigUsecase.new);
    getIt.registerLazySingleton<GetIntakeUsecase>(_FakeGetIntakeUsecase.new);
    getIt.registerLazySingleton<CacheManager>(_FakeCacheManager.new);
    getIt.registerLazySingleton<HomeBloc>(_FakeHomeBloc.new);
    getIt.registerLazySingleton<DiaryBloc>(_FakeDiaryBloc.new);
    getIt.registerLazySingleton<CalendarDayBloc>(_FakeCalendarDayBloc.new);
  });

  tearDown(() async {
    await getIt.reset();
  });

  /// Pumps `[main, mealDetail]` — the stack a recipe Log leaves behind —
  /// with the real meal-detail screen on top, and returns its navigator.
  Future<NavigatorState> pumpRecipeLogStack(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final navigatorKey = GlobalKey<NavigatorState>();

    Route<void> routeFor(RouteSettings settings) {
      final WidgetBuilder builder = switch (settings.name) {
        NavigationOptions.mealDetailRoute => (_) => const MealDetailScreen(),
        NavigationOptions.editMealRoute => (_) => const EditMealScreen(),
        _ => (_) => Scaffold(body: Text('${settings.name}-stub')),
      };
      return MaterialPageRoute<void>(settings: settings, builder: builder);
    }

    await tester.pumpWidget(
      ChangeNotifierProvider<EnergyUnitProvider>(
        create: (_) => EnergyUnitProvider(),
        child: MaterialApp(
          navigatorKey: navigatorKey,
          localizationsDelegates: const [S.delegate],
          supportedLocales: S.supportedLocales,
          initialRoute: NavigationOptions.mainRoute,
          onGenerateInitialRoutes: (_) => [
            routeFor(const RouteSettings(name: NavigationOptions.mainRoute)),
            // What `recipe_detail_screen.dart` `_onLogPressed` pushes.
            routeFor(
              RouteSettings(
                name: NavigationOptions.mealDetailRoute,
                arguments: MealDetailScreenArguments(
                  recipe.toMealEntity(),
                  IntakeTypeEntity.dinner,
                  day,
                  false,
                ),
              ),
            ),
          ],
          onGenerateRoute: routeFor,
        ),
      ),
    );
    await tester.pumpAndSettle();

    return navigatorKey.currentState!;
  }

  testWidgets(
    'logging a recipe through Edit Meal leaves the main screen standing',
    (tester) async {
      final navigator = await pumpRecipeLogStack(tester);
      expect(find.text(recipe.name), findsWidgets);

      // The meal-detail edit pencil. It passes no `editOnly`, so Edit Meal
      // opens on the create-and-log save path rather than the `pop()` one the
      // recipe/custom-meal list entry points get.
      await tester.tap(find.byIcon(Icons.edit_rounded));
      await tester.pumpAndSettle();
      expect(find.text(l10nEn.editMealLabel), findsOneWidget);

      await tester.tap(
        find.widgetWithText(FilledButton, l10nEn.buttonSaveLabel),
      );
      await tester.pumpAndSettle();

      // The save lands on a fresh meal detail either way — the regression is
      // what it leaves underneath.
      expect(find.text(l10nEn.editMealLabel), findsNothing);
      expect(
        navigator.canPop(),
        isTrue,
        reason: 'main must survive the Edit Meal unwind',
      );

      await tester.tap(find.widgetWithText(FilledButton, l10nEn.addLabel));
      await tester.pumpAndSettle();

      // The intake is written whatever the navigator does — that is why the
      // bug reads as "my food was logged and then the app went black".
      expect(loggedIntakes, hasLength(1));
      expect(loggedIntakes.single.type, IntakeTypeEntity.dinner);

      expect(find.text('${NavigationOptions.mainRoute}-stub'), findsOneWidget);
      expect(
        find.byType(Scaffold),
        findsWidgets,
        reason: 'an empty navigator renders as a black screen',
      );
    },
  );
}

class _FakeGetConfigUsecase implements GetConfigUsecase {
  @override
  Future<ConfigEntity> getConfig() async =>
      const ConfigEntity(true, true, false, AppThemeEntity.system);

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('Unexpected call: ${invocation.memberName}');
}

class _FakeConfigRepository implements ConfigRepository {
  @override
  Future<String?> getCustomMealFormMode() async =>
      CustomMealFormMode.simple.name;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('Unexpected call: ${invocation.memberName}');
}

class _FakeCustomMealDataSource implements CustomMealDataSource {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('Unexpected call: ${invocation.memberName}');
}

class _FakeAddIntakeUsecase implements AddIntakeUsecase {
  final List<IntakeEntity> logged;

  _FakeAddIntakeUsecase(this.logged);

  @override
  Future<void> addIntake(IntakeEntity intakeEntity) async {
    logged.add(intakeEntity);
  }

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
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('Unexpected call: ${invocation.memberName}');
}

class _FakeRemoteSearchCacheDataSource implements RemoteSearchCacheDataSource {
  @override
  Future<void> touch(String barcode) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('Unexpected call: ${invocation.memberName}');
}

class _FakeGetIntakeUsecase implements GetIntakeUsecase {
  @override
  Future<List<IntakeEntity>> getDinnerIntakeByDay(
    DateTime day, {
    int dayStartOffsetHours = 0,
    int dayStartOffsetMinutes = 0,
  }) async => [];

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('Unexpected call: ${invocation.memberName}');
}

/// The three refresh blocs the intake sheet pokes on its way out. They only
/// ever receive an event here, so swallowing it is the whole contract.
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

/// The meal screens render a [CachedNetworkImage] for non-custom meals; an
/// empty stream sends it straight to its error widget.
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
