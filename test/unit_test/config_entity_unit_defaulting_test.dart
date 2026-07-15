import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/data/dbo/app_theme_dbo.dart';
import 'package:opennutritracker/core/data/dbo/config_dbo.dart';
import 'package:opennutritracker/core/domain/entity/body_weight_unit_entity.dart';
import 'package:opennutritracker/core/domain/entity/config_entity.dart';

/// Tests for the fallback logic in [ConfigEntity.fromConfigDBO] that maps
/// the legacy single `usesImperialUnits` flag to the three independent unit
/// preferences added in the feature/fdc-atwater-energy-id branch.
///
/// The invariant is: on a fresh install the three new fields are null, so
/// they derive entirely from the legacy flag. Once the user has touched a
/// preference, the explicit value overrides the legacy default regardless of
/// what the legacy flag says.
void main() {
  group('ConfigEntity.fromConfigDBO — unit defaulting', () {
    test('legacy usesImperialUnits=true, new fields null -> all imperial', () {
      final dbo = ConfigDBO(
        false,
        false,
        false,
        AppThemeDBO.system,
        usesImperialUnits: true,
        // usesImperialFoodUnits, usesImperialHeightUnits, bodyWeightUnitIndex all null
      );
      final entity = ConfigEntity.fromConfigDBO(dbo);

      expect(entity.usesImperialFoodUnits, isTrue,
          reason: 'food units should fall back to legacy imperial flag');
      expect(entity.usesImperialHeightUnits, isTrue,
          reason: 'height units should fall back to legacy imperial flag');
      expect(entity.bodyWeightUnit, equals(BodyWeightUnit.lb),
          reason: 'body weight should fall back to lb when legacy flag is true');
    });

    test('legacy usesImperialUnits=false, new fields null -> all metric', () {
      final dbo = ConfigDBO(
        false,
        false,
        false,
        AppThemeDBO.system,
        usesImperialUnits: false,
      );
      final entity = ConfigEntity.fromConfigDBO(dbo);

      expect(entity.usesImperialFoodUnits, isFalse);
      expect(entity.usesImperialHeightUnits, isFalse);
      expect(entity.bodyWeightUnit, equals(BodyWeightUnit.kg));
    });

    test('legacy field null (first-run default) -> all metric', () {
      // ConfigDBO constructor defaults usesImperialUnits to false, but we
      // pass null explicitly to confirm fromConfigDBO handles that path too.
      final dbo = ConfigDBO(
        false,
        false,
        false,
        AppThemeDBO.system,
        usesImperialUnits: null,
      );
      final entity = ConfigEntity.fromConfigDBO(dbo);

      expect(entity.usesImperialFoodUnits, isFalse);
      expect(entity.usesImperialHeightUnits, isFalse);
      expect(entity.bodyWeightUnit, equals(BodyWeightUnit.kg));
    });

    test('explicit usesImperialFoodUnits=false overrides legacy imperial flag', () {
      final dbo = ConfigDBO(
        false,
        false,
        false,
        AppThemeDBO.system,
        usesImperialUnits: true,
        usesImperialFoodUnits: false, // user explicitly picked metric for food
      );
      final entity = ConfigEntity.fromConfigDBO(dbo);

      expect(entity.usesImperialFoodUnits, isFalse,
          reason: 'explicit false should override the legacy imperial flag for food');
      // Height and body weight still inherit the legacy flag because only
      // food was explicitly set.
      expect(entity.usesImperialHeightUnits, isTrue);
      expect(entity.bodyWeightUnit, equals(BodyWeightUnit.lb));
    });

    test('explicit usesImperialHeightUnits=false overrides legacy imperial flag', () {
      final dbo = ConfigDBO(
        false,
        false,
        false,
        AppThemeDBO.system,
        usesImperialUnits: true,
        usesImperialHeightUnits: false,
      );
      final entity = ConfigEntity.fromConfigDBO(dbo);

      expect(entity.usesImperialHeightUnits, isFalse);
      expect(entity.usesImperialFoodUnits, isTrue);
    });

    test('explicit bodyWeightUnitIndex=2 (st) overrides legacy flag', () {
      final dbo = ConfigDBO(
        false,
        false,
        false,
        AppThemeDBO.system,
        usesImperialUnits: false, // metric legacy flag
        bodyWeightUnitIndex: BodyWeightUnit.st.index, // but user picked stones
      );
      final entity = ConfigEntity.fromConfigDBO(dbo);

      expect(entity.bodyWeightUnit, equals(BodyWeightUnit.st),
          reason: 'explicit index should override the legacy metric default');
    });

    test('bodyWeightUnitIndex out of range (99) falls back to kg', () {
      final dbo = ConfigDBO(
        false,
        false,
        false,
        AppThemeDBO.system,
        bodyWeightUnitIndex: 99,
      );
      final entity = ConfigEntity.fromConfigDBO(dbo);

      expect(entity.bodyWeightUnit, equals(BodyWeightUnit.kg),
          reason: 'an out-of-range index should be clamped to kg by BodyWeightUnit.fromIndex');
    });

    test('bodyWeightUnitIndex negative falls back to kg', () {
      final dbo = ConfigDBO(
        false,
        false,
        false,
        AppThemeDBO.system,
        bodyWeightUnitIndex: -1,
      );
      final entity = ConfigEntity.fromConfigDBO(dbo);

      expect(entity.bodyWeightUnit, equals(BodyWeightUnit.kg));
    });
  });
}
