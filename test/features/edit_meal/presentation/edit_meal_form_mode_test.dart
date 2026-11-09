import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:opennutritracker/core/data/data_source/custom_meal_data_source.dart';
import 'package:opennutritracker/core/data/dbo/meal_dbo.dart';
import 'package:opennutritracker/core/data/repository/config_repository.dart';
import 'package:opennutritracker/core/data/repository/favourite_meal_repository.dart';
import 'package:opennutritracker/core/data/repository/intake_repository.dart';
import 'package:opennutritracker/core/domain/entity/app_theme_entity.dart';
import 'package:opennutritracker/core/domain/entity/config_entity.dart';
import 'package:opennutritracker/core/domain/entity/intake_type_entity.dart';
import 'package:opennutritracker/core/domain/usecase/get_config_usecase.dart';
import 'package:opennutritracker/core/utils/energy_unit_provider.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_nutriments_entity.dart';
import 'package:opennutritracker/features/edit_meal/presentation/bloc/edit_meal_bloc.dart';
import 'package:opennutritracker/features/edit_meal/presentation/edit_meal_screen.dart';
import 'package:opennutritracker/features/edit_meal/util/simple_form.dart';
import 'package:opennutritracker/generated/l10n.dart';
import 'package:provider/provider.dart';

/// The simple form saves every food with a base amount and a serving of
/// 100 in g/ml. The editor opens a food that form would change in the
/// advanced form, whatever form the user last chose.
void main() {
  final getIt = GetIt.instance;

  setUp(() {
    // A food that is not custom shows its remote image.
    getIt.registerLazySingleton<CacheManager>(_FakeCacheManager.new);
    getIt.registerFactory<EditMealBloc>(
      () => EditMealBloc(
        _FakeGetConfigUsecase(),
        _FakeCustomMealDataSource(),
        _FakeConfigRepository(),
        _FakeFavouriteMealRepository(),
        _FakeIntakeRepository(),
      ),
    );
  });

  tearDown(() async {
    await getIt.reset();
  });

  MealEntity meal({
    required MealSourceEntity source,
    String? mealQuantity = '100',
    String? mealUnit = 'gml',
    double? servingQuantity = 100,
  }) => MealEntity(
    code: 'oats',
    name: 'Oats',
    url: null,
    mealQuantity: mealQuantity,
    mealUnit: mealUnit,
    servingQuantity: servingQuantity,
    servingUnit: 'g',
    servingSize: '',
    nutriments: const MealNutrimentsEntity(
      energyKcal100: 370,
      carbohydrates100: 60,
      fat100: 7,
      proteins100: 13,
      sugars100: null,
      saturatedFat100: null,
      fiber100: null,
    ),
    source: source,
  );

  Future<void> pumpEditor(WidgetTester tester, MealEntity meal) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ChangeNotifierProvider<EnergyUnitProvider>(
        create: (_) => EnergyUnitProvider(),
        child: MaterialApp(
          localizationsDelegates: const [S.delegate],
          supportedLocales: S.supportedLocales,
          home: Builder(
            builder: (context) => Navigator(
              onGenerateRoute: (_) => MaterialPageRoute<void>(
                settings: RouteSettings(
                  arguments: EditMealScreenArguments(
                    DateTime(2026, 10, 18),
                    meal,
                    IntakeTypeEntity.breakfast,
                    false,
                    editOnly: true,
                  ),
                ),
                builder: (_) => const EditMealScreen(),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// The unit selector heads the advanced form's fields; the simple form
  /// has none.
  final advancedForm = find.byWidgetPredicate(
    (widget) =>
        widget is Semantics &&
        widget.properties.identifier == 'edit-meal-unit-selector',
  );

  group('the editor, with the simple form last chosen', () {
    testWidgets('opens a custom food of 100 g in the simple form', (
      tester,
    ) async {
      await pumpEditor(tester, meal(source: MealSourceEntity.custom));

      expect(advancedForm, findsNothing);
    });

    testWidgets('opens a custom food with a 30 g serving in the advanced '
        'form', (tester) async {
      await pumpEditor(
        tester,
        meal(source: MealSourceEntity.custom, servingQuantity: 30),
      );

      expect(advancedForm, findsOneWidget);
    });

    testWidgets('opens a food that is not custom in the advanced form', (
      tester,
    ) async {
      await pumpEditor(tester, meal(source: MealSourceEntity.off));

      expect(advancedForm, findsOneWidget);
    });
  });

  group('simpleFormKeeps', () {
    test('holds a food of 100 g/ml with a serving of 100 or none', () {
      final custom = MealSourceEntity.custom;
      expect(simpleFormKeeps(meal(source: custom)), isTrue);
      expect(
        simpleFormKeeps(meal(source: custom, servingQuantity: null)),
        isTrue,
      );
      expect(
        simpleFormKeeps(
          meal(source: custom, mealQuantity: null, mealUnit: null),
        ),
        isTrue,
      );
      expect(simpleFormKeeps(meal(source: custom, mealUnit: 'g/ml')), isTrue);
    });

    test('does not hold any other serving, amount or unit', () {
      final custom = MealSourceEntity.custom;
      expect(
        simpleFormKeeps(meal(source: custom, servingQuantity: 30)),
        isFalse,
      );
      expect(
        simpleFormKeeps(meal(source: custom, mealQuantity: '250')),
        isFalse,
      );
      expect(simpleFormKeeps(meal(source: custom, mealUnit: 'g')), isFalse);
      expect(simpleFormKeeps(meal(source: custom, mealUnit: 'ml')), isFalse);
    });
  });
}

/// Nothing is saved: the tests only open the editor.
class _FakeCustomMealDataSource implements CustomMealDataSource {
  @override
  List<MealDBO> getAllCustomMeals() => const [];

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('Unexpected call: ${invocation.memberName}');
}

class _FakeIntakeRepository implements IntakeRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('Unexpected call: ${invocation.memberName}');
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

/// #1307 moves a favourite along with the edit; nothing is starred here.
class _FakeFavouriteMealRepository implements FavouriteMealRepository {
  @override
  Future<void> moveFavourite(MealEntity previous, MealEntity updated) async {}

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
