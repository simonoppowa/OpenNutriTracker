import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:opennutritracker/core/data/data_source/intake_data_source.dart';
import 'package:opennutritracker/core/data/data_source/recipe_data_source.dart';
import 'package:opennutritracker/core/data/dbo/intake_dbo.dart';
import 'package:opennutritracker/core/data/dbo/intake_type_dbo.dart';
import 'package:opennutritracker/core/data/dbo/meal_dbo.dart';
import 'package:opennutritracker/core/data/dbo/meal_nutriments_dbo.dart';
import 'package:opennutritracker/core/data/repository/intake_repository.dart';
import 'package:opennutritracker/core/data/repository/recipe_repository.dart';
import 'package:opennutritracker/core/domain/usecase/get_intake_usecase.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';

import '../helpers/fake_hive_db_provider.dart';
import '../helpers/hive_test_setup.dart';

// #1265: the meal-detail screen opens a food on the amount it was last
// logged with. The lookup behind it: the newest intake of the same food in
// the active profile, matched by source and code, never by name.

MealDBO _meal({
  required String? code,
  MealSourceDBO source = MealSourceDBO.off,
  String? name,
}) => MealDBO(
  code: code,
  name: name ?? code,
  brands: null,
  thumbnailImageUrl: null,
  mainImageUrl: null,
  url: null,
  mealQuantity: '100',
  mealUnit: 'g',
  servingQuantity: 30,
  servingUnit: 'g',
  servingSize: '30 g',
  nutriments: MealNutrimentsDBO(
    energyKcal100: 100,
    carbohydrates100: 10,
    fat100: 2,
    proteins100: 5,
    sugars100: null,
    saturatedFat100: null,
    fiber100: null,
  ),
  source: source,
);

IntakeDBO _intake(
  String id,
  MealDBO meal,
  DateTime at, {
  double amount = 100,
  String unit = 'g',
}) => IntakeDBO(
  id: id,
  unit: unit,
  amount: amount,
  type: IntakeTypeDBO.lunch,
  meal: meal,
  dateTime: at,
);

MealEntity _food(
  String? code, {
  MealSourceEntity source = MealSourceEntity.off,
  String? name,
  bool detailed = false,
}) => MealEntity(
  code: code,
  name: name ?? code,
  url: null,
  mealQuantity: '100',
  mealUnit: 'g',
  servingQuantity: null,
  servingUnit: null,
  servingSize: null,
  nutriments: MealEntity.empty().nutriments,
  source: source,
  detailed: detailed,
);

/// Profiles `a` and `b`, each with its own intake box, `a` active.
class _TwoProfiles extends FakeHiveDBProvider {
  _TwoProfiles(this.boxes) : super(activeProfileId: 'a');

  final Map<String, Box<IntakeDBO>> boxes;

  @override
  Box<IntakeDBO> get intakeBox => boxes[activeProfileId]!;
}

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    Hive.init('.');
    registerHiveAdaptersOnce();
  });

  late Box<IntakeDBO> boxA;
  late Box<IntakeDBO> boxB;
  late _TwoProfiles provider;
  late IntakeDataSource dataSource;
  late GetIntakeUsecase usecase;

  setUp(() async {
    final stamp = DateTime.now().microsecondsSinceEpoch;
    boxA = await Hive.openBox<IntakeDBO>('last_intake_a_$stamp');
    boxB = await Hive.openBox<IntakeDBO>('last_intake_b_$stamp');
    provider = _TwoProfiles({'a': boxA, 'b': boxB});
    dataSource = IntakeDataSource(provider);
    usecase = GetIntakeUsecase(
      IntakeRepository(dataSource),
      RecipeRepository(RecipeDataSource(provider)),
    );
  });

  tearDown(() async {
    await boxA.deleteFromDisk();
    await boxB.deleteFromDisk();
  });

  test('a food never logged has no last intake', () async {
    await boxA.add(
      _intake('other', _meal(code: 'other'), DateTime(2026, 1, 1)),
    );

    expect(await usecase.getLastIntakeOfMeal(_food('cereal')), isNull);
  });

  test(
    'of two entries the newest wins, whatever order they were added in',
    () async {
      final cereal = _meal(code: 'cereal');
      await boxA.addAll([
        _intake('newer', cereal, DateTime(2026, 3, 2), amount: 60),
        _intake('older', cereal, DateTime(2026, 3, 1), amount: 45),
      ]);

      final last = await usecase.getLastIntakeOfMeal(_food('cereal'));

      expect(last?.id, 'newer');
      expect(last?.amount, 60);
    },
  );

  test('two entries at the same moment: the one added last wins', () async {
    final cereal = _meal(code: 'cereal');
    final at = DateTime(2026, 3, 1);
    await boxA.addAll([
      _intake('first', cereal, at, amount: 45),
      _intake('second', cereal, at, amount: 60),
    ]);

    expect((await usecase.getLastIntakeOfMeal(_food('cereal')))?.id, 'second');
  });

  test('matched by code, not by name', () async {
    await boxA.add(
      _intake(
        'same-name',
        _meal(code: 'other-code', name: 'Cereal'),
        DateTime(2026, 3, 1),
      ),
    );

    expect(
      await usecase.getLastIntakeOfMeal(_food('cereal', name: 'Cereal')),
      isNull,
    );
  });

  test('the same code from another source is another food', () async {
    await boxA.add(
      _intake(
        'custom',
        _meal(code: '4000000000000', source: MealSourceDBO.custom),
        DateTime(2026, 3, 1),
      ),
    );

    expect(await usecase.getLastIntakeOfMeal(_food('4000000000000')), isNull);
  });

  test('a food without a code is never matched', () async {
    await boxA.addAll([
      _intake(
        'no-code',
        _meal(code: null, name: 'Apple'),
        DateTime(2026, 3, 1),
      ),
      _intake('blank', _meal(code: '', name: 'Apple'), DateTime(2026, 3, 2)),
    ]);

    expect(
      await usecase.getLastIntakeOfMeal(_food(null, name: 'Apple')),
      isNull,
    );
    expect(await usecase.getLastIntakeOfMeal(_food('', name: 'Apple')), isNull);
  });

  test(
    'a scanned product and the same product from search are one food',
    () async {
      // Both reach the screen as an OFF record keyed by the barcode: the scan
      // as the full product, the search hit as a thin one.
      await boxA.add(
        _intake(
          'scanned',
          _meal(code: '4012345678901'),
          DateTime(2026, 3, 1),
          amount: 250,
        ),
      );

      final fromSearch = await usecase.getLastIntakeOfMeal(
        _food('4012345678901', detailed: false),
      );
      final fromScan = await usecase.getLastIntakeOfMeal(
        _food('4012345678901', detailed: true),
      );

      expect(fromSearch?.id, 'scanned');
      expect(fromScan?.id, 'scanned');
    },
  );

  test('deleting the last entry falls back to the one before it', () async {
    final cereal = _meal(code: 'cereal');
    await boxA.addAll([
      _intake('older', cereal, DateTime(2026, 3, 1), amount: 45),
      _intake('newer', cereal, DateTime(2026, 3, 2), amount: 60),
    ]);

    await dataSource.deleteIntakeFromId('newer');
    expect((await usecase.getLastIntakeOfMeal(_food('cereal')))?.id, 'older');

    await dataSource.deleteIntakeFromId('older');
    expect(await usecase.getLastIntakeOfMeal(_food('cereal')), isNull);
  });

  test("another profile's entries are not used", () async {
    await boxB.add(
      _intake('in-b', _meal(code: 'cereal'), DateTime(2026, 3, 1), amount: 80),
    );

    expect(await usecase.getLastIntakeOfMeal(_food('cereal')), isNull);

    provider.activeProfileId = 'b';
    expect((await usecase.getLastIntakeOfMeal(_food('cereal')))?.id, 'in-b');
  });

  test('a recipe is matched by its id', () async {
    await boxA.add(
      _intake(
        'recipe',
        _meal(code: 'recipe-1', source: MealSourceDBO.recipe),
        DateTime(2026, 3, 1),
        unit: 'serving',
        amount: 600,
      ),
    );

    final last = await usecase.getLastIntakeOfMeal(
      _food('recipe-1', source: MealSourceEntity.recipe),
    );

    expect(last?.id, 'recipe');
    expect(last?.unit, 'serving');
  });

  test('looking up leaves every logged entry as it was', () async {
    final cereal = _meal(code: 'cereal');
    await boxA.addAll([
      _intake('older', cereal, DateTime(2026, 3, 1), amount: 45),
      _intake('newer', cereal, DateTime(2026, 3, 2), amount: 60),
    ]);
    final before = boxA.values
        .map((i) => (i.id, i.amount, i.unit, i.dateTime))
        .toList();

    await usecase.getLastIntakeOfMeal(_food('cereal'));

    expect(
      boxA.values.map((i) => (i.id, i.amount, i.unit, i.dateTime)).toList(),
      before,
    );
  });
}
