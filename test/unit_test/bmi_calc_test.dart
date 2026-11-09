import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/domain/entity/user_bmi_entity.dart';
import 'package:opennutritracker/core/utils/calc/bmi_calc.dart';

import '../fixture/user_entity_fixtures.dart';

void main() {
  group('BMICalc.getBMI', () {
    test('180 cm and 80 kg', () {
      final user = UserEntityFixtures.youngSedentaryMaleWantingToMaintainWeight;

      // 80 / 1.8²
      expect(BMICalc.getBMI(user), closeTo(24.691, 0.001));
    });

    test('160 cm and 75 kg', () {
      final user = UserEntityFixtures.middleAgedActiveFemaleWantingToLoseWeight;

      // 75 / 1.6²
      expect(BMICalc.getBMI(user), closeTo(29.297, 0.001));
    });

    test('164 cm and 55 kg', () {
      final user = UserEntityFixtures.elderlyLowActiveMaleWantingToGainWeight;

      // 55 / 1.64²
      expect(BMICalc.getBMI(user), closeTo(20.449, 0.001));
    });
  });

  group('BMICalc.getNutritionalStatus', () {
    test('below 18.5 is underweight', () {
      expect(
        BMICalc.getNutritionalStatus(15.0),
        UserNutritionalStatus.underWeight,
      );
      expect(
        BMICalc.getNutritionalStatus(18.49),
        UserNutritionalStatus.underWeight,
      );
    });

    test('18.5 up to 25 is normal weight', () {
      expect(
        BMICalc.getNutritionalStatus(18.5),
        UserNutritionalStatus.normalWeight,
      );
      expect(
        BMICalc.getNutritionalStatus(24.99),
        UserNutritionalStatus.normalWeight,
      );
    });

    test('25 up to 30 is pre-obesity', () {
      expect(
        BMICalc.getNutritionalStatus(25.0),
        UserNutritionalStatus.preObesity,
      );
      expect(
        BMICalc.getNutritionalStatus(29.99),
        UserNutritionalStatus.preObesity,
      );
    });

    test('30 up to 35 is obesity class I', () {
      expect(
        BMICalc.getNutritionalStatus(30.0),
        UserNutritionalStatus.obesityClassI,
      );
      expect(
        BMICalc.getNutritionalStatus(34.99),
        UserNutritionalStatus.obesityClassI,
      );
    });

    test('35 up to 40 is obesity class II', () {
      expect(
        BMICalc.getNutritionalStatus(35.0),
        UserNutritionalStatus.obesityClassII,
      );
      expect(
        BMICalc.getNutritionalStatus(39.99),
        UserNutritionalStatus.obesityClassII,
      );
    });

    test('40 and above is obesity class III', () {
      expect(
        BMICalc.getNutritionalStatus(40.0),
        UserNutritionalStatus.obesityClassIII,
      );
      expect(
        BMICalc.getNutritionalStatus(55.0),
        UserNutritionalStatus.obesityClassIII,
      );
    });

    test('the band constants match the classification', () {
      expect(
        BMICalc.getNutritionalStatus(BMICalc.healthyBmiMin),
        UserNutritionalStatus.normalWeight,
      );
      expect(
        BMICalc.getNutritionalStatus(BMICalc.healthyBmiMaxInclusive),
        UserNutritionalStatus.normalWeight,
      );
      expect(
        BMICalc.getNutritionalStatus(BMICalc.preObesityBmiFloor),
        UserNutritionalStatus.preObesity,
      );
    });
  });

  group('BMICalc fixtures end to end', () {
    test('each fixture user lands in the expected band', () {
      expect(
        BMICalc.getNutritionalStatus(
          BMICalc.getBMI(
            UserEntityFixtures.youngSedentaryMaleWantingToMaintainWeight,
          ),
        ),
        UserNutritionalStatus.normalWeight,
      );
      expect(
        BMICalc.getNutritionalStatus(
          BMICalc.getBMI(
            UserEntityFixtures.middleAgedActiveFemaleWantingToLoseWeight,
          ),
        ),
        UserNutritionalStatus.preObesity,
      );
    });
  });
}
