import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/data/dbo/app_theme_dbo.dart';
import 'package:opennutritracker/core/data/dbo/config_dbo.dart';
import 'package:opennutritracker/core/domain/entity/config_entity.dart';

// #1126: the new `defaultToRawFoodUnits` field defaults to false so every
// install that predates it keeps the pre-existing "prefer serving whenever
// one exists" behaviour without a migration. Once the user opts in, the
// stored value carries into ConfigEntity untouched.

void main() {
  group('ConfigEntity.fromConfigDBO defaultToRawFoodUnits', () {
    test('defaults to false when the stored DBO field is null', () {
      final dbo = ConfigDBO(false, false, false, AppThemeDBO.system);
      // Sanity: the DBO's own field is nullable and starts absent.
      expect(dbo.defaultToRawFoodUnits, isNull);

      final entity = ConfigEntity.fromConfigDBO(dbo);
      expect(entity.defaultToRawFoodUnits, isFalse);
    });

    test('carries a stored true value into the entity', () {
      final dbo = ConfigDBO(false, false, false, AppThemeDBO.system)
        ..defaultToRawFoodUnits = true;

      final entity = ConfigEntity.fromConfigDBO(dbo);
      expect(entity.defaultToRawFoodUnits, isTrue);
    });

    test('carries a stored false value through unchanged', () {
      final dbo = ConfigDBO(false, false, false, AppThemeDBO.system)
        ..defaultToRawFoodUnits = false;

      final entity = ConfigEntity.fromConfigDBO(dbo);
      expect(entity.defaultToRawFoodUnits, isFalse);
    });
  });
}
