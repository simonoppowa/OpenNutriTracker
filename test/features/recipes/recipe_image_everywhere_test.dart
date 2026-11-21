import 'dart:convert';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:opennutritracker/core/data/dbo/intake_dbo.dart';
import 'package:opennutritracker/core/data/dbo/intake_type_dbo.dart';
import 'package:opennutritracker/core/data/dbo/meal_dbo.dart';
import 'package:opennutritracker/core/domain/entity/intake_entity.dart';
import 'package:opennutritracker/core/domain/entity/intake_type_entity.dart';
import 'package:opennutritracker/core/domain/entity/recipe_entity.dart';
import 'package:opennutritracker/core/presentation/widgets/intake_card.dart';
import 'package:opennutritracker/core/presentation/widgets/user_image.dart';
import 'package:opennutritracker/core/utils/energy_unit_provider.dart';
import 'package:opennutritracker/core/utils/user_image_storage.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_nutriments_entity.dart';
import 'package:opennutritracker/features/add_meal/presentation/add_meal_type.dart';
import 'package:opennutritracker/features/add_meal/presentation/bloc/favourite_toggle_bloc.dart';
import 'package:opennutritracker/features/add_meal/presentation/widgets/meal_item_card.dart';
import 'package:opennutritracker/features/settings/domain/usecase/export_data_usecase.dart';
import 'package:opennutritracker/generated/l10n.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:provider/provider.dart';

import '../../helpers/fake_favourites.dart';

// #675: a recipe's photo showed in the Recipes list only. The add-food
// search row, the meal detail screen and the Home/Diary entry card all
// showed a placeholder, because `RecipeEntity.toMealEntity()` dropped the
// photo and the search row only knew about remote (Open Food Facts) URLs.

/// A 1x1 PNG, so a decode that does run has real bytes to read.
final _png = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==',
);

const _slug = 'recipe_images/r1.webp';

class _FakePathProvider extends PathProviderPlatform
    with MockPlatformInterfaceMixin {
  _FakePathProvider(this.documentsPath);

  final String documentsPath;

  @override
  Future<String?> getApplicationDocumentsPath() async => documentsPath;
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

RecipeEntity _recipe({String? imagePath = _slug}) => RecipeEntity(
  id: 'r1',
  name: 'Lentil soup',
  description: null,
  ingredients: const [],
  totalWeightG: 800,
  aggregatedNutrimentsPer100: MealNutrimentsEntity.empty(),
  createdAt: DateTime(2026, 11, 1),
  updatedAt: DateTime(2026, 11, 1),
  servingsCount: 4,
  imagePath: imagePath,
);

MealEntity _offMeal() => MealEntity(
  code: '4000000000000',
  name: 'Skyr',
  url: null,
  thumbnailImageUrl: 'https://images.openfoodfacts.org/skyr_thumb.jpg',
  mainImageUrl: 'https://images.openfoodfacts.org/skyr.jpg',
  mealQuantity: '450',
  mealUnit: 'g',
  servingQuantity: null,
  servingUnit: null,
  servingSize: null,
  nutriments: MealNutrimentsEntity.empty(),
  source: MealSourceEntity.off,
);

/// A recipe meal as an intake snapshot stores it, with [localImagePath] as
/// given. Null is what an entry logged before #675 holds.
MealEntity _loggedRecipeMeal(String? localImagePath) => MealEntity(
  code: 'r1',
  name: 'Lentil soup',
  url: null,
  mealQuantity: '800.0',
  mealUnit: 'g',
  servingQuantity: 200,
  servingUnit: 'g',
  servingSize: '1 serving (200 g)',
  nutriments: MealNutrimentsEntity.empty(),
  source: MealSourceEntity.recipe,
  localImagePath: localImagePath,
);

IntakeEntity _intake(MealEntity meal) => IntakeEntity(
  id: 'i1',
  unit: 'g',
  amount: 200,
  type: IntakeTypeEntity.lunch,
  dateTime: DateTime(2026, 11, 9, 12),
  meal: meal,
);

Finder _fileImageAt(String path) => find.byWidgetPredicate(
  (w) =>
      w is Image &&
      w.image is FileImage &&
      (w.image as FileImage).file.path == path,
  description: 'Image.file($path)',
);

final Finder _anyFileImage = find.byWidgetPredicate(
  (w) => w is Image && w.image is FileImage,
  description: 'any Image.file',
);

Finder _networkImage(String url) => find.byWidgetPredicate(
  (w) => w is CachedNetworkImage && w.imageUrl == url,
  description: 'CachedNetworkImage($url)',
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory documents;
  late String photoPath;

  setUp(() async {
    documents = await Directory.systemTemp.createTemp('ont_675_');
    PathProviderPlatform.instance = _FakePathProvider(documents.path);
    photoPath = '${documents.path}/$_slug';
  });

  tearDown(() async {
    if (await documents.exists()) await documents.delete(recursive: true);
  });

  void writePhoto() {
    File(photoPath)
      ..createSync(recursive: true)
      ..writeAsBytesSync(_png);
  }

  group('RecipeEntity.toMealEntity', () {
    test(
      'carries the recipe photo to the meal it is searched and logged as',
      () {
        expect(_recipe().toMealEntity().localImagePath, _slug);
      },
    );

    test('a recipe with no photo gives a meal with no photo', () {
      expect(_recipe(imagePath: null).toMealEntity().localImagePath, isNull);
    });

    test('the photo survives the intake snapshot (MealDBO round trip)', () {
      final stored = MealDBO.fromMealEntity(_recipe().toMealEntity());
      expect(MealEntity.fromMealDBO(stored).localImagePath, _slug);
    });
  });

  group('UserImageStorage.normalizeStored', () {
    test('keeps a canonical relative slug', () {
      expect(UserImageStorage.normalizeStored(_slug), _slug);
    });

    test(
      'takes the slug out of an absolute path from an old iOS container',
      () {
        expect(
          UserImageStorage.normalizeStored(
            '/var/mobile/Containers/Data/Application/'
            'OLD-UUID/Documents/recipe_images/r1.webp',
          ),
          _slug,
        );
      },
    );

    test('rejects values that are not a user-image slug', () {
      expect(UserImageStorage.normalizeStored(''), isNull);
      expect(UserImageStorage.normalizeStored('/etc/passwd'), isNull);
      expect(UserImageStorage.normalizeStored('r1.webp'), isNull);
      expect(
        UserImageStorage.normalizeStored('recipe_images/../x.webp'),
        isNull,
      );
      expect(
        UserImageStorage.normalizeStored('/var/x/recipe_images/../r1.webp'),
        isNull,
      );
    });
  });

  group('UserImageStorage.existingFile', () {
    test(
      'resolves a stored slug against the current documents directory',
      () async {
        writePhoto();
        final file = await UserImageStorage.existingFile(_slug);
        expect(file?.path, photoPath);
      },
    );

    test('is null when the photo was deleted', () async {
      expect(await UserImageStorage.existingFile(_slug), isNull);
    });

    test('is null for no stored value', () async {
      expect(await UserImageStorage.existingFile(null), isNull);
    });

    test('a stale absolute path resolves into the current container', () async {
      writePhoto();
      final file = await UserImageStorage.existingFile(
        '/var/mobile/Containers/Data/Application/OLD-UUID/Documents/$_slug',
      );
      expect(file?.path, photoPath);
    });

    test(
      'is null, not a throw, when the documents directory is unavailable',
      () async {
        PathProviderPlatform.instance = _ThrowingPathProvider();
        expect(await UserImageStorage.existingFile(_slug), isNull);
      },
    );
  });

  group('export', () {
    test('a logged recipe and its recipe export its photo once', () {
      final recipe = _recipe();
      final paths = ExportDataUsecase.userImagePaths(
        recipes: [recipe.toDBO()],
        customMeals: const [],
        intakes: [
          IntakeDBO(
            id: 'i1',
            unit: 'g',
            amount: 200,
            type: IntakeTypeDBO.lunch,
            meal: MealDBO.fromMealEntity(recipe.toMealEntity()),
            dateTime: DateTime(2026, 11, 9),
          ),
        ],
      );
      expect(paths, [_slug]);
    });
  });

  group('UserImage', () {
    Future<void> pump(WidgetTester tester, String stored) async {
      await tester.pumpWidget(
        MaterialApp(
          home: UserImage(
            storedPath: stored,
            width: 40,
            height: 40,
            fallback: const Icon(Icons.restaurant_rounded),
          ),
        ),
      );
      await tester.pump();
    }

    testWidgets('shows the photo when the file exists', (tester) async {
      writePhoto();
      await pump(tester, _slug);
      expect(_fileImageAt(photoPath), findsOneWidget);
      expect(find.byIcon(Icons.restaurant_rounded), findsNothing);
    });

    testWidgets('falls back when the file is gone', (tester) async {
      await pump(tester, _slug);
      expect(tester.takeException(), isNull);
      expect(_anyFileImage, findsNothing);
      expect(find.byIcon(Icons.restaurant_rounded), findsOneWidget);
    });

    testWidgets('falls back when the bytes do not decode', (tester) async {
      File(photoPath)
        ..createSync(recursive: true)
        ..writeAsStringSync('not an image');
      // The file read and decode are real I/O, which only finishes outside
      // the test's fake clock.
      await tester.runAsync(() async {
        await pump(tester, _slug);
        await Future<void>.delayed(const Duration(milliseconds: 500));
      });
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(find.byIcon(Icons.restaurant_rounded), findsOneWidget);
    });
  });

  group('add-food search row', () {
    final getIt = GetIt.instance;
    late FakeFavourites favourites;

    setUp(() {
      favourites = FakeFavourites();
      getIt.registerFactory<FavouriteToggleBloc>(
        () => FavouriteToggleBloc(favourites.get, favourites.toggle),
      );
      getIt.registerLazySingleton<CacheManager>(_FakeCacheManager.new);
    });

    tearDown(() async {
      await getIt.reset();
      await favourites.dispose();
    });

    Future<void> pumpRow(WidgetTester tester, MealEntity meal) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            S.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: S.supportedLocales,
          home: Scaffold(
            body: MealItemCard(
              day: DateTime(2026, 11, 9),
              mealEntity: meal,
              addMealType: AddMealType.lunchType,
              usesImperialUnits: false,
            ),
          ),
        ),
      );
      await tester.pump();
    }

    testWidgets('a recipe with a photo shows the photo', (tester) async {
      writePhoto();
      await pumpRow(tester, _recipe().toMealEntity());
      expect(_fileImageAt(photoPath), findsOneWidget);
      expect(find.byIcon(Icons.menu_book_rounded), findsNothing);
    });

    testWidgets('a recipe without a photo keeps the recipe placeholder', (
      tester,
    ) async {
      await pumpRow(tester, _recipe(imagePath: null).toMealEntity());
      expect(_anyFileImage, findsNothing);
      expect(find.byIcon(Icons.menu_book_rounded), findsOneWidget);
    });

    testWidgets('a recipe whose photo was deleted keeps the placeholder', (
      tester,
    ) async {
      await pumpRow(tester, _recipe().toMealEntity());
      expect(tester.takeException(), isNull);
      expect(_anyFileImage, findsNothing);
      expect(find.byIcon(Icons.menu_book_rounded), findsOneWidget);
    });

    testWidgets('an Open Food Facts product still shows its remote thumbnail', (
      tester,
    ) async {
      await pumpRow(tester, _offMeal());
      expect(_networkImage(_offMeal().thumbnailImageUrl!), findsOneWidget);
      expect(_anyFileImage, findsNothing);
    });
  });

  group('Home and Diary entry card', () {
    setUp(() {
      GetIt.instance.registerLazySingleton<CacheManager>(_FakeCacheManager.new);
    });

    tearDown(() async {
      await GetIt.instance.reset();
    });

    Future<void> pumpCard(WidgetTester tester, MealEntity meal) async {
      await tester.pumpWidget(
        ChangeNotifierProvider<EnergyUnitProvider>(
          create: (_) => EnergyUnitProvider(),
          child: MaterialApp(
            localizationsDelegates: const [
              S.delegate,
              ...GlobalMaterialLocalizations.delegates,
            ],
            supportedLocales: S.supportedLocales,
            home: Scaffold(
              body: SizedBox(
                width: 360,
                child: IntakeCard(
                  key: const ValueKey('card'),
                  intake: _intake(meal),
                  firstListElement: false,
                  usesImperialUnits: false,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
    }

    testWidgets('a logged recipe shows its photo', (tester) async {
      writePhoto();
      await pumpCard(tester, _recipe().toMealEntity());
      expect(_fileImageAt(photoPath), findsOneWidget);
      expect(find.byIcon(Icons.restaurant_rounded), findsNothing);
    });

    testWidgets('a photo deleted after logging falls back to the placeholder', (
      tester,
    ) async {
      writePhoto();
      final meal = _recipe().toMealEntity();
      File(photoPath).deleteSync();
      await pumpCard(tester, meal);
      expect(tester.takeException(), isNull);
      expect(_anyFileImage, findsNothing);
      expect(find.byIcon(Icons.restaurant_rounded), findsOneWidget);
    });

    testWidgets(
      'a stale absolute path from an old container still shows the photo',
      (tester) async {
        writePhoto();
        await pumpCard(
          tester,
          _loggedRecipeMeal(
            '/var/mobile/Containers/Data/Application/OLD-UUID/Documents/$_slug',
          ),
        );
        expect(_fileImageAt(photoPath), findsOneWidget);
      },
    );

    testWidgets('an entry logged before the fix keeps the placeholder', (
      tester,
    ) async {
      writePhoto();
      await pumpCard(tester, _loggedRecipeMeal(null));
      expect(tester.takeException(), isNull);
      expect(_anyFileImage, findsNothing);
      expect(find.byIcon(Icons.restaurant_rounded), findsOneWidget);
    });

    testWidgets('an Open Food Facts entry still shows its remote image', (
      tester,
    ) async {
      await pumpCard(tester, _offMeal());
      expect(_networkImage(_offMeal().mainImageUrl!), findsOneWidget);
      expect(_anyFileImage, findsNothing);
    });
  });
}

class _ThrowingPathProvider extends PathProviderPlatform
    with MockPlatformInterfaceMixin {
  @override
  Future<String?> getApplicationDocumentsPath() async =>
      throw Exception('no documents directory');
}
