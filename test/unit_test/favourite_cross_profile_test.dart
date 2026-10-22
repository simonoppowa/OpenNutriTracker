import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:opennutritracker/core/data/data_source/custom_meal_data_source.dart';
import 'package:opennutritracker/core/data/data_source/favourite_meal_data_source.dart';
import 'package:opennutritracker/core/data/data_source/intake_data_source.dart';
import 'package:opennutritracker/core/data/data_source/recipe_data_source.dart';
import 'package:opennutritracker/core/data/data_source/tracked_day_data_source.dart';
import 'package:opennutritracker/core/data/dbo/favourite_meal_dbo.dart';
import 'package:opennutritracker/core/data/dbo/intake_dbo.dart';
import 'package:opennutritracker/core/data/dbo/meal_dbo.dart';
import 'package:opennutritracker/core/data/dbo/profile_dbo.dart';
import 'package:opennutritracker/core/data/dbo/recipe_dbo.dart';
import 'package:opennutritracker/core/data/dbo/tracked_day_dbo.dart';
import 'package:opennutritracker/core/data/repository/config_repository.dart';
import 'package:opennutritracker/core/data/repository/favourite_meal_repository.dart';
import 'package:opennutritracker/core/data/repository/intake_repository.dart';
import 'package:opennutritracker/core/data/repository/recipe_repository.dart';
import 'package:opennutritracker/core/data/repository/tracked_day_repository.dart';
import 'package:opennutritracker/core/domain/entity/recipe_entity.dart';
import 'package:opennutritracker/core/domain/usecase/add_tracked_day_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/delete_recipe_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_config_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/merge_custom_meals_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/toggle_favourite_meal_usecase.dart';
import 'package:opennutritracker/core/utils/hive_db_provider.dart';
import 'package:opennutritracker/core/utils/tracked_day_lock.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_nutriments_entity.dart';
import 'package:opennutritracker/features/edit_meal/presentation/bloc/edit_meal_bloc.dart';

import '../helpers/fake_hive_db_provider.dart';
import '../helpers/hive_test_setup.dart';

/// Profiles `a`, `b` and `c`, each with its own favourites box; one is
/// active, the others are reached through [openScopedBox] the way the real
/// provider opens a profile that is not active.
class _ProfilesProvider extends FakeHiveDBProvider {
  _ProfilesProvider({
    required this.favourites,
    required super.customMealBox,
    required super.recipeBox,
    required super.profileBox,
  }) : super(activeProfileId: 'a');

  final Map<String, Box<FavouriteMealDBO>> favourites;
  final closed = <String>[];

  /// What a profile switch does to the active box-set.
  void activate(String id) => activeProfileId = id;

  @override
  Box<FavouriteMealDBO> get favouriteMealBox => favourites[activeProfileId]!;

  // The suffix is the profile id here.
  @override
  Future<Box<E>> openScopedBox<E>(String baseName, String boxSuffix) async {
    expect(baseName, HiveDBProvider.favouriteMealBoxName);
    expect(boxSuffix, isNot(activeProfileId));
    return favourites[boxSuffix]! as Box<E>;
  }

  // The boxes outlive the call so the test can read them; record instead.
  @override
  Future<void> closeScopedBox<E>(String baseName, String boxSuffix) async {
    closed.add(boxSuffix);
  }
}

/// A custom-meal save that waits for the test to let it land.
class _GatedCustomMealDataSource extends CustomMealDataSource {
  _GatedCustomMealDataSource(super.db);

  final gate = Completer<void>();

  @override
  Future<void> saveCustomMeal(MealDBO mealDBO, {MealDBO? previous}) async {
    await gate.future;
    await super.saveCustomMeal(mealDBO, previous: previous);
  }
}

class _FakeGetConfigUsecase implements GetConfigUsecase {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('Unexpected call: ${invocation.memberName}');
}

class _FakeConfigRepository implements ConfigRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('Unexpected call: ${invocation.memberName}');
}

/// No diary entries to move: these tests are about the favourites (#1417).
class _NoIntakesRepository implements IntakeRepository {
  @override
  Future<int> moveCustomMealInEveryProfile({
    required String fromMealKey,
    required MealDBO toMeal,
  }) async => 0;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('Unexpected call: ${invocation.memberName}');
}

MealEntity _meal(String code, {double kcal = 150, String name = 'Oats'}) =>
    MealEntity(
      code: code,
      name: name,
      url: null,
      mealQuantity: '100',
      mealUnit: 'g',
      servingQuantity: null,
      servingUnit: null,
      servingSize: null,
      nutriments: MealNutrimentsEntity(
        energyKcal100: kcal,
        carbohydrates100: null,
        fat100: null,
        proteins100: null,
        sugars100: null,
        saturatedFat100: null,
        fiber100: null,
      ),
      source: MealSourceEntity.custom,
    );

RecipeEntity _recipe(String name) => RecipeEntity(
  id: 'r1',
  name: name,
  description: null,
  ingredients: const [],
  totalWeightG: 300,
  aggregatedNutrimentsPer100: MealNutrimentsEntity.empty(),
  createdAt: DateTime(2026, 10, 1),
  updatedAt: DateTime(2026, 10, 1),
  servingsCount: null,
);

FavouriteMealDBO _favourite(MealEntity meal, DateTime addedAt) =>
    FavouriteMealDBO(meal: MealDBO.fromMealEntity(meal), addedAt: addedAt);

/// #1307: the custom-meal and recipe libraries are shared by every profile,
/// each profile has its own favourites. A change to the library from one
/// profile reaches the others' favourites, and stars nothing new.
void main() {
  late Map<String, Box<FavouriteMealDBO>> favourites;
  late Box<MealDBO> customMealBox;
  late Box<RecipeDBO> recipeBox;
  late Box<ProfileDBO> profileBox;
  late _ProfilesProvider provider;
  late FavouriteMealRepository repository;
  final starredAt = DateTime(2026, 10, 2, 8);

  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    Hive.init('.');
    registerHiveAdaptersOnce();
  });

  setUp(() async {
    final tag = DateTime.now().microsecondsSinceEpoch;
    favourites = {
      for (final id in ['a', 'b', 'c'])
        id: await Hive.openBox<FavouriteMealDBO>('xprofile_fav_${id}_$tag'),
    };
    customMealBox = await Hive.openBox<MealDBO>('xprofile_custom_$tag');
    recipeBox = await Hive.openBox<RecipeDBO>('xprofile_recipes_$tag');
    profileBox = await Hive.openBox<ProfileDBO>('xprofile_profiles_$tag');
    for (final id in ['a', 'b', 'c']) {
      await profileBox.put(
        id,
        ProfileDBO(
          id: id,
          name: id,
          createdAt: DateTime(2026),
          boxSuffix: id,
        ),
      );
    }
    provider = _ProfilesProvider(
      favourites: favourites,
      customMealBox: customMealBox,
      recipeBox: recipeBox,
      profileBox: profileBox,
    );
    repository = FavouriteMealRepository(
      FavouriteMealDataSource(provider),
      CustomMealDataSource(provider),
      RecipeDataSource(provider),
    );
  });

  tearDown(() async {
    for (final box in favourites.values) {
      await box.deleteFromDisk();
    }
    await customMealBox.deleteFromDisk();
    await recipeBox.deleteFromDisk();
    await profileBox.deleteFromDisk();
  });

  test(
    'a custom meal deleted in one profile keeps its latest version in every '
    'profile that stars it',
    () async {
      // Profile A stars the meal at 150 kcal; profile B, active now, edits
      // the shared meal to 180 kcal and deletes it.
      await favourites['a']!.put('custom:c1', _favourite(_meal('c1'), starredAt));
      final library = CustomMealDataSource(provider);
      await library.saveCustomMeal(MealDBO.fromMealEntity(_meal('c1')));
      await library.saveCustomMeal(
        MealDBO.fromMealEntity(_meal('c1', kcal: 180, name: 'Better oats')),
      );
      provider.activate('b');

      await withTrackedDayLock(() async {
        await repository.keepLatestCustomMealSnapshot('c1');
        await library.deleteCustomMeal('c1');
      });

      final kept = favourites['a']!.get('custom:c1')!;
      expect(kept.meal.name, 'Better oats');
      expect(kept.meal.nutriments.energyKcal100, 180);
      expect(kept.addedAt, starredAt);
      // Nothing is starred where it was not.
      expect(favourites['b']!.isEmpty, isTrue);
      expect(favourites['c']!.isEmpty, isTrue);
      expect(provider.closed, unorderedEquals(['a', 'c']));

      provider.activate('a');
      final shown = await repository.getAllFavourites();
      expect(shown.single.nutriments.energyKcal100, 180);
    },
  );

  test(
    'a recipe deleted after an edit keeps the edited version on Favourites',
    () async {
      final recipes = RecipeDataSource(provider);
      await recipes.saveRecipe(_recipe('Chili').toDBO());
      await repository.addFavourite(_recipe('Chili').toMealEntity());
      await favourites['b']!.put(
        'recipe:r1',
        _favourite(_recipe('Chili').toMealEntity(), starredAt),
      );
      await recipes.saveRecipe(_recipe('Chili con carne').toDBO());

      await DeleteRecipeUseCase(
        RecipeRepository(recipes),
        repository,
      ).delete('r1');

      expect(recipeBox.isEmpty, isTrue);
      final shown = await repository.getAllFavourites();
      expect(shown.single.name, 'Chili con carne');
      expect(shown.single.source, MealSourceEntity.recipe);
      expect(favourites['b']!.get('recipe:r1')!.meal.name, 'Chili con carne');
      expect(favourites['b']!.get('recipe:r1')!.addedAt, starredAt);
      expect(favourites['c']!.isEmpty, isTrue);
    },
  );

  test(
    'merging a starred meal moves its favourite in every profile',
    () async {
      final tag = DateTime.now().microsecondsSinceEpoch;
      final intakeBox = await Hive.openBox<IntakeDBO>('xprofile_intake_$tag');
      final trackedBox = await Hive.openBox<TrackedDayDBO>(
        'xprofile_tracked_$tag',
      );
      addTearDown(() async {
        await intakeBox.deleteFromDisk();
        await trackedBox.deleteFromDisk();
      });
      final library = CustomMealDataSource(provider);
      final loser = _meal('L', name: 'Oats (dup)');
      final winner = _meal('W', kcal: 160);
      await library.saveCustomMeal(MealDBO.fromMealEntity(loser));
      await library.saveCustomMeal(MealDBO.fromMealEntity(winner));
      final earlier = DateTime(2026, 9, 1);
      // A and B star the duplicate; B also stars the winner, later; C
      // stars only the winner.
      await favourites['a']!.put('custom:L', _favourite(loser, starredAt));
      await favourites['b']!.put('custom:L', _favourite(loser, earlier));
      await favourites['b']!.put('custom:W', _favourite(winner, starredAt));
      await favourites['c']!.put('custom:W', _favourite(winner, starredAt));

      await MergeCustomMealsUseCase(
        library,
        IntakeRepository(
          IntakeDataSource(FakeHiveDBProvider(intakeBox: intakeBox)),
        ),
        AddTrackedDayUsecase(
          TrackedDayRepository(
            TrackedDayDataSource(FakeHiveDBProvider(trackedDayBox: trackedBox)),
          ),
        ),
        repository,
      ).merge(loserKey: 'L', winnerKey: 'W');

      for (final id in ['a', 'b', 'c']) {
        expect(favourites[id]!.keys, ['custom:W'], reason: id);
        expect(
          favourites[id]!.get('custom:W')!.meal.nutriments.energyKcal100,
          160,
          reason: id,
        );
      }
      expect(favourites['a']!.get('custom:W')!.addedAt, starredAt);
      expect(favourites['b']!.get('custom:W')!.addedAt, earlier);
      expect(customMealBox.values.map((m) => m.code), ['W']);
    },
  );

  test(
    'a hydrated search result replaces the thin snapshot in every profile',
    () async {
      MealEntity off({required bool detailed}) => MealEntity(
        code: '0080457761112',
        name: 'Crisps',
        url: null,
        mealQuantity: detailed ? '25' : null,
        mealUnit: detailed ? 'g' : null,
        servingQuantity: detailed ? 31.8 : null,
        servingUnit: detailed ? 'g' : null,
        servingSize: null,
        nutriments: MealNutrimentsEntity.empty(),
        source: MealSourceEntity.off,
        detailed: detailed,
      );
      final thin = off(detailed: false);
      await favourites['a']!.put('off:0080457761112', _favourite(thin, starredAt));
      await favourites['b']!.put('off:0080457761112', _favourite(thin, starredAt));

      // A thin record never overwrites anything.
      await withTrackedDayLock(() => repository.refreshDetailedSnapshot(thin));
      await withTrackedDayLock(
        () => repository.refreshDetailedSnapshot(off(detailed: true)),
      );

      for (final id in ['a', 'b']) {
        final stored = favourites[id]!.get('off:0080457761112')!;
        expect(stored.meal.detailed, isTrue, reason: id);
        expect(stored.meal.servingQuantity, 31.8, reason: id);
        expect(stored.addedAt, starredAt, reason: id);
      }
      expect(favourites['c']!.isEmpty, isTrue);
    },
  );

  test(
    'a profile switch during a pending edit waits, and every profile keeps '
    'its favourite',
    () async {
      final original = _meal('c1');
      await CustomMealDataSource(
        provider,
      ).saveCustomMeal(MealDBO.fromMealEntity(original));
      await favourites['a']!.put('custom:c1', _favourite(original, starredAt));
      await favourites['b']!.put('custom:c1', _favourite(original, starredAt));
      final gated = _GatedCustomMealDataSource(provider);
      final bloc = EditMealBloc(
        _FakeGetConfigUsecase(),
        gated,
        _FakeConfigRepository(),
        repository,
        _NoIntakesRepository(),
      );

      // The edit gives the meal a barcode, then the user switches to B
      // while the save is still pending.
      final edited = _meal('4006381333931', kcal: 180);
      final save = bloc.saveCustomMeal(edited, previous: original);
      var movedBeforeSwitch = false;
      final switched = withProfileSwitchLock(() async {
        movedBeforeSwitch = favourites['a']!.containsKey(
          'custom:4006381333931',
        );
        provider.activate('b');
      });
      await Future<void>.delayed(Duration.zero);
      expect(provider.activeProfileId, 'a');
      gated.gate.complete();
      await save;
      await switched;
      await bloc.close();

      expect(movedBeforeSwitch, isTrue);
      expect(provider.activeProfileId, 'b');
      for (final id in ['a', 'b']) {
        final box = favourites[id]!;
        expect(box.keys, ['custom:4006381333931'], reason: id);
        expect(box.get('custom:4006381333931')!.addedAt, starredAt);
        expect(
          box.get('custom:4006381333931')!.meal.nutriments.energyKcal100,
          180,
        );
      }
      expect(favourites['c']!.isEmpty, isTrue);
    },
  );

  group('an edit that takes over another meal\'s barcode (#1403)', () {
    test('the edited meal replaces its entry and its favourite follows; the '
        'dropped meal\'s favourite resolves to the edited one', () async {
      final library = CustomMealDataSource(provider);
      // P has no barcode; X already has the one the edit gives P.
      final p = _meal('p', name: 'Porridge');
      final x = _meal('4006381333931', name: 'Muesli', kcal: 90);
      await library.saveCustomMeal(MealDBO.fromMealEntity(p));
      await library.saveCustomMeal(MealDBO.fromMealEntity(x));
      final earlier = starredAt.subtract(const Duration(days: 1));
      // A stars both, X first; B stars only X; C only P.
      await favourites['a']!.put('custom:p', _favourite(p, starredAt));
      await favourites['a']!.put(
        'custom:4006381333931',
        _favourite(x, earlier),
      );
      await favourites['b']!.put(
        'custom:4006381333931',
        _favourite(x, starredAt),
      );
      await favourites['c']!.put('custom:p', _favourite(p, starredAt));
      final bloc = EditMealBloc(
        _FakeGetConfigUsecase(),
        library,
        _FakeConfigRepository(),
        repository,
        _NoIntakesRepository(),
      );
      addTearDown(bloc.close);

      final edited = _meal('4006381333931', name: 'Porridge', kcal: 180);
      await bloc.saveCustomMeal(edited, previous: p);

      // One library entry, the edited meal, in P's place.
      expect(customMealBox.values.map((m) => (m.code, m.name)), [
        ('4006381333931', 'Porridge'),
      ]);
      for (final id in ['a', 'b', 'c']) {
        expect(favourites[id]!.keys, ['custom:4006381333931'], reason: id);
      }
      expect(favourites['a']!.get('custom:4006381333931')!.addedAt, earlier);
      expect(
        favourites['c']!.get('custom:4006381333931')!.meal.name,
        'Porridge',
      );
      // B starred the meal that was dropped; its star now shows the meal
      // that holds the barcode.
      provider.activate('b');
      final shown = await repository.getAllFavourites();
      expect(shown.single.name, 'Porridge');
      expect(shown.single.nutriments.energyKcal100, 180);
    });
  });

  group('a star tapped just before a profile switch', () {
    test('lands on the profile it was tapped on', () async {
      final meal = _meal('t1');
      final toggle = ToggleFavouriteMealUsecase(repository);

      // The tap is stamped on A; the switch to B is already holding the
      // lock, so the toggle queues behind it.
      final tappedOn = ProfileStamp.now();
      final release = Completer<void>();
      final switched = withProfileSwitchLock(() async {
        await release.future;
        provider.activate('b');
      });
      final toggled = toggle.toggle(meal, startedOn: tappedOn);
      await Future<void>.delayed(Duration.zero);
      release.complete();
      await switched;

      // Read on A and written on B, it would have starred the meal for the
      // wrong person. It is dropped instead.
      expect(await toggled, isNull);
      for (final id in ['a', 'b', 'c']) {
        expect(favourites[id]!.isEmpty, isTrue, reason: id);
      }
    });

    test('a toggle started before the switch finishes first', () async {
      final meal = _meal('t2');
      final toggle = ToggleFavouriteMealUsecase(repository);

      final toggled = toggle.toggle(meal);
      final switched = withProfileSwitchLock(
        () async => provider.activate('b'),
      );

      expect(await toggled, isTrue);
      await switched;
      expect(favourites['a']!.keys, ['custom:t2']);
      expect(favourites['b']!.isEmpty, isTrue);
    });
  });
}
