import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/data/dbo/app_theme_dbo.dart';
import 'package:opennutritracker/core/data/dbo/config_dbo.dart';
import 'package:opennutritracker/core/domain/entity/config_entity.dart';

ConfigDBO _dbo({
  bool? healthImportEnabled,
  double? healthWorkoutKcalMultiplier,
  DateTime? healthLastImportAt,
}) => ConfigDBO(
  false,
  false,
  false,
  AppThemeDBO.system,
  healthImportEnabled: healthImportEnabled,
  healthWorkoutKcalMultiplier: healthWorkoutKcalMultiplier,
  healthLastImportAt: healthLastImportAt,
);

void main() {
  group('ConfigEntity health import defaults', () {
    test('a config written before the feature existed reads as opted out', () {
      final config = ConfigEntity.fromConfigDBO(ConfigDBO.empty());

      expect(config.healthImportEnabled, isFalse);
      expect(config.healthWorkoutKcalMultiplier, isNull);
      expect(config.healthLastImportAt, isNull);
    });

    test('no stored multiplier credits every reported calorie', () {
      final config = ConfigEntity.fromConfigDBO(_dbo());

      expect(config.effectiveHealthWorkoutKcalMultiplier, equals(1.0));
    });

    test('a stored multiplier is used verbatim', () {
      final config = ConfigEntity.fromConfigDBO(
        _dbo(healthWorkoutKcalMultiplier: 0.7),
      );

      expect(config.healthWorkoutKcalMultiplier, equals(0.7));
      expect(config.effectiveHealthWorkoutKcalMultiplier, equals(0.7));
    });

    test('both range bounds are accepted', () {
      final floor = ConfigEntity.fromConfigDBO(
        _dbo(
          healthWorkoutKcalMultiplier:
              ConfigEntity.minHealthWorkoutKcalMultiplier,
        ),
      );
      final ceiling = ConfigEntity.fromConfigDBO(
        _dbo(
          healthWorkoutKcalMultiplier:
              ConfigEntity.maxHealthWorkoutKcalMultiplier,
        ),
      );

      expect(floor.effectiveHealthWorkoutKcalMultiplier, equals(0.5));
      expect(ceiling.effectiveHealthWorkoutKcalMultiplier, equals(1.0));
    });

    test(
      'a multiplier outside the supported range is dropped, not scaled by',
      () {
        final tooLow = ConfigEntity.fromConfigDBO(
          _dbo(healthWorkoutKcalMultiplier: 0.1),
        );
        final tooHigh = ConfigEntity.fromConfigDBO(
          _dbo(healthWorkoutKcalMultiplier: 4.2),
        );

        expect(tooLow.healthWorkoutKcalMultiplier, isNull);
        expect(tooLow.effectiveHealthWorkoutKcalMultiplier, equals(1.0));
        expect(tooHigh.healthWorkoutKcalMultiplier, isNull);
        expect(tooHigh.effectiveHealthWorkoutKcalMultiplier, equals(1.0));
      },
    );

    test('the opt-in flag and the watermark round-trip', () {
      final watermark = DateTime.utc(2026, 5, 23, 14, 30);
      final config = ConfigEntity.fromConfigDBO(
        _dbo(healthImportEnabled: true, healthLastImportAt: watermark),
      );

      expect(config.healthImportEnabled, isTrue);
      expect(config.healthLastImportAt, equals(watermark));
    });
  });
}
