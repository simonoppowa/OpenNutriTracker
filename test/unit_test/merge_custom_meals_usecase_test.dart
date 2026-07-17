import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:opennutritracker/core/data/data_source/custom_meal_data_source.dart';
import 'package:opennutritracker/core/data/data_source/intake_data_source.dart';
import 'package:opennutritracker/core/data/data_source/tracked_day_data_source.dart';
import 'package:opennutritracker/core/data/dbo/intake_dbo.dart';
import 'package:opennutritracker/core/data/dbo/intake_type_dbo.dart';
import 'package:opennutritracker/core/data/dbo/meal_dbo.dart';
import 'package:opennutritracker/core/data/dbo/meal_nutriments_dbo.dart';
import 'package:opennutritracker/core/data/dbo/tracked_day_dbo.dart';
import 'package:opennutritracker/core/data/repository/intake_repository.dart';
import 'package:opennutritracker/core/data/repository/tracked_day_repository.dart';
import 'package:opennutritracker/core/domain/usecase/add_tracked_day_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/merge_custom_meals_usecase.dart';

import '../helpers/hive_test_setup.dart';
import '../helpers/fake_hive_db_provider.dart';

MealNutrimentsDBO _nutriments({double kcal = 100, double protein = 5}) =>
    MealNutrimentsDBO(
      energyKcal100: kcal,
      carbohydrates100: 10,
      fat100: 2,
      proteins100: protein,
      sugars100: null,
      saturatedFat100: null,
      fiber100: null,
    );

MealDBO _customMeal({
  required String code,
  required String name,
  double kcal = 100,
}) =>
    MealDBO(
      code: code,
      name: name,
      brands: null,
      thumbnailImageUrl: null,
      mainImageUrl: null,
      url: null,
      mealQuantity: '100',
      mealUnit: 'g',
      servingQuantity: null,
      servingUnit: 'g',
      servingSize: null,
      nutriments: _nutriments(kcal: kcal),
      source: MealSourceDBO.custom,
    );

IntakeDBO _intake({
  required String id,
  required MealDBO meal,
  DateTime? at,
}) =>
    IntakeDBO(
      id: id,
      unit: 'g',
      amount: 100,
      type: IntakeTypeDBO.lunch,
      meal: meal,
      dateTime: at ?? DateTime.utc(2025, 1, 1),
    );

void main() {
  group('MergeCustomMealsUseCase', () {
    late Box<MealDBO> customBox;
    late Box<IntakeDBO> intakeBox;
    late Box<TrackedDayDBO> trackedDayBox;
    late MergeCustomMealsUseCase usecase;

    setUpAll(() {
      TestWidgetsFlutterBinding.ensureInitialized();
      Hive.init('.');
      registerHiveAdaptersOnce();
    });

    setUp(() async {
      final stamp = DateTime.now().microsecondsSinceEpoch;
      customBox = await Hive.openBox<MealDBO>('merge_custom_meals_$stamp');
      intakeBox = await Hive.openBox<IntakeDBO>('merge_intake_$stamp');
      trackedDayBox =
          await Hive.openBox<TrackedDayDBO>('merge_tracked_$stamp');
      final customDs = CustomMealDataSource(FakeHiveDBProvider(customMealBox: customBox));
      final intakeRepo = IntakeRepository(IntakeDataSource(FakeHiveDBProvider(intakeBox: intakeBox)));
      final trackedRepo =
          TrackedDayRepository(TrackedDayDataSource(FakeHiveDBProvider(trackedDayBox: trackedDayBox)));
      usecase = MergeCustomMealsUseCase(
        customDs,
        intakeRepo,
        AddTrackedDayUsecase(trackedRepo),
      );
    });

    tearDown(() async {
      await customBox.deleteFromDisk();
      await intakeBox.deleteFromDisk();
      await trackedDayBox.deleteFromDisk();
    });

    test('rewrites loser intakes to winner and deletes loser meal', () async {
      final loser = _customMeal(code: 'L', name: 'Apple (dup)', kcal: 50);
      final winner = _customMeal(code: 'W', name: 'Apple', kcal: 50);
      await customBox.add(loser);
      await customBox.add(winner);

      await intakeBox.add(_intake(id: 'i1', meal: loser));
      await intakeBox.add(_intake(id: 'i2', meal: loser));
      await intakeBox.add(_intake(id: 'i3', meal: loser));

      final result = await usecase.merge(loserKey: 'L', winnerKey: 'W');

      expect(result.rewrittenIntakeCount, equals(3));
      expect(result.winnerDisplayName, equals('Apple'));

      // Loser is gone from the saved-meals list; winner remains.
      final remainingCustom = customBox.values.map((m) => m.code).toSet();
      expect(remainingCustom, equals({'W'}));

      // Every intake now snapshots the winner.
      final rewrittenCodes =
          intakeBox.values.map((i) => i.meal.code).toList();
      expect(rewrittenCodes, equals(['W', 'W', 'W']));
      // And keeps its original id so existing references stay valid.
      final rewrittenIds = intakeBox.values.map((i) => i.id).toSet();
      expect(rewrittenIds, equals({'i1', 'i2', 'i3'}));
    });
  });
}
