import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_ce/hive.dart';
import 'package:opennutritracker/core/data/data_source/custom_meal_data_source.dart';
import 'package:opennutritracker/core/data/data_source/remote_search_cache_data_source.dart';
import 'package:opennutritracker/core/data/dbo/meal_dbo.dart';
import 'package:opennutritracker/core/data/repository/config_repository.dart';
import 'package:opennutritracker/core/data/repository/favourite_meal_repository.dart';
import 'package:opennutritracker/core/data/repository/intake_repository.dart';
import 'package:opennutritracker/core/domain/entity/app_theme_entity.dart';
import 'package:opennutritracker/core/domain/entity/config_entity.dart';
import 'package:opennutritracker/core/domain/entity/intake_entity.dart';
import 'package:opennutritracker/core/domain/entity/intake_type_entity.dart';
import 'package:opennutritracker/core/domain/entity/tracked_day_entity.dart';
import 'package:opennutritracker/core/domain/usecase/add_intake_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/add_tracked_day_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_config_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_kcal_goal_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_macro_goal_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_tracked_day_usecase.dart';
import 'package:opennutritracker/core/utils/energy_unit_provider.dart';
import 'package:opennutritracker/core/utils/navigation_options.dart';
import 'package:opennutritracker/features/add_meal/data/repository/products_repository.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_nutriments_entity.dart';
import 'package:opennutritracker/features/edit_meal/presentation/bloc/edit_meal_bloc.dart';
import 'package:opennutritracker/features/edit_meal/presentation/edit_meal_screen.dart';
import 'package:opennutritracker/features/meal_detail/meal_detail_screen.dart';
import 'package:opennutritracker/features/meal_detail/presentation/bloc/meal_detail_bloc.dart';
import 'package:opennutritracker/features/meal_detail/util/hydrate_off_meal.dart';
import 'package:opennutritracker/features/scanner/domain/usecase/search_product_by_barcode_usecase.dart';
import 'package:opennutritracker/generated/l10n.dart';
import 'package:provider/provider.dart';

import '../../../helpers/fake_favourites.dart';
import '../../../helpers/fake_hive_db_provider.dart';
import '../../../helpers/hive_test_setup.dart';
import '../../../helpers/test_l10n.dart';

const _barcode = '4006381333931';

MealEntity _scannedMeal({String code = _barcode}) => MealEntity(
  code: code,
  name: 'Scanned oats',
  url: null,
  mealQuantity: '400',
  mealUnit: 'g',
  servingQuantity: 40,
  servingUnit: 'g',
  servingSize: '40 g',
  nutriments: const MealNutrimentsEntity(
    energyKcal100: 180,
    carbohydrates100: 20,
    fat100: 8,
    proteins100: 7,
    sugars100: 2,
    saturatedFat100: 1,
    fiber100: 6,
  ),
  source: MealSourceEntity.off,
  detailed: true,
);

void main() {
  final getIt = GetIt.instance;
  late Directory directory;
  late Box<MealDBO> box;
  late CustomMealDataSource library;
  late FakeFavourites favourites;
  late _Products products;
  late _Cache cache;
  final editors = <EditMealBloc>[];
  MealEntity? edited;
  var imperial = false;
  var kilojoules = false;

  setUp(() async {
    imperial = false;
    kilojoules = false;
    directory = await Directory.systemTemp.createTemp('scanned-correction-');
    Hive.init(directory.path);
    registerHiveAdaptersOnce();
    box = await Hive.openBox<MealDBO>('custom-meals');
    library = CustomMealDataSource(FakeHiveDBProvider(customMealBox: box));
    // A different identity must not be replaced just because its name matches.
    await library.saveCustomMeal(
      MealDBO.fromMealEntity(_scannedMeal(code: 'unrelated')),
    );
    favourites = FakeFavourites();
    products = _Products();
    cache = _Cache();
    getIt.registerSingleton<CacheManager>(_Images());
    getIt.registerFactory<EditMealBloc>(() {
      final editor = EditMealBloc(
        _Config(imperial),
        library,
        _FormMode(),
        _Favourites(),
        _Intakes(),
      );
      editors.add(editor);
      return editor;
    });
  });

  tearDown(() async {
    for (final editor in editors) {
      await editor.close();
    }
    editors.clear();
    await getIt.reset();
    await favourites.dispose();
    await box.deleteFromDisk();
    await directory.delete(recursive: true);
  });

  Future<void> pumpEditor(
    WidgetTester tester,
    MealEntity meal, {
    bool editOnly = false,
  }) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const SizedBox.shrink());
    edited = null;
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => EnergyUnitProvider(usesKilojoules: kilojoules),
        child: MaterialApp(
          localizationsDelegates: const [S.delegate],
          supportedLocales: S.supportedLocales,
          onGenerateInitialRoutes: (_) => [
            MaterialPageRoute<void>(builder: (_) => const Scaffold()),
            MaterialPageRoute<void>(
              settings: RouteSettings(
                arguments: EditMealScreenArguments(
                  DateTime(2026, 10, 31),
                  meal,
                  IntakeTypeEntity.breakfast,
                  imperial,
                  editOnly: editOnly,
                ),
              ),
              builder: (_) => const EditMealScreen(),
            ),
          ],
          onGenerateRoute: (settings) {
            expect(settings.name, NavigationOptions.mealDetailRoute);
            edited =
                (settings.arguments as MealDetailScreenArguments).mealEntity;
            return MaterialPageRoute<void>(
              builder: (_) => const Scaffold(body: Text('detail')),
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> enterField(
    WidgetTester tester,
    String label,
    String value,
  ) async {
    final field = find.widgetWithText(TextFormField, label);
    await tester.scrollUntilVisible(
      field,
      300,
      scrollable: find
          .descendant(
            of: find.byType(ListView),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.enterText(field, value);
  }

  Future<void> save(WidgetTester tester) async {
    await tester.runAsync(() async {
      await tester.tap(
        find.widgetWithText(FilledButton, l10nEn.buttonSaveLabel),
      );
      await box.flush();
    });
    await tester.pumpAndSettle();
  }

  for (final (useImperial, useKj) in [
    (false, false),
    (false, true),
    (true, false),
    (true, true),
  ]) {
    for (final saveForLater in [true, false]) {
      testWidgets(
        'scanned correction survives detail and logging; save = $saveForLater, imperial = $useImperial, kj = $useKj',
        (tester) async {
          imperial = useImperial;
          kilojoules = useKj;
          await pumpEditor(tester, _scannedMeal());
          await enterField(
            tester,
            '${l10nEn.mealEnergyLabel} (${kilojoules ? l10nEn.kjLabel : l10nEn.kcalLabel})',
            kilojoules ? '920.5' : '220',
          );
          await enterField(tester, l10nEn.mealCarbsLabel, '30');
          if (!saveForLater) {
            final checkbox = find.byType(Checkbox);
            await tester.scrollUntilVisible(
              checkbox,
              300,
              scrollable: find
                  .descendant(
                    of: find.byType(ListView),
                    matching: find.byType(Scrollable),
                  )
                  .first,
            );
            await tester.tap(checkbox);
            await tester.pumpAndSettle();
          }
          await save(tester);
          expect(find.text('detail'), findsOneWidget);
          expect(library.getAllCustomMeals(), hasLength(saveForLater ? 2 : 1));
          expect(library.getAllCustomMeals().first.code, 'unrelated');

          final corrected = edited!;
          expect(corrected.nutriments.energyKcal100, 220);
          expect(corrected.nutriments.carbohydrates100, 30);
          expect(corrected.nutriments.fiber100, 6);
          expect(corrected.code, _barcode);
          expect(double.parse(corrected.mealQuantity!), closeTo(400, 0.3));
          expect(corrected.servingQuantity, closeTo(40, 0.1));
          expect(corrected.mealUnit, 'g');
          // Both hydration paths must leave the user's one-off or saved edit alone.
          expect(
            await fetchDetailedOffMeal(corrected, cache, products),
            isNull,
          );

          // Reopen the actual box, not just its in-memory values.
          await tester.runAsync(() async {
            await box.close();
            box = await Hive.openBox<MealDBO>('custom-meals');
          });
          library = CustomMealDataSource(
            FakeHiveDBProvider(customMealBox: box),
          );
          final reopenedScanner = SearchProductByBarcodeUseCase(
            products,
            library,
            cache,
            favourites.toggle,
          );
          var rescanned = await reopenedScanner.searchProductByBarcode(
            _barcode,
          );
          expect(rescanned.nutriments.energyKcal100, saveForLater ? 220 : 180);
          expect(
            rescanned.source,
            saveForLater ? MealSourceEntity.custom : MealSourceEntity.off,
          );
          if (saveForLater) {
            await pumpEditor(tester, rescanned, editOnly: true);
            expect(
              find.byType(SegmentedButton<CustomMealFormMode>),
              findsOneWidget,
            );
            final mode = tester.widget<SegmentedButton<CustomMealFormMode>>(
              find.byType(SegmentedButton<CustomMealFormMode>),
            );
            expect(mode.selected, {CustomMealFormMode.advanced});
            await save(tester);
            rescanned = await reopenedScanner.searchProductByBarcode(_barcode);
            expect(double.parse(rescanned.mealQuantity!), closeTo(400, 0.3));
            expect(rescanned.servingQuantity, closeTo(40, 0.1));
            expect(rescanned.mealUnit, 'g');
            expect(rescanned.nutriments.energyKcal100, 220);
            expect(rescanned.nutriments.fiber100, 6);
            expect(library.getAllCustomMeals(), hasLength(2));
          }
          final logged = _AddIntake();
          final totals = _AddDay();
          final detail = MealDetailBloc(
            logged,
            totals,
            _Goal(),
            _Macros(),
            _Day(),
            products,
            cache,
          );
          addTearDown(detail.close);
          detail.add(HydrateMealEvent(corrected));
          await tester.pumpAndSettle();
          expect(detail.state.hydratedMeal, isNull);
          detail.add(
            UpdateKcalEvent(
              meal: corrected,
              totalQuantity: '2',
              selectedUnit: 'serving',
            ),
          );
          await tester.pumpAndSettle();
          await detail.addIntake(
            tester.element(find.byType(Scaffold).last),
            'serving',
            detail.state.totalQuantityConverted,
            IntakeTypeEntity.breakfast,
            saveForLater ? rescanned : corrected,
            DateTime(2026, 10, 31),
          );
          await tester.pumpAndSettle();
          expect(logged.intakes.single.meal.nutriments.energyKcal100, 220);
          expect(logged.intakes.single.totalKcal, closeTo(176, 0.5));
          expect(logged.intakes.single.totalCarbsGram, closeTo(24, 0.1));
          expect(totals.kcal, closeTo(176, 0.5));
          // Only the saving-off rescan may read the original cache; no live refresh.
          expect(products.calls, 0);
          expect(cache.writes, isEmpty);
        },
      );
    }
  }

  for (final isNew in [true, false]) {
    testWidgets('representable custom food stays simple; new = $isNew', (
      tester,
    ) async {
      final meal = isNew
          ? MealEntity.empty()
          : const MealEntity(
              code: 'simple-custom',
              name: 'Simple oats',
              url: null,
              mealQuantity: '100',
              mealUnit: 'g/ml',
              servingQuantity: 100,
              servingUnit: 'g/ml',
              servingSize: '',
              nutriments: MealNutrimentsEntity(
                energyKcal100: 180,
                carbohydrates100: 20,
                fat100: 8,
                proteins100: 7,
                sugars100: null,
                saturatedFat100: null,
                fiber100: null,
              ),
              source: MealSourceEntity.custom,
            );
      await pumpEditor(tester, meal);
      final mode = tester.widget<SegmentedButton<CustomMealFormMode>>(
        find.byType(SegmentedButton<CustomMealFormMode>),
      );
      expect(mode.selected, {CustomMealFormMode.simple});
      if (isNew) {
        await tester.enterText(
          find.widgetWithText(TextFormField, l10nEn.mealNameLabel),
          'Simple oats',
        );
        await enterField(
          tester,
          '${l10nEn.mealEnergyLabel} (${l10nEn.kcalLabel})',
          '180',
        );
        await enterField(tester, l10nEn.mealCarbsLabel, '20');
        await enterField(tester, l10nEn.mealFatLabel, '8');
        await enterField(tester, l10nEn.mealProteinLabel, '7');
      }
      await save(tester);
      expect(edited!.nutriments.energyKcal100, 180);
      expect(edited!.mealQuantity, '100');
      expect(edited!.servingQuantity, 100);
      expect(edited!.mealUnit, 'g/ml');
    });
  }
}

class _Images extends Fake implements CacheManager {}

class _Config extends Fake implements GetConfigUsecase {
  _Config(this.imperial);
  final bool imperial;
  @override
  Future<ConfigEntity> getConfig() async => ConfigEntity(
    true,
    true,
    false,
    AppThemeEntity.system,
    usesImperialFoodUnits: imperial,
  );
}

class _FormMode extends Fake implements ConfigRepository {
  @override
  Future<String?> getCustomMealFormMode() async => 'simple';
}

class _Favourites extends Fake implements FavouriteMealRepository {
  @override
  Future<void> moveFavourite(MealEntity previous, MealEntity updated) async {}
}

class _Intakes extends Fake implements IntakeRepository {}

class _Products extends Fake implements ProductsRepository {
  int calls = 0;
  @override
  Future<MealEntity> getOFFProductByBarcode(
    String barcode, {
    String? knownName,
  }) async {
    calls++;
    return _scannedMeal();
  }
}

class _Cache extends Fake implements RemoteSearchCacheDataSource {
  final writes = <MealDBO>[];
  @override
  MealDBO? getDetailedByBarcode(String barcode) =>
      MealDBO.fromMealEntity(_scannedMeal());
  @override
  Future<void> cache(MealDBO meal) async => writes.add(meal);
  @override
  Future<void> touch(String code) async {}
}

class _AddIntake extends Fake implements AddIntakeUsecase {
  final intakes = <IntakeEntity>[];
  @override
  Future<void> addIntake(IntakeEntity intake) async => intakes.add(intake);
}

class _AddDay extends Fake implements AddTrackedDayUsecase {
  double? kcal;
  @override
  Future<bool> hasTrackedDay(DateTime day) async => true;
  @override
  Future<void> addDayCaloriesTracked(
    DateTime day,
    double caloriesTracked,
  ) async {
    kcal = caloriesTracked;
  }

  @override
  Future<void> addDayMacrosTracked(
    DateTime day, {
    double? carbsTracked,
    double? fatTracked,
    double? proteinTracked,
  }) async {}
}

class _Goal extends Fake implements GetKcalGoalUsecase {}

class _Macros extends Fake implements GetMacroGoalUsecase {}

class _Day extends Fake implements GetTrackedDayUsecase {
  @override
  Future<TrackedDayEntity?> getTrackedDay(DateTime day) async => null;
}
