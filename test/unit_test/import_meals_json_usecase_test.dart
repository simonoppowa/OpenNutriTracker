import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:opennutritracker/core/data/data_source/config_data_source.dart';
import 'package:opennutritracker/core/data/data_source/custom_meal_data_source.dart';
import 'package:opennutritracker/core/data/data_source/intake_data_source.dart';
import 'package:opennutritracker/core/data/data_source/tracked_day_data_source.dart';
import 'package:opennutritracker/core/data/data_source/user_activity_data_source.dart';
import 'package:opennutritracker/core/data/data_source/user_data_source.dart';
import 'package:opennutritracker/core/data/dbo/meal_dbo.dart';
import 'package:opennutritracker/core/data/repository/config_repository.dart';
import 'package:opennutritracker/core/data/repository/intake_repository.dart';
import 'package:opennutritracker/core/data/repository/tracked_day_repository.dart';
import 'package:opennutritracker/core/data/repository/user_activity_repository.dart';
import 'package:opennutritracker/core/data/repository/user_repository.dart';
import 'package:opennutritracker/core/domain/entity/intake_entity.dart';
import 'package:opennutritracker/core/domain/usecase/add_intake_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/add_tracked_day_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_kcal_goal_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_macro_goal_usecase.dart';
import 'package:opennutritracker/features/settings/domain/usecase/import_meals_json_usecase.dart';

import '../helpers/hive_test_setup.dart';

/// Tracks the intakes the use case wrote without actually touching Hive
/// for the intake/tracked-day side. The custom-meal side runs against a
/// real (per-test) Hive box, because the dedup behaviour we're exercising
/// lives in [CustomMealDataSource] itself.
class _RecordingAddIntakeUsecase extends AddIntakeUsecase {
  _RecordingAddIntakeUsecase(super.repo);

  final List<IntakeEntity> writtenIntakes = <IntakeEntity>[];

  @override
  Future<void> addIntake(IntakeEntity intakeEntity) async {
    writtenIntakes.add(intakeEntity);
  }
}

class _NoopAddTrackedDayUsecase extends AddTrackedDayUsecase {
  _NoopAddTrackedDayUsecase(super.repo);

  @override
  Future<bool> hasTrackedDay(DateTime day) async => true;

  @override
  Future<void> addNewTrackedDay(
    DateTime day,
    double totalKcalGoal,
    double totalCarbsGoal,
    double totalFatGoal,
    double totalProteinGoal,
  ) async {}

  @override
  Future<void> addDayCaloriesTracked(DateTime day, double caloriesTracked) async {}

  @override
  Future<void> addDayMacrosTracked(
    DateTime day, {
    double? carbsTracked,
    double? fatTracked,
    double? proteinTracked,
  }) async {}
}

class _StubGetKcalGoalUsecase extends GetKcalGoalUsecase {
  _StubGetKcalGoalUsecase(super.userRepo, super.configRepo, super.activityRepo);

  @override
  Future<double> getKcalGoal({
    userEntity,
    double? totalKcalActivitiesParam,
    double? kcalUserAdjustment,
  }) async =>
      2000;
}

class _StubGetMacroGoalUsecase extends GetMacroGoalUsecase {
  _StubGetMacroGoalUsecase(super.configRepo);

  @override
  Future<double> getCarbsGoal(double totalCalorieGoal) async => 250;
  @override
  Future<double> getFatsGoal(double totalCalorieGoal) async => 70;
  @override
  Future<double> getProteinsGoal(double totalCalorieGoal) async => 100;
}

void main() {
  group('ImportMealsJsonUsecase', () {
    late Box<MealDBO> customMealBox;
    late CustomMealDataSource customMealDataSource;
    late _RecordingAddIntakeUsecase addIntake;
    late ImportMealsJsonUsecase sut;

    setUpAll(() {
      TestWidgetsFlutterBinding.ensureInitialized();
      Hive.init('.');
      registerHiveAdaptersOnce();
    });

    setUp(() async {
      customMealBox = await Hive.openBox<MealDBO>(
        'custom_meal_json_usecase_${DateTime.now().microsecondsSinceEpoch}',
      );
      customMealDataSource = CustomMealDataSource(customMealBox);

      // The super constructors of the use cases require concrete repository
      // instances. The recording/no-op subclasses below never call into
      // those repositories — they short-circuit the public methods — so
      // we pass repositories backed by uninitialised data sources. None of
      // these are ever read.
      final dummyIntakeRepo = IntakeRepository(IntakeDataSource(_FakeBox()));
      final dummyTrackedRepo = TrackedDayRepository(TrackedDayDataSource(_FakeBox()));
      final dummyUserRepo = UserRepository(UserDataSource(_FakeBox()));
      final dummyConfigRepo = ConfigRepository(ConfigDataSource(_FakeBox()));
      final dummyActivityRepo =
          UserActivityRepository(UserActivityDataSource(_FakeBox()));

      addIntake = _RecordingAddIntakeUsecase(dummyIntakeRepo);
      sut = ImportMealsJsonUsecase(
        addIntake,
        _NoopAddTrackedDayUsecase(dummyTrackedRepo),
        _StubGetKcalGoalUsecase(dummyUserRepo, dummyConfigRepo, dummyActivityRepo),
        _StubGetMacroGoalUsecase(dummyConfigRepo),
        customMealDataSource,
      );
    });

    tearDown(() async {
      await customMealBox.deleteFromDisk();
    });

    test('one pasted entry writes one intake and one custom meal', () async {
      const json = '{"name":"Apple","kcal":95,"protein":0.5,"carbs":25,"fat":0.3}';

      final result = await sut.importFromJsonString(json);

      expect(result.imported, 1);
      expect(result.savedAsCustomMeals, 1);
      expect(addIntake.writtenIntakes, hasLength(1));
      expect(customMealDataSource.getAllCustomMeals(), hasLength(1));
      expect(customMealDataSource.getAllCustomMeals().single.name, 'Apple');
    });

    test(
        'pasting the same entry twice writes two intakes but only one custom meal '
        '(dedup on name)', () async {
      const json = '{"name":"Apple","kcal":95,"protein":0.5,"carbs":25,"fat":0.3}';

      await sut.importFromJsonString(json);
      final second = await sut.importFromJsonString(json);

      expect(addIntake.writtenIntakes, hasLength(2),
          reason: 'every paste should land in the diary, even if the meal '
              'is already saved');
      expect(customMealDataSource.getAllCustomMeals(), hasLength(1),
          reason: 'the saved-meals list should not bloat on re-paste');
      expect(second.imported, 1);
      expect(second.savedAsCustomMeals, 0,
          reason: 'the second paste finds the name already in the box and '
              'skips the custom-meal write');
    });

    test(
        'name dedup is case-insensitive', () async {
      const json1 = '{"name":"Apple","kcal":95,"protein":0.5,"carbs":25,"fat":0.3}';
      const json2 = '{"name":"apple","kcal":95,"protein":0.5,"carbs":25,"fat":0.3}';

      await sut.importFromJsonString(json1);
      final second = await sut.importFromJsonString(json2);

      expect(customMealDataSource.getAllCustomMeals(), hasLength(1));
      expect(second.savedAsCustomMeals, 0);
    });

    test('an array of three distinct entries writes three intakes and three custom meals',
        () async {
      const json = '['
          '{"name":"Oats","kcal":150,"protein":5,"carbs":27,"fat":2.5},'
          '{"name":"Banana","kcal":105,"protein":1.3,"carbs":27,"fat":0.4},'
          '{"name":"Chicken","kcal":165,"protein":31,"carbs":0,"fat":3.6}'
          ']';

      final result = await sut.importFromJsonString(json);

      expect(result.imported, 3);
      expect(result.savedAsCustomMeals, 3);
      expect(addIntake.writtenIntakes, hasLength(3));
      final savedNames =
          customMealDataSource.getAllCustomMeals().map((m) => m.name).toSet();
      expect(savedNames, equals({'Oats', 'Banana', 'Chicken'}));
    });

    test('an array containing a duplicate name dedups within a single paste',
        () async {
      const json = '['
          '{"name":"Oats","kcal":150,"protein":5,"carbs":27,"fat":2.5},'
          '{"name":"Oats","kcal":150,"protein":5,"carbs":27,"fat":2.5},'
          '{"name":"Banana","kcal":105,"protein":1.3,"carbs":27,"fat":0.4}'
          ']';

      final result = await sut.importFromJsonString(json);

      expect(result.imported, 3);
      expect(result.savedAsCustomMeals, 2,
          reason: 'two Oats intakes but only one Oats custom meal');
      expect(addIntake.writtenIntakes, hasLength(3));
      expect(customMealDataSource.getAllCustomMeals(), hasLength(2));
    });
  });
}

/// Stand-in for a Hive box used only to satisfy the data-source constructors
/// in tests where the data source itself is never invoked. Any method call
/// throws so that misuse fails loudly rather than silently swallowing.
class _FakeBox<T> implements Box<T> {
  @override
  dynamic noSuchMethod(Invocation invocation) {
    throw UnsupportedError(
      'Fake Hive box invoked: ${invocation.memberName}. The test should not '
      'be reaching the underlying data source.',
    );
  }
}
