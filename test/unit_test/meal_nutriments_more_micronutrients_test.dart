import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:opennutritracker/core/data/dbo/intake_dbo.dart';
import 'package:opennutritracker/core/data/dbo/intake_type_dbo.dart';
import 'package:opennutritracker/core/data/dbo/meal_dbo.dart';
import 'package:opennutritracker/core/data/dbo/meal_nutriments_dbo.dart';
import 'package:opennutritracker/core/data/data_source/custom_meal_data_source.dart';
import 'package:opennutritracker/core/data/repository/config_repository.dart';
import 'package:opennutritracker/core/domain/entity/recipe_ingredient_entity.dart';
import 'package:opennutritracker/core/domain/usecase/compute_recipe_nutrition_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_config_usecase.dart';
import 'package:opennutritracker/core/utils/csv_data_exporter.dart';
import 'package:opennutritracker/features/add_meal/data/data_sources/local_bls_catalog.dart';
import 'package:opennutritracker/features/add_meal/data/data_sources/local_bls_food_data_source.dart';
import 'package:opennutritracker/features/add_meal/data/dto/off/off_product_nutriments_dto.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_nutriments_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/nutrients/nutrient_field.dart';
import 'package:opennutritracker/features/edit_meal/presentation/bloc/edit_meal_bloc.dart';

import '../helpers/hive_test_setup.dart';

const _newFields = [
  NutrientField.vitaminE,
  NutrientField.vitaminK,
  NutrientField.thiamin,
  NutrientField.riboflavin,
  NutrientField.pantothenicAcid,
  NutrientField.biotin,
  NutrientField.folate,
  NutrientField.iodine,
  NutrientField.selenium,
  NutrientField.copper,
  NutrientField.manganese,
];

MealNutrimentsEntity _withNewFields(double value) => NutrientField.entityFrom({
  NutrientField.energyKcal: 100,
  for (final field in _newFields) field: value,
});

/// Writes a [MealNutrimentsDBO] the way the app did before #50: the 24
/// upstream fields only.
class _LegacyAdapter extends TypeAdapter<MealNutrimentsDBO> {
  @override
  final typeId = 3;

  @override
  MealNutrimentsDBO read(BinaryReader reader) => throw UnimplementedError();

  @override
  void write(BinaryWriter writer, MealNutrimentsDBO obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.energyKcal100)
      ..writeByte(23)
      ..write(obj.niacin100);
  }
}

class _Unused
    implements GetConfigUsecase, CustomMealDataSource, ConfigRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('Open Food Facts', () {
    test('every new nutrient is read and converted from grams', () {
      final dto = OFFProductNutrimentsDTO.fromJson({
        'energy-kcal_100g': 100,
        'vitamin-e_100g': 0.012,
        'vitamin-k_100g': 0.00008,
        'vitamin-b1_100g': '0.0011',
        'vitamin-b2_100g': 0.0014,
        'pantothenic-acid_100g': 0.005,
        'biotin_100g': 0.00003,
        'vitamin-b9_100g': 0.0002,
        'iodine_100g': 0.00015,
        'selenium_100g': 0.00006,
        'copper_100g': 0.0009,
        'manganese_100g': 0.002,
      });

      final n = MealNutrimentsEntity.fromOffNutriments(dto);

      expect(n.vitaminE100, closeTo(12, 1e-9));
      expect(n.vitaminK100, closeTo(80, 1e-9));
      expect(n.thiamin100, closeTo(1.1, 1e-9));
      expect(n.riboflavin100, closeTo(1.4, 1e-9));
      expect(n.pantothenicAcid100, closeTo(5, 1e-9));
      expect(n.biotin100, closeTo(30, 1e-9));
      expect(n.folate100, closeTo(200, 1e-9));
      expect(n.iodine100, closeTo(150, 1e-9));
      expect(n.selenium100, closeTo(60, 1e-9));
      expect(n.copper100, closeTo(0.9, 1e-9));
      expect(n.manganese100, closeTo(2, 1e-9));
      expect(n.hasMicronutrientData, isTrue);
    });

    test('folate falls back to folates_100g', () {
      final dto = OFFProductNutrimentsDTO.fromJson({
        'energy-kcal_100g': 100,
        'folates_100g': 0.0001,
      });

      expect(
        MealNutrimentsEntity.fromOffNutriments(dto).folate100,
        closeTo(100, 1e-9),
      );
    });

    test('folate falls back to folates_100g when vitamin-b9 is no number', () {
      final dto = OFFProductNutrimentsDTO.fromJson({
        'energy-kcal_100g': 100,
        'vitamin-b9_100g': 'n/a',
        'folates_100g': 0.0001,
      });

      expect(
        MealNutrimentsEntity.fromOffNutriments(dto).folate100,
        closeTo(100, 1e-9),
      );
    });

    test('a product without them reads as unknown', () {
      final n = MealNutrimentsEntity.fromOffNutriments(
        OFFProductNutrimentsDTO.fromJson({'energy-kcal_100g': 100}),
      );

      for (final field in _newFields) {
        expect(field.per100(n), isNull, reason: field.name);
      }
    });
  });

  group('storage', () {
    setUpAll(() {
      TestWidgetsFlutterBinding.ensureInitialized();
      registerHiveAdaptersOnce();
    });

    setUp(() => Hive.init(Directory.systemTemp.createTempSync().path));

    tearDown(() async {
      Hive.registerAdapter(MealNutrimentsDBOAdapter(), override: true);
      await Hive.deleteFromDisk();
    });

    test(
      'a record from before #50 reads with the new fields unknown',
      () async {
        Hive.registerAdapter(_LegacyAdapter(), override: true);
        var box = await Hive.openBox<MealNutrimentsDBO>('legacy_nutriments');
        await box.put(
          'a',
          MealNutrimentsDBO.fromProductNutrimentsEntity(_withNewFields(5)),
        );
        await box.close();
        Hive.registerAdapter(MealNutrimentsDBOAdapter(), override: true);
        box = await Hive.openBox<MealNutrimentsDBO>('legacy_nutriments');

        final read = MealNutrimentsEntity.fromMealNutrimentsDBO(box.get('a')!);

        expect(read.energyKcal100, 100);
        for (final field in _newFields) {
          expect(field.per100(read), isNull, reason: field.name);
        }
        await box.close();
      },
    );

    test('the new fields are stored and read back', () async {
      var box = await Hive.openBox<MealNutrimentsDBO>('nutriments');
      await box.put(
        'a',
        MealNutrimentsDBO.fromProductNutrimentsEntity(_withNewFields(7)),
      );
      await box.close();
      box = await Hive.openBox<MealNutrimentsDBO>('nutriments');

      final read = MealNutrimentsEntity.fromMealNutrimentsDBO(box.get('a')!);

      for (final field in _newFields) {
        expect(field.per100(read), 7, reason: field.name);
      }
      await box.close();
    });

    test('the JSON of the backup keeps them, an old backup reads null', () {
      final dbo = MealNutrimentsDBO.fromProductNutrimentsEntity(
        _withNewFields(3),
      );
      final restored = MealNutrimentsEntity.fromMealNutrimentsDBO(
        MealNutrimentsDBO.fromJson(dbo.toJson()),
      );
      final json = dbo.toJson()
        ..removeWhere((key, _) => key == 'vitaminE100' || key == 'iodine100');
      final old = MealNutrimentsDBO.fromJson(json);

      for (final field in _newFields) {
        expect(field.per100(restored), 3, reason: field.name);
      }
      expect(old.vitaminE100, isNull);
      expect(old.iodine100, isNull);
      expect(old.selenium100, 3);
    });

    test('the CSV export keeps them', () {
      final intake = IntakeDBO(
        id: 'i',
        unit: 'g',
        amount: 100,
        type: IntakeTypeDBO.snack,
        meal: MealDBO(
          code: 'c',
          name: 'n',
          brands: null,
          thumbnailImageUrl: null,
          mainImageUrl: null,
          url: null,
          mealQuantity: null,
          mealUnit: 'g',
          servingQuantity: null,
          servingUnit: 'g',
          servingSize: null,
          source: MealSourceDBO.custom,
          nutriments: MealNutrimentsDBO.fromProductNutrimentsEntity(
            _withNewFields(4.5),
          ),
        ),
        dateTime: DateTime.utc(2026, 10, 19),
      );

      final csv = CsvDataExporter.intakesToCsv([intake]);
      final parsed = CsvDataExporter.parseIntakesFromCsv(csv).single;
      final n = MealNutrimentsEntity.fromMealNutrimentsDBO(
        parsed.meal.nutriments,
      );

      expect(CsvDataExporter.intakeColumns.last, 'meal_data_version');
      for (final field in _newFields) {
        expect(field.per100(n), 4.5, reason: field.name);
      }
    });
  });

  test('recipes aggregate them', () {
    MealEntity meal(String code, double value) => MealEntity(
      code: code,
      name: code,
      url: null,
      mealQuantity: null,
      mealUnit: 'g',
      servingQuantity: null,
      servingUnit: null,
      servingSize: null,
      nutriments: _withNewFields(value),
      source: MealSourceEntity.custom,
    );

    final result = ComputeRecipeNutritionUseCase().compute([
      RecipeIngredientEntity(
        snapshotMeal: meal('a', 10),
        amount: 100,
        unit: 'g',
        convertedAmountG: 100,
      ),
      RecipeIngredientEntity(
        snapshotMeal: meal('b', 30),
        amount: 100,
        unit: 'g',
        convertedAmountG: 100,
      ),
    ]);

    for (final field in _newFields) {
      expect(
        field.per100(result.perHundredG),
        closeTo(20, 1e-9),
        reason: field.name,
      );
    }
  });

  test('the local BLS fills every new nutrient but selenium', () async {
    final catalog = LocalBlsCatalog.decode(
      File('assets/bls/bls_4_0.json.gz').readAsBytesSync(),
    );
    final source = LocalBlsFoodDataSource(
      loadCatalog: () async => catalog,
      isEnabled: () async => true,
      localeName: () => 'de_DE',
    );

    final egg = (await source.fetchSearchWordResults('Hühnerei roh')).first;
    final n = MealNutrimentsEntity.fromSpFoodSummary(egg);

    expect(n.vitaminE100, isNotNull);
    expect(n.vitaminK100, isNotNull);
    expect(n.thiamin100, isNotNull);
    expect(n.riboflavin100, isNotNull);
    expect(n.pantothenicAcid100, isNotNull);
    expect(n.biotin100, isNotNull);
    expect(n.folate100, isNotNull);
    expect(n.iodine100, isNotNull);
    expect(n.copper100, isNotNull);
    expect(n.manganese100, isNotNull);
    expect(n.selenium100, isNull);
  });

  test('editing a meal keeps the nutrients the form does not show', () async {
    final bloc = EditMealBloc(_Unused(), _Unused(), _Unused());
    addTearDown(bloc.close);
    final old = MealEntity.empty();
    final meal = MealEntity(
      code: old.code,
      name: 'Skyr',
      url: null,
      mealQuantity: '100',
      mealUnit: 'g',
      servingQuantity: null,
      servingUnit: 'g',
      servingSize: null,
      nutriments: NutrientField.entityFrom({
        NutrientField.energyKcal: 60,
        NutrientField.zinc: 0.5,
        NutrientField.iodine: 20,
        NutrientField.vitaminE: 0.1,
      }),
      source: MealSourceEntity.custom,
    );

    final edited = bloc.createNewMealEntity(
      meal,
      'Skyr',
      '',
      '100',
      '',
      '100',
      'g',
      '62',
      '4',
      '0',
      '11',
    );

    expect(edited.nutriments.energyKcal100, 62);
    expect(edited.nutriments.zinc100, 0.5);
    expect(edited.nutriments.iodine100, 20);
    expect(edited.nutriments.vitaminE100, 0.1);
  });
}
