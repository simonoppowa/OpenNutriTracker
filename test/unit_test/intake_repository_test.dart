import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:opennutritracker/core/data/data_source/intake_data_source.dart';
import 'package:opennutritracker/core/data/dbo/intake_dbo.dart';
import 'package:opennutritracker/core/data/repository/intake_repository.dart';
import 'package:opennutritracker/core/domain/entity/intake_entity.dart';
import 'package:opennutritracker/core/domain/entity/intake_type_entity.dart';

import '../fixture/meal_entity_fixtures.dart';
import '../helpers/hive_test_setup.dart';
import '../helpers/fake_hive_db_provider.dart';

void main() {
  group('IntakeRepository test', () {
    setUp(() {
      TestWidgetsFlutterBinding.ensureInitialized();
      Hive.init(".");
      registerHiveAdaptersOnce();
    });

    tearDown(() {
      Hive.deleteFromDisk();
    });

    test('returns last added first', () async {
      final box = await Hive.openBox<IntakeDBO>('intake_test');

      final repo = IntakeRepository(IntakeDataSource(FakeHiveDBProvider(intakeBox: box)));

      await repo.addIntake(
        IntakeEntity(
          id: "1",
          unit: "g",
          amount: 1,
          type: IntakeTypeEntity.breakfast,
          meal: MealEntityFixtures.mealOne,
          dateTime: DateTime.utc(2024, 1, 1, 0, 0, 0),
        ),
      );
      await repo.addIntake(
        IntakeEntity(
          id: "2",
          unit: "g",
          amount: 1,
          type: IntakeTypeEntity.breakfast,
          meal: MealEntityFixtures.mealTwo,
          dateTime: DateTime.utc(2024, 1, 2, 0, 0, 0),
        ),
      );
      await repo.addIntake(
        IntakeEntity(
          id: "3",
          unit: "g",
          amount: 1,
          type: IntakeTypeEntity.breakfast,
          meal: MealEntityFixtures.mealThree,
          dateTime: DateTime.utc(2024, 1, 3, 0, 0, 0),
        ),
      );

      final recents = (await repo.getRecentIntake()).map((e) => e.id).toList();
      expect(recents, List.from(["3", "2", "1"]));
    });
  });
}
