import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:opennutritracker/core/data/data_source/remote_search_cache_data_source.dart';
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
import 'package:opennutritracker/features/diary/presentation/bloc/calendar_day_bloc.dart';
import 'package:opennutritracker/features/diary/presentation/bloc/diary_bloc.dart';
import 'package:opennutritracker/features/home/presentation/bloc/home_bloc.dart';
import 'package:opennutritracker/features/meal_detail/meal_detail_screen.dart';
import 'package:opennutritracker/features/meal_detail/presentation/bloc/meal_detail_bloc.dart';
import 'package:opennutritracker/features/meal_detail/presentation/widgets/meal_detail_macro_nutrients.dart';
import 'package:opennutritracker/features/meal_detail/presentation/widgets/meal_detail_nutriments_table.dart';
import 'package:opennutritracker/generated/l10n.dart';
import 'package:provider/provider.dart';

import '../../helpers/fake_favourites.dart';
import '../../helpers/test_l10n.dart';

// #1295: a Quick Add entry saved with only its energy showed in Recents,
// but its detail screen refused to log it again ("missing data"). Macros
// are optional in Quick Add, so they are optional when reusing the entry,
// and what was left out stays unknown rather than becoming 0 g.

/// Shaped as Quick Add stores its entry: per 100 g/ml, no serving, and only
/// the macros that were typed.
MealEntity _quickAdded({
  double? kcal = 350,
  double? carbs,
  double? fat,
  double? protein,
}) => MealEntity(
  code: 'quick-add-reuse-test',
  name: 'Canteen lunch',
  url: null,
  mealQuantity: '100',
  mealUnit: 'gml',
  servingQuantity: null,
  servingUnit: 'gml',
  servingSize: '',
  nutriments: MealNutrimentsEntity(
    energyKcal100: kcal,
    carbohydrates100: carbs,
    fat100: fat,
    proteins100: protein,
    sugars100: null,
    saturatedFat100: null,
    fiber100: null,
  ),
  source: MealSourceEntity.custom,
);

void main() {
  final getIt = GetIt.instance;
  late _RecordingAddIntakeUsecase addIntake;
  late _RecordingAddTrackedDayUsecase trackedDay;

  setUp(() {
    addIntake = _RecordingAddIntakeUsecase();
    trackedDay = _RecordingAddTrackedDayUsecase();
    getIt.registerLazySingleton<MealDetailBloc>(
      () => MealDetailBloc(
        addIntake,
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

  Future<void> pumpMealDetail(WidgetTester tester, MealEntity meal) async {
    tester.view.physicalSize = const Size(1080, 2400);
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
          localizationsDelegates: const [S.delegate],
          supportedLocales: S.supportedLocales,
          initialRoute: NavigationOptions.mealDetailRoute,
          onGenerateInitialRoutes: (_) => [
            routeFor(
              RouteSettings(
                name: NavigationOptions.mealDetailRoute,
                arguments: MealDetailScreenArguments(
                  meal,
                  IntakeTypeEntity.lunch,
                  DateTime(2026, 11, 9),
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
  }

  Finder inSummary(String label, Finder matching) => find.descendant(
    of: find.widgetWithText(MealDetailMacroNutrients, label),
    matching: matching,
  );

  Finder addButton() => find.descendant(
    of: find.bySemanticsIdentifier('meal-detail-add'),
    matching: find.bySubtype<ButtonStyleButton>(),
  );

  bool addEnabled(WidgetTester tester) =>
      tester.widget<ButtonStyleButton>(addButton()).onPressed != null;

  Future<void> tapAdd(WidgetTester tester) async {
    await tester.ensureVisible(addButton());
    await tester.pumpAndSettle();
    await tester.tap(addButton());
    await tester.pumpAndSettle();
  }

  testWidgets('with only energy, it can be logged again and its macros '
      'stay unknown', (tester) async {
    await pumpMealDetail(tester, _quickAdded());

    expect(find.textContaining(l10nEn.missingProductInfo), findsNothing);
    expect(addEnabled(tester), isTrue);
    expect(find.text('350 kcal'), findsWidgets);
    for (final label in [
      l10nEn.carbsLabel,
      l10nEn.fatLabel,
      l10nEn.proteinLabel,
    ]) {
      expect(
        inSummary(label, find.text(missingNutrientPlaceholder)),
        findsOneWidget,
      );
    }
    expect(find.textContaining('0.0 g'), findsNothing);

    await tapAdd(tester);

    final logged = addIntake.stored.single;
    expect(logged.amount, 100);
    expect(logged.totalKcal, 350);
    expect(logged.meal.nutriments.energyKcal100, 350);
    expect(logged.meal.nutriments.carbohydrates100, isNull);
    expect(logged.meal.nutriments.fat100, isNull);
    expect(logged.meal.nutriments.proteins100, isNull);
    // The day's totals get what the first Quick Add gave them.
    expect(trackedDay.calories, [350]);
    expect(trackedDay.macros, [(carbs: 0.0, fat: 0.0, protein: 0.0)]);
  });

  testWidgets('with some macros, the known ones count and the rest stay '
      'unknown', (tester) async {
    await pumpMealDetail(tester, _quickAdded(carbs: 40));

    expect(find.textContaining(l10nEn.missingProductInfo), findsNothing);
    expect(addEnabled(tester), isTrue);
    expect(inSummary(l10nEn.carbsLabel, find.text('40.0 g')), findsOneWidget);
    expect(
      inSummary(l10nEn.fatLabel, find.text(missingNutrientPlaceholder)),
      findsOneWidget,
    );
    expect(
      inSummary(l10nEn.proteinLabel, find.text(missingNutrientPlaceholder)),
      findsOneWidget,
    );

    await tapAdd(tester);

    final logged = addIntake.stored.single;
    expect(logged.meal.nutriments.carbohydrates100, 40);
    expect(logged.meal.nutriments.fat100, isNull);
    expect(logged.meal.nutriments.proteins100, isNull);
    expect(trackedDay.macros, [(carbs: 40.0, fat: 0.0, protein: 0.0)]);
  });

  testWidgets('with every macro, it logs as it always did', (tester) async {
    await pumpMealDetail(tester, _quickAdded(carbs: 40, fat: 15, protein: 20));

    expect(find.textContaining(l10nEn.missingProductInfo), findsNothing);
    for (final label in [
      l10nEn.carbsLabel,
      l10nEn.fatLabel,
      l10nEn.proteinLabel,
    ]) {
      expect(
        inSummary(label, find.text(missingNutrientPlaceholder)),
        findsNothing,
      );
    }

    await tapAdd(tester);

    expect(addIntake.stored.single.totalKcal, 350);
    expect(trackedDay.macros, [(carbs: 40.0, fat: 15.0, protein: 20.0)]);
  });

  testWidgets('a changed amount scales the energy and leaves the missing '
      'macros unknown', (tester) async {
    await pumpMealDetail(tester, _quickAdded(carbs: 40));

    final quantity = find.widgetWithText(TextFormField, l10nEn.quantityLabel);
    await tester.enterText(quantity, '250');
    await tester.pumpAndSettle();

    expect(find.text('875 kcal'), findsWidgets);
    expect(inSummary(l10nEn.carbsLabel, find.text('100.0 g')), findsOneWidget);
    expect(
      inSummary(l10nEn.fatLabel, find.text(missingNutrientPlaceholder)),
      findsOneWidget,
    );

    await tapAdd(tester);

    final logged = addIntake.stored.single;
    expect(logged.amount, 250);
    expect(logged.totalKcal, 875);
    expect(logged.meal.nutriments.fat100, isNull);
    expect(logged.meal.nutriments.proteins100, isNull);
    expect(trackedDay.calories, [875]);
    expect(trackedDay.macros, [(carbs: 100.0, fat: 0.0, protein: 0.0)]);
  });

  testWidgets('without energy, it is still refused', (tester) async {
    await pumpMealDetail(
      tester,
      _quickAdded(kcal: null, carbs: 40, fat: 15, protein: 20),
    );

    expect(
      find.textContaining(l10nEn.missingProductInfoFields(l10nEn.energyLabel)),
      findsOneWidget,
    );
    expect(addEnabled(tester), isFalse);
  });
}

class _RecordingAddIntakeUsecase extends Fake implements AddIntakeUsecase {
  final stored = <IntakeEntity>[];

  @override
  Future<void> addIntake(IntakeEntity intakeEntity) async =>
      stored.add(intakeEntity);
}

/// A day that already has its row: records what is added to its totals.
class _RecordingAddTrackedDayUsecase extends Fake
    implements AddTrackedDayUsecase {
  final calories = <double>[];
  final macros = <({double? carbs, double? fat, double? protein})>[];

  @override
  Future<bool> hasTrackedDay(DateTime day) async => true;

  @override
  Future<void> addDayCaloriesTracked(
    DateTime day,
    double caloriesTracked,
  ) async => calories.add(caloriesTracked);

  @override
  Future<void> addDayMacrosTracked(
    DateTime day, {
    double? carbsTracked,
    double? fatTracked,
    double? proteinTracked,
  }) async => macros.add((
    carbs: carbsTracked,
    fat: fatTracked,
    protein: proteinTracked,
  ));
}

class _FakeGetConfigUsecase extends Fake implements GetConfigUsecase {
  @override
  Future<ConfigEntity> getConfig() async =>
      const ConfigEntity(true, true, false, AppThemeEntity.system);
}

class _FakeGetKcalGoalUsecase extends Fake implements GetKcalGoalUsecase {}

class _FakeGetMacroGoalUsecase extends Fake implements GetMacroGoalUsecase {}

class _FakeGetTrackedDayUsecase extends Fake implements GetTrackedDayUsecase {
  @override
  Future<TrackedDayEntity?> getTrackedDay(DateTime day) async => null;
}

class _FakeProductsRepository extends Fake implements ProductsRepository {}

class _FakeRemoteSearchCacheDataSource extends Fake
    implements RemoteSearchCacheDataSource {
  @override
  Future<void> touch(String barcode) async {}
}

/// Nothing logged yet, so the duplicate check lets the meal through.
class _FakeGetIntakeUsecase extends Fake implements GetIntakeUsecase {
  @override
  Future<List<IntakeEntity>> getLunchIntakeByDay(
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

class _FakeCacheManager extends Fake implements CacheManager {
  @override
  Stream<FileResponse> getFileStream(
    String url, {
    String? key,
    Map<String, String>? headers,
    bool withProgress = false,
  }) => const Stream<FileResponse>.empty();
}
