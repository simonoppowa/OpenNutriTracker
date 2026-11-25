import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/data/data_source/custom_meal_data_source.dart';
import 'package:opennutritracker/core/data/data_source/recipe_data_source.dart';
import 'package:opennutritracker/core/data/data_source/remote_search_cache_data_source.dart';
import 'package:opennutritracker/core/data/dbo/app_theme_dbo.dart';
import 'package:opennutritracker/core/data/dbo/config_dbo.dart';
import 'package:opennutritracker/core/data/dbo/meal_dbo.dart';
import 'package:opennutritracker/core/data/dbo/recipe_dbo.dart';
import 'package:opennutritracker/core/domain/entity/app_theme_entity.dart';
import 'package:opennutritracker/core/domain/entity/config_entity.dart';
import 'package:opennutritracker/core/domain/entity/intake_entity.dart';
import 'package:opennutritracker/core/domain/usecase/get_config_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_intake_usecase.dart';
import 'package:opennutritracker/core/utils/off_const.dart';
import 'package:opennutritracker/features/add_meal/data/repository/products_repository.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_nutriments_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/usecase/search_products_usecase.dart';

/// #946: Open Food Facts can be switched off in Settings → Food databases
/// like the backend databases. Off, a product search asks OFF nothing and
/// answers from the user's own foods; on — the default, and what every
/// existing install has stored — it behaves exactly as before.
void main() {
  group('the stored Open Food Facts setting', () {
    test('a config that never stored it reads as on', () {
      final entity = ConfigEntity.fromConfigDBO(
        ConfigDBO(false, false, false, AppThemeDBO.system),
      );

      expect(entity.isOffEnabled, isTrue);
    });

    test('backend choices stored before #946 leave it on', () {
      final entity = ConfigEntity.fromConfigDBO(
        ConfigDBO(
          false,
          false,
          false,
          AppThemeDBO.system,
          foodSourceToggles: {'bls': false, 'fdc_branded': true},
        ),
      );

      expect(entity.isOffEnabled, isTrue);
      expect(entity.isFoodSourceEnabled('bls'), isFalse);
    });

    test('switched off, it reads as off and leaves the backend ones alone', () {
      final entity = ConfigEntity.fromConfigDBO(
        ConfigDBO(
          false,
          false,
          false,
          AppThemeDBO.system,
          foodSourceToggles: {OFFConst.offSourceCode: false},
        ),
      );

      expect(entity.isOffEnabled, isFalse);
      expect(entity.isFoodSourceEnabled('bls'), isTrue);
    });

    test('the OFF code is not a backend source code', () {
      // The backend data source builds its source filter from the backend
      // codes only, so an OFF entry in the same map never reaches it.
      expect(
        OFFConst.offSourceCode,
        isNot(
          anyOf(
            'fdc_foundation',
            'fdc_sr_legacy',
            'fdc_survey',
            'fdc_branded',
            'bls',
          ),
        ),
      );
    });
  });

  group('product search', () {
    late _FakeProductsRepository products;
    late _FakeCustomMealDataSource customMeals;
    late _FakeRecipeDataSource recipes;
    late _FakeCache cache;
    late _FakeGetConfigUsecase config;
    late SearchProductsUseCase useCase;

    setUp(() {
      products = _FakeProductsRepository();
      customMeals = _FakeCustomMealDataSource();
      recipes = _FakeRecipeDataSource();
      cache = _FakeCache();
      config = _FakeGetConfigUsecase();
      useCase = SearchProductsUseCase(
        products,
        _FakeGetIntakeUsecase(),
        customMeals,
        cache,
        recipes,
        config,
      );
    });

    group('with Open Food Facts switched off', () {
      setUp(() => config.toggles = {OFFConst.offSourceCode: false});

      test('asks OFF nothing and answers with the custom foods', () async {
        customMeals.meals.add(
          MealDBO.fromMealEntity(
            _meal('c1', 'Oat porridge', MealSourceEntity.custom),
          ),
        );
        products.offResults['oat'] = [
          _meal('off-1', 'Oat drink', MealSourceEntity.off),
        ];

        final result = await useCase.searchOFFProductsByString('oat');

        expect(products.offCalls, 0);
        expect(result.meals.map((m) => m.code), ['c1']);
        // Not a failure and not "OFF found nothing": OFF was not asked.
        expect(result.remoteSourceEmpty, isFalse);
        expect(result.remoteSourceFailed, isFalse);
        expect(cache.cached, isEmpty);
      });

      test('leaves out OFF products cached by earlier searches', () async {
        cache.meals.add(
          MealDBO.fromMealEntity(
            _meal('off-cached', 'Oat bar', MealSourceEntity.off),
          ),
        );

        final result = await useCase.searchOFFProductsByString('oat');

        expect(result.meals, isEmpty);
        expect(products.offCalls, 0);
      });

      test('the backend search still runs', () async {
        products.fdcResults['oat'] = [
          _meal('fdc-1', 'Oats, raw', MealSourceEntity.fdc),
        ];

        final result = await useCase.searchFDCFoodByString('oat');

        expect(result.meals.map((m) => m.code), ['fdc-1']);
        expect(products.fdcCalls, 1);
      });
    });

    group('with Open Food Facts on', () {
      for (final entry in {
        'never stored (every existing install)': <String, bool>{},
        'switched on': {OFFConst.offSourceCode: true},
      }.entries) {
        test('${entry.key}: asks OFF and lists custom foods first', () async {
          config.toggles = entry.value;
          customMeals.meals.add(
            MealDBO.fromMealEntity(
              _meal('c1', 'Oat porridge', MealSourceEntity.custom),
            ),
          );
          products.offResults['oat'] = [
            _meal('off-1', 'Oat drink', MealSourceEntity.off),
          ];

          final result = await useCase.searchOFFProductsByString('oat');

          expect(products.offCalls, 1);
          expect(result.meals.map((m) => m.code), ['c1', 'off-1']);
          expect(cache.cached.map((m) => m.code), ['off-1']);
        });
      }
    });
  });
}

MealEntity _meal(String code, String name, MealSourceEntity source) =>
    MealEntity(
      code: code,
      name: name,
      url: null,
      mealQuantity: '100',
      mealUnit: 'g',
      servingQuantity: null,
      servingUnit: 'g',
      servingSize: null,
      nutriments: const MealNutrimentsEntity(
        energyKcal100: 100,
        carbohydrates100: null,
        fat100: null,
        proteins100: null,
        sugars100: null,
        saturatedFat100: null,
        fiber100: null,
      ),
      source: source,
    );

class _FakeProductsRepository implements ProductsRepository {
  final Map<String, List<MealEntity>> offResults = {};
  final Map<String, List<MealEntity>> fdcResults = {};
  int offCalls = 0;
  int fdcCalls = 0;

  @override
  Future<List<MealEntity>> getOFFProductsByString(String searchString) async {
    offCalls++;
    return offResults[searchString] ?? const [];
  }

  @override
  Future<List<MealEntity>> getSupabaseFoodsByString(
    String searchString, {
    bool forResolution = false,
  }) async {
    fdcCalls++;
    return fdcResults[searchString] ?? const [];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('Unexpected call: ${invocation.memberName}');
}

class _FakeGetIntakeUsecase implements GetIntakeUsecase {
  @override
  Future<List<IntakeEntity>> getRecentIntake() async => const [];

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('Unexpected call: ${invocation.memberName}');
}

class _FakeGetConfigUsecase implements GetConfigUsecase {
  Map<String, bool> toggles = const <String, bool>{};

  @override
  Future<ConfigEntity> getConfig() async => ConfigEntity(
    true,
    true,
    false,
    AppThemeEntity.system,
    foodSourceToggles: toggles,
  );

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('Unexpected call: ${invocation.memberName}');
}

class _FakeCustomMealDataSource implements CustomMealDataSource {
  final List<MealDBO> meals = [];

  @override
  List<MealDBO> getAllCustomMeals() => meals;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('Unexpected call: ${invocation.memberName}');
}

class _FakeRecipeDataSource implements RecipeDataSource {
  @override
  List<RecipeDBO> getAllRecipes() => const [];

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('Unexpected call: ${invocation.memberName}');
}

class _FakeCache implements RemoteSearchCacheDataSource {
  final List<MealDBO> meals = [];
  final List<MealDBO> cached = [];

  @override
  List<MealDBO> getAllByMostRecentlyTouched() => List.of(meals);

  @override
  Future<void> cacheFromSearch(Iterable<MealDBO> incoming) async {
    for (final meal in incoming) {
      cached.add(meal);
      meals.add(meal);
    }
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('Unexpected call: ${invocation.memberName}');
}
