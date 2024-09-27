import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:opennutritracker/core/data/data_source/intake_data_source.dart';
import 'package:opennutritracker/core/data/dbo/intake_dbo.dart';
import 'package:opennutritracker/core/data/dbo/intake_type_dbo.dart';
import 'package:opennutritracker/core/data/dbo/meal_dbo.dart';
import 'package:opennutritracker/core/data/dbo/meal_nutriments_dbo.dart';
import 'package:opennutritracker/core/data/repository/intake_repository.dart';
import 'package:opennutritracker/core/domain/entity/intake_entity.dart';
import 'package:opennutritracker/core/domain/entity/intake_type_entity.dart';

import '../fixture/meal_entity_fixtures.dart';

void main() {

  group('IntakeRepository test', () {
    setUp(() {
      TestWidgetsFlutterBinding.ensureInitialized();
      // final temp = await getTemporaryDirectory();
      Hive.init(".");
      Hive.registerAdapter(IntakeDBOAdapter());
      Hive.registerAdapter(IntakeTypeDBOAdapter());
      Hive.registerAdapter(MealDBOAdapter());
      Hive.registerAdapter(MealSourceDBOAdapter());
      Hive.registerAdapter(MealNutrimentsDBOAdapter());
    });

    tearDown(() {
      Hive.deleteFromDisk();
    });

    test('returns last added first', () async {
      final box = await Hive.openBox<IntakeDBO>('intake_test');

      final repo = IntakeRepository(IntakeDataSource(box));


      await repo.addIntake(IntakeEntity(
          id: "1",
          unit: "g",
          amount: 1,
          type: IntakeTypeEntity.breakfast,
          meal: MealEntityFixtures.mealOne,
          dateTime: DateTime.utc(2024, 1, 1, 0, 0, 0)));
      await repo.addIntake(IntakeEntity(
          id: "2",
          unit: "g",
          amount: 1,
          type: IntakeTypeEntity.breakfast,
          meal: MealEntityFixtures.mealTwo,
          dateTime: DateTime.utc(2024, 1, 2, 0, 0, 0)));
      await repo.addIntake(IntakeEntity(
          id: "3",
          unit: "g",
          amount: 1,
          type: IntakeTypeEntity.breakfast,
          meal: MealEntityFixtures.mealThree,
          dateTime: DateTime.utc(2024, 1, 3, 0, 0, 0)));

      final recents = (await repo.getRecentIntake()).map((e) => e.id).toList();
      expect(recents, List.from(["3", "2", "1"]));
    });
  });
}
