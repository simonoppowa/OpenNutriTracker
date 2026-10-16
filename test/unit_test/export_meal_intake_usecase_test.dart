import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/data/data_source/health/external_meal_intake.dart';
import 'package:opennutritracker/core/data/dbo/intake_dbo.dart';
import 'package:opennutritracker/core/data/repository/config_repository.dart';
import 'package:opennutritracker/core/data/repository/health_export_repository.dart';
import 'package:opennutritracker/core/data/repository/intake_repository.dart';
import 'package:opennutritracker/core/domain/entity/app_theme_entity.dart';
import 'package:opennutritracker/core/domain/entity/config_entity.dart';
import 'package:opennutritracker/core/domain/entity/intake_entity.dart';
import 'package:opennutritracker/core/domain/entity/intake_type_entity.dart';
import 'package:opennutritracker/core/domain/usecase/add_intake_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/delete_intake_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/export_meal_intake_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/update_intake_usecase.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_nutriments_entity.dart';

class _FakeHealthExportRepository extends Fake
    implements HealthExportRepository {
  final List<ExternalMealIntake> writtenMeals = [];
  final List<String> deletedMealIds = [];
  final List<DateTime?> deleteWindows = [];
  bool writeResult = true;
  bool deleteResult = true;
  bool shouldThrow = false;

  @override
  Future<bool> writeMeal(ExternalMealIntake intake) async {
    if (shouldThrow) throw Exception('Platform channel error');
    writtenMeals.add(intake);
    return writeResult;
  }

  @override
  Future<bool> deleteMeal(String clientRecordId, {DateTime? at}) async {
    if (shouldThrow) throw Exception('Platform channel error');
    deletedMealIds.add(clientRecordId);
    deleteWindows.add(at);
    return deleteResult;
  }
}

class _FakeConfigRepository extends Fake implements ConfigRepository {
  bool exportEnabled = true;

  @override
  Future<ConfigEntity> getConfig() async {
    return ConfigEntity(
      true,
      true,
      false,
      AppThemeEntity.system,
      healthExportEnabled: exportEnabled,
    );
  }
}

class _FakeIntakeRepository extends Fake implements IntakeRepository {
  final List<IntakeEntity> addedIntakes = [];
  final List<IntakeEntity> deletedIntakes = [];
  IntakeEntity? updatedIntakeResult;

  /// What the repository still holds — read by the iOS delete-window check.
  List<IntakeEntity> storedIntakes = [];

  @override
  Future<List<IntakeDBO>> getAllIntakesDBO() async =>
      storedIntakes.map(IntakeDBO.fromIntakeEntity).toList();

  @override
  Future<void> addIntake(IntakeEntity intakeEntity) async {
    addedIntakes.add(intakeEntity);
  }

  @override
  Future<void> deleteIntake(IntakeEntity intakeEntity) async {
    deletedIntakes.add(intakeEntity);
  }

  @override
  Future<IntakeEntity?> updateIntake(
    String intakeId,
    Map<String, dynamic> fields,
  ) async {
    return updatedIntakeResult;
  }
}

void main() {
  final mealDate = DateTime(2026, 6, 15, 12, 30);
  final testIntake = IntakeEntity(
    id: 'intake-123',
    unit: 'g',
    amount: 150, // 150g -> scale factor 1.5
    type: IntakeTypeEntity.lunch,
    dateTime: mealDate,
    meal: const MealEntity(
      code: 'code-abc',
      name: 'Granola & Yogurt',
      url: null,
      mealQuantity: '100',
      mealUnit: 'g',
      servingQuantity: null,
      servingUnit: 'g',
      servingSize: '100 g',
      source: MealSourceEntity.off,
      nutriments: MealNutrimentsEntity(
        energyKcal100: 200, // * 1.5 = 300 kcal
        carbohydrates100: 30, // * 1.5 = 45 g
        fat100: 10, // * 1.5 = 15 g
        proteins100: 8, // * 1.5 = 12 g
        saturatedFat100: 2, // * 1.5 = 3 g
        sugars100: 12, // * 1.5 = 18 g
        fiber100: 4, // * 1.5 = 6 g
        sodium100: 100, // 100mg * 1.5 = 150mg -> 0.15 g
        calcium100: 200, // 200mg * 1.5 = 300mg -> 0.3 g
        potassium100: 300, // 300mg * 1.5 = 450mg -> 0.45 g
        cholesterol100: 20, // 20mg * 1.5 = 30mg -> 0.03 g
        vitaminD100: 2, // 2µg * 1.5 = 3µg -> 3e-6 g
      ),
    ),
  );

  group('ExternalMealIntake mapping', () {
    test('scales calories and converts micronutrient units properly', () {
      final external = ExternalMealIntake.fromIntake(testIntake);

      expect(external.id, equals('ont_intake_intake-123'));
      expect(external.name, equals('Granola & Yogurt'));
      expect(external.mealTypeName, equals('LUNCH'));
      expect(external.dateTime, equals(mealDate));
      expect(external.calories, closeTo(300.0, 0.01));
      expect(external.carbohydrates, closeTo(45.0, 0.01));
      expect(external.fatTotal, closeTo(15.0, 0.01));
      expect(external.protein, closeTo(12.0, 0.01));
      expect(external.fatSaturated, closeTo(3.0, 0.01));
      expect(external.sugar, closeTo(18.0, 0.01));
      expect(external.fiber, closeTo(6.0, 0.01));
      // Milligrams to grams conversion
      expect(external.sodium, closeTo(0.15, 0.001));
      expect(external.calcium, closeTo(0.3, 0.001));
      expect(external.potassium, closeTo(0.45, 0.001));
      expect(external.cholesterol, closeTo(0.03, 0.001));
      // Micrograms to grams conversion
      expect(external.vitaminD, closeTo(3e-6, 1e-8));
    });
  });

  group('ExportMealIntakeUsecase', () {
    late _FakeHealthExportRepository healthRepo;
    late _FakeConfigRepository configRepo;
    late _FakeIntakeRepository intakeRepo;
    late ExportMealIntakeUsecase usecase;

    setUp(() {
      healthRepo = _FakeHealthExportRepository();
      configRepo = _FakeConfigRepository();
      intakeRepo = _FakeIntakeRepository();
      usecase = ExportMealIntakeUsecase(healthRepo, configRepo, intakeRepo);
    });

    test(
      'does nothing and returns false when healthExportEnabled is false',
      () async {
        configRepo.exportEnabled = false;

        final exportResult = await usecase.exportIntake(testIntake);
        final deleteResult = await usecase.deleteIntake(testIntake);

        expect(exportResult, isFalse);
        expect(deleteResult, isFalse);
        expect(healthRepo.writtenMeals, isEmpty);
        expect(healthRepo.deletedMealIds, isEmpty);
      },
    );

    test('writes meal intake when healthExportEnabled is true', () async {
      configRepo.exportEnabled = true;

      final result = await usecase.exportIntake(testIntake);

      expect(result, isTrue);
      expect(healthRepo.writtenMeals.length, equals(1));
      expect(healthRepo.writtenMeals.first.id, equals('ont_intake_intake-123'));
    });

    test('deletes meal intake with clientRecordId when deleted', () async {
      configRepo.exportEnabled = true;

      final result = await usecase.deleteIntake(testIntake);

      expect(result, isTrue);
      expect(healthRepo.deletedMealIds, equals(['ont_intake_intake-123']));
    });

    // #1393 review: iOS deletes by time window, and bulk add gives every row
    // the same timestamp — deleting one must not erase the others.
    group('iOS delete window', () {
      IntakeEntity loggedAt(String id, DateTime dateTime) => IntakeEntity(
        id: id,
        unit: testIntake.unit,
        amount: testIntake.amount,
        type: testIntake.type,
        meal: testIntake.meal,
        dateTime: dateTime,
      );

      test('is passed when no other entry starts inside it', () async {
        intakeRepo.storedIntakes = [
          loggedAt('earlier', mealDate.subtract(const Duration(seconds: 1))),
          loggedAt('later', mealDate.add(const Duration(minutes: 2))),
        ];

        await usecase.deleteIntake(testIntake);

        expect(healthRepo.deleteWindows, [mealDate]);
      });

      test('is withheld when a bulk-add sibling shares its time', () async {
        intakeRepo.storedIntakes = [loggedAt('sibling', mealDate)];

        await usecase.deleteIntake(testIntake);

        expect(healthRepo.deletedMealIds, ['ont_intake_intake-123']);
        expect(healthRepo.deleteWindows, [null]);
      });

      test('is withheld when another entry starts later inside it', () async {
        intakeRepo.storedIntakes = [
          loggedAt('next', mealDate.add(const Duration(seconds: 59))),
        ];

        await usecase.deleteIntake(testIntake);

        expect(healthRepo.deleteWindows, [null]);
      });

      test('ignores the entry being deleted if it is still stored', () async {
        intakeRepo.storedIntakes = [testIntake];

        await usecase.deleteIntake(testIntake);

        expect(healthRepo.deleteWindows, [mealDate]);
      });
    });

    test('catches platform error and returns false without throwing', () async {
      configRepo.exportEnabled = true;
      healthRepo.shouldThrow = true;

      expect(await usecase.exportIntake(testIntake), isFalse);
      expect(await usecase.deleteIntake(testIntake), isFalse);
    });
  });

  group('Intake usecases live export triggers', () {
    late _FakeHealthExportRepository healthRepo;
    late _FakeConfigRepository configRepo;
    late _FakeIntakeRepository intakeRepo;
    late ExportMealIntakeUsecase exportUsecase;

    setUp(() {
      healthRepo = _FakeHealthExportRepository();
      configRepo = _FakeConfigRepository();
      intakeRepo = _FakeIntakeRepository();
      exportUsecase = ExportMealIntakeUsecase(
        healthRepo,
        configRepo,
        intakeRepo,
      );
    });

    test('AddIntakeUsecase persists and triggers live export', () async {
      final addUsecase = AddIntakeUsecase(intakeRepo, exportUsecase);

      await addUsecase.addIntake(testIntake);
      await Future<void>.delayed(Duration.zero);

      expect(intakeRepo.addedIntakes, contains(testIntake));
      expect(healthRepo.writtenMeals.length, equals(1));
      expect(healthRepo.writtenMeals.first.id, equals('ont_intake_intake-123'));
    });

    test(
      'UpdateIntakeUsecase updates and triggers live export with updated entity',
      () async {
        final updated = IntakeEntity(
          id: testIntake.id,
          unit: testIntake.unit,
          amount: 200,
          type: testIntake.type,
          meal: testIntake.meal,
          dateTime: testIntake.dateTime,
        );
        intakeRepo.updatedIntakeResult = updated;
        final updateUsecase = UpdateIntakeUsecase(intakeRepo, exportUsecase);

        final res = await updateUsecase.updateIntake('intake-123', {
          'amount': 200,
        });
        await Future<void>.delayed(Duration.zero);

        expect(res, equals(updated));
        expect(healthRepo.writtenMeals.length, equals(1));
        expect(healthRepo.writtenMeals.first.calories, closeTo(400.0, 0.01));
      },
    );

    test(
      'DeleteIntakeUsecase deletes and triggers delete on health store',
      () async {
        final deleteUsecase = DeleteIntakeUsecase(intakeRepo, exportUsecase);

        await deleteUsecase.deleteIntake(testIntake);
        await Future<void>.delayed(Duration.zero);

        expect(intakeRepo.deletedIntakes, contains(testIntake));
        expect(healthRepo.deletedMealIds, equals(['ont_intake_intake-123']));
      },
    );
  });
}
