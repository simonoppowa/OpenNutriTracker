import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:opennutritracker/core/data/data_source/remote_search_cache_data_source.dart';
import 'package:opennutritracker/core/data/dbo/meal_dbo.dart';
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
import 'package:opennutritracker/features/add_meal/presentation/bloc/favourite_toggle_bloc.dart';
import 'package:opennutritracker/features/diary/presentation/bloc/calendar_day_bloc.dart';
import 'package:opennutritracker/features/diary/presentation/bloc/diary_bloc.dart';
import 'package:opennutritracker/features/home/presentation/bloc/home_bloc.dart';
import 'package:opennutritracker/features/meal_detail/meal_detail_screen.dart';
import 'package:opennutritracker/features/meal_detail/presentation/bloc/meal_detail_bloc.dart';
import 'package:opennutritracker/features/meal_detail/presentation/widgets/meal_detail_bottom_sheet.dart';
import 'package:opennutritracker/generated/l10n.dart';
import 'package:provider/provider.dart';

import '../../helpers/fake_favourites.dart';

// #833: logging a recipe by serving. Runs the path the recipe page takes —
// `RecipeEntity.toMealEntity()` into the meal-detail screen, a quantity in
// the serving unit, Add — and checks what reaches the diary: the intake's
// gram amount, its energy and macros, and the day's totals.

/// 150 kcal, 20 g carbs, 5 g fat and 8 g protein per 100 g of the cooked
/// recipe, so a 300 g serving is 450 kcal, 60 g carbs, 15 g fat, 24 g
/// protein.
const _per100 = MealNutrimentsEntity(
  energyKcal100: 150,
  carbohydrates100: 20,
  fat100: 5,
  proteins100: 8,
  sugars100: null,
  saturatedFat100: null,
  fiber100: null,
);

RecipeEntity _recipe({required double totalWeightG, int? servingsCount}) =>
    RecipeEntity(
      id: 'recipe-833',
      name: 'Lentil stew',
      description: null,
      ingredients: const [],
      totalWeightG: totalWeightG,
      aggregatedNutrimentsPer100: _per100,
      createdAt: DateTime(2026, 11, 1),
      updatedAt: DateTime(2026, 11, 1),
      servingsCount: servingsCount,
    );

void main() {
  final getIt = GetIt.instance;
  late MealDetailBloc bloc;
  late _RecordingAddIntakeUsecase intakes;
  late _RecordingAddTrackedDayUsecase trackedDay;

  setUp(() {
    intakes = _RecordingAddIntakeUsecase();
    trackedDay = _RecordingAddTrackedDayUsecase();
    getIt.registerLazySingleton<MealDetailBloc>(
      () => bloc = MealDetailBloc(
        intakes,
        trackedDay,
        _FakeGetKcalGoalUsecase(),
        _FakeGetMacroGoalUsecase(),
        _FakeGetTrackedDayUsecase(),
        _FakeProductsRepository(),
        _FakeRemoteSearchCacheDataSource(),
      ),
    );
    getIt.registerLazySingleton<GetConfigUsecase>(_FakeGetConfigUsecase.new);
    getIt.registerLazySingleton<GetIntakeUsecase>(_FakeGetIntakeUsecase.new);
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

  /// Opens the recipe the way the recipe page's "Log this recipe" does.
  Future<void> openRecipe(
    WidgetTester tester,
    RecipeEntity recipe, {
    Locale locale = const Locale('en'),
    bool usesImperialUnits = false,
  }) async {
    tester.view.physicalSize = const Size(600, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    Route<void> routeFor(RouteSettings settings) => MaterialPageRoute<void>(
      settings: settings,
      builder: (_) => const MealDetailScreen(),
    );

    await tester.pumpWidget(
      ChangeNotifierProvider<EnergyUnitProvider>(
        create: (_) => EnergyUnitProvider(),
        child: MaterialApp(
          locale: locale,
          localizationsDelegates: const [
            S.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: S.supportedLocales,
          initialRoute: NavigationOptions.mealDetailRoute,
          onGenerateInitialRoutes: (_) => [
            routeFor(
              RouteSettings(
                name: NavigationOptions.mealDetailRoute,
                arguments: MealDetailScreenArguments(
                  recipe.toMealEntity(),
                  IntakeTypeEntity.lunch,
                  DateTime(2026, 11, 9),
                  usesImperialUnits,
                ),
              ),
            ),
          ],
          onGenerateRoute: routeFor,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Finder inSheet(Finder matching) => find.descendant(
    of: find.byType(MealDetailBottomSheet),
    matching: matching,
  );

  Future<void> enterQuantity(WidgetTester tester, String text) async {
    await tester.enterText(inSheet(find.byType(TextField)).first, text);
    await tester.pumpAndSettle();
  }

  Future<void> tapAdd(WidgetTester tester) async {
    await tester.tap(inSheet(find.byIcon(Icons.add_rounded)));
    await tester.pumpAndSettle();
  }

  /// The unit dropdown's entries, as the menu lists them.
  List<String?> unitValues(WidgetTester tester) => tester
      .widget<DropdownButton<String>>(
        inSheet(find.byType(DropdownButton<String>)),
      )
      .items!
      .map((item) => item.value)
      .toList();

  group('a recipe with a total weight and a servings count', () {
    final recipe = _recipe(totalWeightG: 1200, servingsCount: 4);

    testWidgets('opens on the serving unit, labelled with one serving', (
      tester,
    ) async {
      await openRecipe(tester, recipe);

      expect(bloc.state.selectedUnit, 'serving');
      // The label names one serving and its weight, not the batch's count:
      // "4 servings" next to a quantity of 1 read as one serving being the
      // whole batch, or the count being a weight (#833).
      expect(inSheet(find.text('1 serving (300 g)')), findsOneWidget);
      expect(inSheet(find.text('4 servings')), findsNothing);
    });

    testWidgets('one serving logs a quarter of the batch', (tester) async {
      await openRecipe(tester, recipe);
      await enterQuantity(tester, '1');
      await tapAdd(tester);

      final intake = intakes.single;
      expect(intake.unit, 'serving');
      expect(intake.amount, 300);
      expect(intake.totalKcal, closeTo(450, 1e-9));
      expect(intake.totalCarbsGram, closeTo(60, 1e-9));
      expect(intake.totalFatsGram, closeTo(15, 1e-9));
      expect(intake.totalProteinsGram, closeTo(24, 1e-9));
      expect(trackedDay.kcal, closeTo(450, 1e-9));
      expect(trackedDay.carbs, closeTo(60, 1e-9));
      expect(trackedDay.fat, closeTo(15, 1e-9));
      expect(trackedDay.protein, closeTo(24, 1e-9));
    });

    testWidgets('a quantity above one multiplies the serving', (tester) async {
      await openRecipe(tester, recipe);
      await enterQuantity(tester, '2.5');
      await tapAdd(tester);

      final intake = intakes.single;
      expect(intake.amount, 750);
      expect(intake.totalKcal, closeTo(1125, 1e-9));
      expect(intake.totalProteinsGram, closeTo(60, 1e-9));
      expect(trackedDay.kcal, closeTo(1125, 1e-9));
    });

    testWidgets('the label is translated', (tester) async {
      await openRecipe(tester, recipe, locale: const Locale('de'));

      expect(inSheet(find.text('1 Portion (300 g)')), findsOneWidget);
    });

    testWidgets('the label is in ounces for imperial units', (tester) async {
      await openRecipe(tester, recipe, usesImperialUnits: true);

      // 300 g is 10.58 oz.
      expect(inSheet(find.text('1 serving (10.58 oz)')), findsOneWidget);
    });

    testWidgets('a comma decimal is read the same way', (tester) async {
      await openRecipe(tester, recipe);
      await enterQuantity(tester, '1,5');
      await tapAdd(tester);

      expect(intakes.single.amount, 450);
      expect(trackedDay.kcal, closeTo(675, 1e-9));
    });
  });

  group('a serving that does not divide evenly', () {
    testWidgets('logs the exact share and labels it rounded', (tester) async {
      // 1000 g in 3 servings: 333.33 g each.
      await openRecipe(tester, _recipe(totalWeightG: 1000, servingsCount: 3));

      expect(inSheet(find.text('1 serving (333.3 g)')), findsOneWidget);

      await enterQuantity(tester, '3');
      await tapAdd(tester);

      expect(intakes.single.amount, closeTo(1000, 1e-9));
      expect(trackedDay.kcal, closeTo(1500, 1e-9));
    });
  });

  group('a recipe whose total weight was typed in by hand', () {
    testWidgets('a serving is a share of the typed weight', (tester) async {
      // Cooked down from the ingredients' sum to 800 g: the stored total is
      // the typed one, and a serving is a quarter of it.
      await openRecipe(tester, _recipe(totalWeightG: 800, servingsCount: 4));

      expect(inSheet(find.text('1 serving (200 g)')), findsOneWidget);

      await enterQuantity(tester, '1');
      await tapAdd(tester);

      expect(intakes.single.amount, 200);
      expect(trackedDay.kcal, closeTo(300, 1e-9));
    });

    testWidgets('the issue\'s recipe: a count as large as the weight', (
      tester,
    ) async {
      // The report's screenshots: "414 servings" on a recipe of about that
      // many grams, so a serving came to about 1 g and logged 1 kcal. The
      // field is a count; the label now shows what a serving weighs.
      await openRecipe(tester, _recipe(totalWeightG: 414, servingsCount: 414));

      expect(inSheet(find.text('1 serving (1 g)')), findsOneWidget);
      expect(inSheet(find.text('414 servings')), findsNothing);

      await enterQuantity(tester, '1');
      await tapAdd(tester);

      expect(intakes.single.amount, 1);
    });
  });

  group('a recipe that cannot be logged by serving', () {
    for (final count in <int?>[null, 0]) {
      testWidgets('servings count $count offers grams only', (tester) async {
        await openRecipe(
          tester,
          _recipe(totalWeightG: 1200, servingsCount: count),
        );

        expect(bloc.state.selectedUnit, 'g');
        expect(unitValues(tester), isNot(contains('serving')));

        await enterQuantity(tester, '150');
        await tapAdd(tester);

        final intake = intakes.single;
        expect(intake.unit, 'g');
        expect(intake.amount, 150);
        expect(trackedDay.kcal, closeTo(225, 1e-9));
      });
    }

    testWidgets('a missing total weight offers no serving to log', (
      tester,
    ) async {
      // A serving of a weightless batch is 0 g: offering it logged nothing
      // whatever the quantity.
      await openRecipe(tester, _recipe(totalWeightG: 0, servingsCount: 4));

      expect(bloc.state.selectedUnit, 'g');
      expect(unitValues(tester), isNot(contains('serving')));

      await enterQuantity(tester, '100');
      await tapAdd(tester);

      expect(intakes.single.amount, 100);
      expect(trackedDay.kcal, closeTo(150, 1e-9));
    });
  });
}

class _RecordingAddIntakeUsecase implements AddIntakeUsecase {
  final logged = <IntakeEntity>[];

  IntakeEntity get single {
    expect(logged, hasLength(1));
    return logged.single;
  }

  @override
  Future<void> addIntake(IntakeEntity intakeEntity) async =>
      logged.add(intakeEntity);

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('Unexpected call: ${invocation.memberName}');
}

class _RecordingAddTrackedDayUsecase implements AddTrackedDayUsecase {
  double kcal = 0;
  double carbs = 0;
  double fat = 0;
  double protein = 0;

  @override
  Future<bool> hasTrackedDay(DateTime day) async => true;

  @override
  Future<void> addDayCaloriesTracked(DateTime day, double kcal) async =>
      this.kcal += kcal;

  @override
  Future<void> addDayMacrosTracked(
    DateTime day, {
    double? carbsTracked,
    double? fatTracked,
    double? proteinTracked,
  }) async {
    carbs += carbsTracked ?? 0;
    fat += fatTracked ?? 0;
    protein += proteinTracked ?? 0;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('Unexpected call: ${invocation.memberName}');
}

class _FakeGetConfigUsecase implements GetConfigUsecase {
  @override
  Future<ConfigEntity> getConfig() async =>
      ConfigEntity(true, true, false, AppThemeEntity.system);

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
        caloriesTracked: 0,
        carbsGoal: 250,
        carbsTracked: 0,
        fatGoal: 70,
        fatTracked: 0,
        proteinGoal: 120,
        proteinTracked: 0,
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
  MealDBO? getDetailedByBarcode(String barcode) => null;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('Unexpected call: ${invocation.memberName}');
}

class _FakeGetIntakeUsecase implements GetIntakeUsecase {
  @override
  Future<List<IntakeEntity>> getLunchIntakeByDay(
    DateTime day, {
    int dayStartOffsetHours = 0,
    int dayStartOffsetMinutes = 0,
  }) async => [];

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
