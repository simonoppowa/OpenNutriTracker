import 'package:opennutritracker/core/presentation/widgets/local_user_image.dart';
import 'package:opennutritracker/core/presentation/widgets/image_full_screen.dart';
import 'dart:convert';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:opennutritracker/core/utils/user_image_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:opennutritracker/core/data/data_source/custom_meal_data_source.dart';
import 'package:opennutritracker/core/data/data_source/remote_search_cache_data_source.dart';
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
import 'package:opennutritracker/core/domain/usecase/get_intake_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_kcal_goal_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_macro_goal_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_tracked_day_usecase.dart';
import 'package:opennutritracker/core/utils/energy_unit_provider.dart';
import 'package:opennutritracker/core/utils/navigation_options.dart';
import 'package:opennutritracker/features/add_meal/data/repository/products_repository.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_nutriments_entity.dart';
import 'package:opennutritracker/features/add_meal/presentation/bloc/favourite_toggle_bloc.dart';
import 'package:opennutritracker/features/edit_meal/presentation/bloc/edit_meal_bloc.dart';
import 'package:opennutritracker/features/edit_meal/presentation/edit_meal_screen.dart';
import 'package:opennutritracker/features/meal_detail/meal_detail_screen.dart';
import 'package:opennutritracker/features/meal_detail/presentation/bloc/meal_detail_bloc.dart';
import 'package:opennutritracker/generated/l10n.dart';
import 'package:provider/provider.dart';
import '../../../helpers/fake_favourites.dart';
import '../../../helpers/test_l10n.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/usecase/search_products_usecase.dart';
import 'package:opennutritracker/features/add_meal/presentation/add_meal_screen.dart';
import 'package:opennutritracker/features/add_meal/presentation/add_meal_type.dart';
import 'package:opennutritracker/features/add_meal/presentation/bloc/add_meal_bloc.dart';
import 'package:opennutritracker/features/add_meal/presentation/bloc/favourite_meal_bloc.dart';
import 'package:opennutritracker/features/add_meal/presentation/bloc/food_bloc.dart';
import 'package:opennutritracker/features/add_meal/presentation/bloc/products_bloc.dart';
import 'package:opennutritracker/features/add_meal/presentation/bloc/recent_meal_bloc.dart';

import 'dart:io';
import 'package:hive_ce/hive.dart';
import 'package:opennutritracker/core/data/data_source/intake_data_source.dart';
import 'package:opennutritracker/core/data/data_source/recipe_data_source.dart';
import 'package:opennutritracker/core/data/dbo/meal_dbo.dart';
import 'package:opennutritracker/core/data/dbo/intake_dbo.dart';
import 'package:opennutritracker/core/data/dbo/recipe_dbo.dart';
import 'package:opennutritracker/core/data/repository/recipe_repository.dart';
import '../../../helpers/fake_hive_db_provider.dart';
import '../../../helpers/hive_test_setup.dart';
import 'package:opennutritracker/features/meal_detail/presentation/widgets/meal_detail_bottom_sheet.dart';

void main() {
  final getIt = GetIt.instance;
  late Directory directory;
  late PathProviderPlatform originalPaths;
  late Box<MealDBO> meals;
  late Box<IntakeDBO> intakes;
  late CustomMealDataSource library;
  late IntakeRepository history;
  final day = DateTime(2026, 11, 1);
  final blocs = <EditMealBloc>[];

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('save-reopen-');
    originalPaths = PathProviderPlatform.instance;
    PathProviderPlatform.instance = _FakePaths(directory.path);
    Hive.init(directory.path);
    registerHiveAdaptersOnce();
    meals = await Hive.openBox<MealDBO>('meals');
    intakes = await Hive.openBox<IntakeDBO>('intakes');
    final db = FakeHiveDBProvider(
      customMealBox: meals,
      intakeBox: intakes,
      recipeBox: await Hive.openBox<RecipeDBO>('recipes'),
    );
    library = CustomMealDataSource(db);
    history = IntakeRepository(IntakeDataSource(db));
    final config = _FakeGetConfigUsecase();
    final recent = GetIntakeUsecase(
      history,
      RecipeRepository(RecipeDataSource(db)),
      library,
    );
    getIt.registerSingleton<GetConfigUsecase>(config);
    getIt.registerSingleton<GetIntakeUsecase>(recent);
    getIt.registerFactory<AddMealBloc>(() => AddMealBloc(config));
    getIt.registerFactory<ProductsBloc>(
      () => ProductsBloc(_FakeSearch(), config),
    );
    getIt.registerFactory<FoodBloc>(() => FoodBloc(_FakeSearch(), config));
    getIt.registerFactory<RecentMealBloc>(() => RecentMealBloc(recent, config));
    final favourites = FakeFavourites();
    addTearDown(favourites.dispose);
    getIt.registerFactory<FavouriteMealBloc>(
      () => FavouriteMealBloc(favourites.get, config),
    );
    getIt.registerFactory<FavouriteToggleBloc>(
      () => FavouriteToggleBloc(favourites.get, favourites.toggle),
    );
    getIt.registerLazySingleton<CacheManager>(_FakeCacheManager.new);
    getIt.registerFactory<MealDetailBloc>(
      () => MealDetailBloc(
        _FakeAddIntakeUsecase([]),
        _FakeAddTrackedDayUsecase(),
        _FakeGetKcalGoalUsecase(),
        _FakeGetMacroGoalUsecase(),
        _FakeGetTrackedDayUsecase(),
        _FakeProductsRepository(),
        _FakeRemoteSearchCacheDataSource(),
      ),
    );
    getIt.registerFactory<EditMealBloc>(() {
      final bloc = EditMealBloc(
        config,
        library,
        _FakeConfigRepository(),
        _FakeFavouriteMealRepository(),
        history,
      );
      blocs.add(bloc);
      return bloc;
    });
  });

  tearDown(() async {
    for (final bloc in blocs) {
      await bloc.close();
    }
    blocs.clear();
    await getIt.reset();
    PathProviderPlatform.instance = originalPaths;
    await Hive.close();
    await directory.delete(recursive: true);
  });

  for (final saveForLater in [false, true]) {
    for (final withPhoto in [false, true]) {
      testWidgets(
        'Recently edit save=$saveForLater reopens serving and photo=$withPhoto without changing history',
        (tester) async {
          String? photo;
          if (withPhoto) {
            await tester.runAsync(() async {
              final source = File('${directory.path}/synthetic.png');
              await source.writeAsBytes(
                base64Decode(
                  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+aN1sAAAAASUVORK5CYII=',
                ),
              );
              photo = await UserImageStorage.importFrom(
                kind: UserImageKind.meal,
                ownerId: 'synthetic-solid',
                sourcePath: source.path,
              );
            });
          }
          final meal = MealEntity(
            localImagePath: photo,
            code: 'synthetic-solid',
            name: 'Synthetic solid',
            url: null,
            mealQuantity: '60',
            mealUnit: 'g',
            servingQuantity: 30,
            servingUnit: 'g',
            servingSize: null,
            source: MealSourceEntity.custom,
            detailed: true,
            nutriments: const MealNutrimentsEntity(
              energyKcal100: 460,
              carbohydrates100: 60,
              fat100: 20,
              proteins100: 10,
              sugars100: null,
              saturatedFat100: null,
              fiber100: null,
            ),
          );
          await tester.runAsync(() async {
            await library.saveCustomMeal(MealDBO.fromMealEntity(meal));
            await history.addIntake(
              IntakeEntity(
                id: 'existing',
                unit: 'g',
                amount: 60,
                type: IntakeTypeEntity.breakfast,
                meal: meal,
                dateTime: day,
              ),
            );
          });
          tester.view.physicalSize = const Size(1080, 2400);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);
          final navigator = GlobalKey<NavigatorState>();
          await tester.pumpWidget(
            ChangeNotifierProvider(
              create: (_) => EnergyUnitProvider(),
              child: MaterialApp(
                navigatorKey: navigator,
                localizationsDelegates: const [S.delegate],
                supportedLocales: S.supportedLocales,
                initialRoute: NavigationOptions.addMealRoute,
                onGenerateRoute: (settings) => MaterialPageRoute<void>(
                  settings: settings.name == NavigationOptions.addMealRoute
                      ? RouteSettings(
                          name: settings.name,
                          arguments: AddMealScreenArguments(
                            AddMealType.breakfastType,
                            day,
                          ),
                        )
                      : settings,
                  builder: (_) => switch (settings.name) {
                    NavigationOptions.addMealRoute => const AddMealScreen(),
                    NavigationOptions.mealDetailRoute =>
                      const MealDetailScreen(),
                    NavigationOptions.editMealRoute => const EditMealScreen(),
                    NavigationOptions.imageFullScreenRoute =>
                      const ImageFullScreen(),
                    _ => const Scaffold(),
                  },
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          if (withPhoto) {
            expect(find.byType(LocalUserImage), findsOneWidget);
          }
          await tester.tap(
            find.textContaining('Synthetic solid', findRichText: true),
          );
          await tester.pumpAndSettle();
          if (withPhoto) {
            await tester.tap(find.byType(LocalUserImage));
            await tester.pumpAndSettle();
            expect(find.byType(ImageFullScreen), findsOneWidget);
            expect(find.byType(LocalUserImage), findsOneWidget);
            navigator.currentState!.pop();
            await tester.pumpAndSettle();
          }
          await tester.tap(find.byIcon(Icons.edit_rounded));
          await tester.pumpAndSettle();
          final serving = find.widgetWithText(
            TextFormField,
            '${l10nEn.servingSizeLabelMetric} (${l10nEn.ozUnit})',
          );
          await tester.ensureVisible(serving);
          await tester.enterText(serving, '1');
          expect(
            tester.widget<Checkbox>(find.byType(Checkbox).first).value,
            isTrue,
          );
          if (!saveForLater) {
            await tester.ensureVisible(find.byType(Checkbox).first);
            await tester.tap(find.byType(Checkbox).first);
            await tester.pumpAndSettle();
          }
          await tester.runAsync(() async {
            await tester.tap(
              find.widgetWithText(FilledButton, l10nEn.buttonSaveLabel),
            );
            await meals.flush();
          });
          await tester.pumpAndSettle();
          final saved = MealEntity.fromMealDBO(meals.values.single);
          expect(saved.localImagePath, photo);
          if (withPhoto) {
            await tester.runAsync(() async {
              expect(
                await File(
                  await UserImageStorage.absolutePath(photo!),
                ).exists(),
                isTrue,
              );
            });
            await tester.pumpAndSettle();
            expect(
              find.byWidgetPredicate((w) => w is Image && w.image is FileImage),
              findsOneWidget,
            );
          }
          expect(
            saved.servingQuantity,
            closeTo(saveForLater ? 28.3495 : 30, .0001),
          );
          expect(saved.mealQuantity, '60');
          expect(saved.nutriments.energyKcal100, 460);
          // Immediate detail is right; the old route below it must also refresh.
          expect(
            (tester.widget<MealDetailBottomSheet>(
              find.byType(MealDetailBottomSheet),
            )).product.servingQuantity,
            closeTo(28.3495, .0001),
          );
          expect(
            tester
                .widget<MealDetailBottomSheet>(
                  find.byType(MealDetailBottomSheet),
                )
                .mealDetailBloc
                .state
                .totalKcal,
            closeTo(130.4077, .001),
          );
          if (saveForLater) {
            // Save replaces Detail: edit again before returning to Recently.
            await tester.tap(find.byIcon(Icons.edit_rounded));
            await tester.pumpAndSettle();
            await tester.ensureVisible(serving);
            await tester.enterText(serving, '2');
            await tester.runAsync(() async {
              await tester.tap(
                find.widgetWithText(FilledButton, l10nEn.buttonSaveLabel),
              );
              await meals.flush();
            });
            await tester.pumpAndSettle();
            expect(
              tester
                  .widget<MealDetailBottomSheet>(
                    find.byType(MealDetailBottomSheet),
                  )
                  .product
                  .servingQuantity,
              closeTo(56.699, .0001),
            );
          }
          navigator.currentState!.pop();
          await tester.pumpAndSettle();
          await tester.tap(
            find.textContaining('Synthetic solid', findRichText: true),
          );
          await tester.pumpAndSettle();
          expect(
            (tester.widget<MealDetailBottomSheet>(
              find.byType(MealDetailBottomSheet),
            )).product.servingQuantity,
            closeTo(saveForLater ? 56.699 : 30, .0001),
          );
          if (withPhoto) {
            expect(
              find.byWidgetPredicate((w) => w is Image && w.image is FileImage),
              findsOneWidget,
            );
          }
          expect(
            tester
                .widget<MealDetailBottomSheet>(
                  find.byType(MealDetailBottomSheet),
                )
                .mealDetailBloc
                .state
                .totalKcal,
            closeTo(saveForLater ? 260.8154 : 138, .001),
          );
          expect(intakes.length, 1);
          final logged = await history.getIntakeById('existing');
          expect(logged!.amount, 60);
          expect(logged.totalKcal, 276);
          expect(logged.meal.servingQuantity, 30);
          await tester.runAsync(() async {
            await meals.close();
            meals = await Hive.openBox<MealDBO>('meals');
          });
          final durable = MealEntity.fromMealDBO(meals.values.single);
          expect(
            durable.servingQuantity,
            closeTo(saveForLater ? 56.699 : 30, .0001),
          );
          expect(durable.localImagePath, photo);
        },
      );
    }
  }
}

class _FakeGetConfigUsecase implements GetConfigUsecase {
  @override
  Future<ConfigEntity> getConfig() async => const ConfigEntity(
    true,
    true,
    false,
    AppThemeEntity.system,
    usesImperialFoodUnits: true,
  );

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('Unexpected call: ${invocation.memberName}');
}

class _FakeConfigRepository implements ConfigRepository {
  @override
  Future<bool> getCustomMealNutrientsTotal() async => false;

  @override
  Future<String?> getCustomMealFormMode() async =>
      CustomMealFormMode.advanced.name;

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

class _FakeFavouriteMealRepository implements FavouriteMealRepository {
  @override
  Future<void> moveFavourite(MealEntity previous, MealEntity updated) async {}
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeSearch implements SearchProductsUseCase {
  final List<String> offQueries = [];
  final List<String> fdcQueries = [];
  List<MealEntity> products = const [];
  List<MealEntity> food = const [];

  @override
  Future<SearchProductsResult> searchOFFProductsByString(
    String searchString, {
    bool skipRemote = false,
  }) async {
    offQueries.add(searchString);
    return SearchProductsResult(meals: products, remoteSourceEmpty: true);
  }

  @override
  Future<SearchProductsResult> searchFDCFoodByString(
    String searchString, {
    bool skipRemote = false,
    bool forResolution = false,
  }) async {
    fdcQueries.add(searchString);
    return SearchProductsResult(meals: food, remoteSourceEmpty: true);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('Unexpected call: ${invocation.memberName}');
}

class _FakePaths extends PathProviderPlatform with MockPlatformInterfaceMixin {
  _FakePaths(this.path);
  final String path;
  @override
  Future<String?> getApplicationDocumentsPath() async => path;
}
