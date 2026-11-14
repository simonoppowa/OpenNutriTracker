import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_ce/hive.dart';
import 'package:opennutritracker/core/data/data_source/custom_meal_data_source.dart';
import 'package:opennutritracker/core/data/data_source/intake_data_source.dart';
import 'package:opennutritracker/core/data/data_source/recipe_data_source.dart';
import 'package:opennutritracker/core/data/dbo/intake_dbo.dart';
import 'package:opennutritracker/core/data/dbo/meal_dbo.dart';
import 'package:opennutritracker/core/data/dbo/recipe_dbo.dart';
import 'package:opennutritracker/core/data/repository/intake_repository.dart';
import 'package:opennutritracker/core/domain/entity/intake_entity.dart';
import 'package:opennutritracker/core/domain/entity/intake_type_entity.dart';
import 'package:opennutritracker/core/presentation/widgets/intake_card.dart';
import 'package:opennutritracker/core/presentation/widgets/local_user_image.dart';
import 'package:opennutritracker/core/utils/energy_unit_provider.dart';
import 'package:opennutritracker/core/utils/user_image_storage.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_nutriments_entity.dart';
import 'package:opennutritracker/features/diary/presentation/widgets/diary_sort_type.dart';
import 'package:opennutritracker/generated/l10n.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:provider/provider.dart';

import '../../../../helpers/fake_hive_db_provider.dart';
import '../../../../helpers/hive_test_setup.dart';

MealEntity meal({
  String? photo,
  bool current = false,
  MealSourceEntity source = MealSourceEntity.custom,
}) => MealEntity(
  code: 'solid',
  name: current ? 'Renamed current food' : 'Historical solid',
  url: null,
  mealQuantity: '60',
  mealUnit: 'g',
  servingQuantity: current ? 28.3495 : 30,
  servingUnit: 'g',
  servingSize: null,
  source: source,
  localImagePath: photo,
  nutriments: MealNutrimentsEntity(
    energyKcal100: current ? 100 : 460,
    carbohydrates100: current ? 1 : 60,
    fat100: current ? 2 : 20,
    proteins100: current ? 3 : 10,
    sugars100: null,
    saturatedFat100: null,
    fiber100: null,
  ),
);

void main() {
  late Directory directory;
  late PathProviderPlatform originalPaths;
  late Box<MealDBO> meals;
  late Box<IntakeDBO> intakes;
  late CustomMealDataSource library;
  late IntakeRepository history;
  late FakeHiveDBProvider db;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('intake-photo-');
    originalPaths = PathProviderPlatform.instance;
    PathProviderPlatform.instance = _Paths(directory.path);
    Hive.init(directory.path);
    registerHiveAdaptersOnce();
    meals = await Hive.openBox<MealDBO>('meals');
    intakes = await Hive.openBox<IntakeDBO>('intakes');
    db = FakeHiveDBProvider(
      customMealBox: meals,
      intakeBox: intakes,
      recipeBox: await Hive.openBox<RecipeDBO>('recipes'),
    );
    library = CustomMealDataSource(db);
    history = IntakeRepository(IntakeDataSource(db));
    GetIt.I.registerSingleton<CustomMealDataSource>(library);
    GetIt.I.registerSingleton<RecipeDataSource>(RecipeDataSource(db));
  });
  tearDown(() async {
    await GetIt.I.reset();
    PathProviderPlatform.instance = originalPaths;
    await Hive.close();
    await directory.delete(recursive: true);
  });

  Future<String> importPhoto(String id, {bool black = false}) async {
    final source = File('${directory.path}/synthetic.png');
    await source.writeAsBytes(
      base64Decode(
        black
            ? 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR4nGNgYGD4DwABBAEAX+XDSwAAAABJRU5ErkJggg=='
            : 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAAC0lEQVR4nGP4DwQACfsD/fteaysAAAAASUVORK5CYII=',
      ),
    );
    return UserImageStorage.importFrom(
      kind: UserImageKind.meal,
      ownerId: id,
      sourcePath: source.path,
    );
  }

  Widget surface(IntakeEntity intake, {DiarySortType? sort}) =>
      ChangeNotifierProvider(
        create: (_) => EnergyUnitProvider(),
        child: MaterialApp(
          localizationsDelegates: const [S.delegate],
          supportedLocales: S.supportedLocales,
          home: Scaffold(
            body: IntakeCard(
              key: const ValueKey('existing-row'),
              intake: intake,
              firstListElement: false,
              usesImperialUnits: true,
              sortType: sort,
            ),
          ),
        ),
      );

  testWidgets('same-slug editor photo replacement refreshes decoded image', (
    tester,
  ) async {
    late String photo;
    await tester.runAsync(() async {
      photo = await importPhoto('same-slug');
      await library.saveCustomMeal(
        MealDBO.fromMealEntity(meal(photo: photo, current: true)),
      );
    });
    final logged = IntakeEntity(
      id: 'same-slug-log',
      unit: 'g',
      amount: 60,
      type: IntakeTypeEntity.breakfast,
      meal: meal(),
      dateTime: DateTime(2026, 11, 1),
    );
    await tester.runAsync(() async {
      await tester.pumpWidget(surface(logged));
    });
    await tester.pumpAndSettle();
    Future<void> decodeFrames() async {
      for (var i = 0; i < 10; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 20)),
        );
        await tester.pump();
      }
    }

    await decodeFrames();
    final oldImage = tester.widget<RawImage>(find.byType(RawImage)).image!;
    await tester.runAsync(() async {
      final before = await oldImage.toByteData();
      expect(before!.getUint8(0), 255);
      expect(await importPhoto('same-slug', black: true), photo);
      // The existing editor evicts the overwritten file before saving metadata.
      await FileImage(File(await UserImageStorage.absolutePath(photo))).evict();
      await library.saveCustomMeal(
        MealDBO.fromMealEntity(meal(photo: photo, current: true)),
      );
    });
    await tester.pumpAndSettle();
    await decodeFrames();
    final replacement = tester.widget<RawImage>(find.byType(RawImage)).image!;
    await tester.runAsync(() async {
      final after = await replacement.toByteData();
      expect(after!.getUint8(0), 0);
    });
    expect(find.text('276 kcal'), findsOneWidget);
  });

  testWidgets(
    'source collisions do not borrow a photo and deletion uses snapshot',
    (tester) async {
      late String snapshotPhoto;
      late String currentPhoto;
      await tester.runAsync(() async {
        snapshotPhoto = await importPhoto('snapshot');
        currentPhoto = await importPhoto('current');
        await library.saveCustomMeal(
          MealDBO.fromMealEntity(meal(photo: currentPhoto, current: true)),
        );
      });
      IntakeEntity entry(MealSourceEntity source) => IntakeEntity(
        id: 'collision',
        unit: 'g',
        amount: 60,
        type: IntakeTypeEntity.breakfast,
        meal: meal(photo: snapshotPhoto, source: source),
        dateTime: DateTime(2026, 11, 1),
      );
      await tester.pumpWidget(surface(entry(MealSourceEntity.off)));
      await tester.pumpAndSettle();
      expect(
        tester.widget<LocalUserImage>(find.byType(LocalUserImage)).relativePath,
        snapshotPhoto,
      );
      await tester.pumpWidget(surface(entry(MealSourceEntity.custom)));
      await tester.pumpAndSettle();
      expect(
        tester.widget<LocalUserImage>(find.byType(LocalUserImage)).relativePath,
        currentPhoto,
      );
      await tester.runAsync(() => library.deleteCustomMeal('solid'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<LocalUserImage>(find.byType(LocalUserImage)).relativePath,
        snapshotPhoto,
      );
      // A present library entry with no photo is a clear, not a missing reference.
      await tester.runAsync(
        () =>
            library.saveCustomMeal(MealDBO.fromMealEntity(meal(current: true))),
      );
      await tester.pumpAndSettle();
      expect(find.byType(LocalUserImage), findsNothing);
      expect(find.text('276 kcal'), findsOneWidget);
    },
  );

  testWidgets('recipe ID uses recipe photo, not colliding custom food', (
    tester,
  ) async {
    late String photo;
    await tester.runAsync(() async {
      photo = await importPhoto('recipe');
      await library.saveCustomMeal(
        MealDBO.fromMealEntity(meal(photo: photo, current: true)),
      );
    });
    final logged = IntakeEntity(
      id: 'recipe-log',
      unit: 'g',
      amount: 60,
      type: IntakeTypeEntity.dinner,
      meal: meal(source: MealSourceEntity.recipe),
      dateTime: DateTime(2026, 10, 31),
    );
    await tester.pumpWidget(surface(logged));
    await tester.pumpAndSettle();
    expect(find.byType(LocalUserImage), findsNothing);
    Future<void> save(String? path) => GetIt.I<RecipeDataSource>().saveRecipe(
      RecipeDBO(
        id: 'solid',
        name: 'Current recipe',
        description: null,
        ingredients: [],
        totalWeightG: 100,
        aggregatedNutrimentsPer100: meals.values.single.nutriments,
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
        servingsCount: 1,
        tags: [],
        imagePath: path,
      ),
    );
    await tester.runAsync(() => save(photo));
    await tester.pumpAndSettle();
    expect(
      tester.widget<LocalUserImage>(find.byType(LocalUserImage)).relativePath,
      photo,
    );
    expect(find.text('276 kcal'), findsOneWidget);
    await tester.runAsync(() => save(null));
    await tester.pumpAndSettle();
    expect(find.byType(LocalUserImage), findsNothing);
  });

  testWidgets('pending image cannot follow recycled item across profile/day', (
    tester,
  ) async {
    late String photo;
    await tester.runAsync(() async {
      photo = await importPhoto('pending');
    });
    final gate = Completer<String?>();
    (PathProviderPlatform.instance as _Paths).pending = gate.future;
    final old = IntakeEntity(
      id: 'same-row',
      unit: 'g',
      amount: 60,
      type: IntakeTypeEntity.breakfast,
      meal: meal(photo: photo),
      dateTime: DateTime(2026, 11, 1),
    );
    await tester.pumpWidget(surface(old));
    await tester.pump();
    expect(find.byType(LocalUserImage), findsOneWidget);
    db.activeProfileId = 'other-profile';
    final next = IntakeEntity(
      id: 'same-row',
      unit: 'g',
      amount: 10,
      type: IntakeTypeEntity.dinner,
      meal: meal(source: MealSourceEntity.off),
      dateTime: DateTime(2026, 11, 2),
    );
    await tester.pumpWidget(surface(next));
    gate.complete(directory.path);
    await tester.pumpAndSettle();
    expect(find.byType(LocalUserImage), findsNothing);
    expect(find.text('46 kcal'), findsOneWidget);
    await tester.runAsync(
      () => library.saveCustomMeal(
        MealDBO.fromMealEntity(meal(photo: photo, current: true)),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(LocalUserImage), findsNothing);
    expect(find.text('46 kcal'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final sort in [null, DiarySortType.carbs]) {
    testWidgets(
      'existing Home/Diary card follows library photos only sort=$sort',
      (tester) async {
        late IntakeEntity logged;
        await tester.runAsync(() async {
          await library.saveCustomMeal(
            MealDBO.fromMealEntity(meal(current: true)),
          );
          await history.addIntake(
            IntakeEntity(
              id: 'existing',
              unit: 'g',
              amount: 60,
              type: IntakeTypeEntity.breakfast,
              meal: meal(),
              dateTime: DateTime(2026, 11, 1),
            ),
          );
          logged = (await history.getIntakeById('existing'))!;
        });
        final key = intakes.keys.single;
        final before = intakes.values.single.toJson();
        await tester.pumpWidget(surface(logged, sort: sort));
        await tester.pumpAndSettle();
        expect(find.byIcon(Icons.restaurant_rounded), findsOneWidget);
        late String photo;
        await tester.runAsync(() async {
          photo = await importPhoto('first');
          await library.saveCustomMeal(
            MealDBO.fromMealEntity(meal(photo: photo, current: true)),
          );
        });
        await tester.pumpAndSettle();
        expect(find.byType(LocalUserImage), findsOneWidget);
        expect(
          find.byWidgetPredicate((w) => w is Image && w.image is FileImage),
          findsOneWidget,
        );
        expect(
          tester
              .widget<LocalUserImage>(find.byType(LocalUserImage))
              .relativePath,
          photo,
        );
        expect(find.text('276 kcal'), findsOneWidget);
        expect(find.text('Historical solid'), findsOneWidget);
        expect(find.textContaining('2.12'), findsOneWidget);
        if (sort != null) expect(find.text('36.0 g carbs'), findsOneWidget);
        await tester.runAsync(() async {
          photo = await importPhoto('replacement');
          await library.saveCustomMeal(
            MealDBO.fromMealEntity(meal(photo: photo, current: true)),
          );
        });
        await tester.pumpAndSettle();
        expect(
          tester
              .widget<LocalUserImage>(find.byType(LocalUserImage))
              .relativePath,
          photo,
        );
        await tester.runAsync(
          () => library.saveCustomMeal(
            MealDBO.fromMealEntity(meal(current: true)),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.byType(LocalUserImage), findsNothing);
        expect(find.byIcon(Icons.restaurant_rounded), findsOneWidget);
        await tester.runAsync(() => library.deleteCustomMeal('solid'));
        await tester.pumpAndSettle();
        expect(find.text('276 kcal'), findsOneWidget);
        expect(intakes.keys.single, key);
        expect(intakes.length, 1);
        expect(intakes.values.single.toJson(), before);
        expect(logged.totalCarbsGram, 36);
        expect(logged.totalFatsGram, 12);
        expect(logged.totalProteinsGram, 6);
        expect(logged.meal.servingQuantity, 30);
        await tester.pumpWidget(const SizedBox());
        await tester.runAsync(
          () => library.saveCustomMeal(
            MealDBO.fromMealEntity(meal(photo: photo, current: true)),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(surface(logged, sort: sort));
        await tester.pumpAndSettle();
        expect(
          tester
              .widget<LocalUserImage>(find.byType(LocalUserImage))
              .relativePath,
          photo,
        );
      },
    );
  }
}

class _Paths extends PathProviderPlatform with MockPlatformInterfaceMixin {
  _Paths(this.path);
  final String path;
  Future<String?>? pending;
  @override
  Future<String?> getApplicationDocumentsPath() async => pending ?? path;
}
