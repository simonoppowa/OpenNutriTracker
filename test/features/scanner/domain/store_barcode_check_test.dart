import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/data/data_source/config_data_source.dart';
import 'package:opennutritracker/core/data/dbo/app_theme_dbo.dart';
import 'package:opennutritracker/core/data/dbo/config_dbo.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_nutriments_entity.dart';
import 'package:opennutritracker/features/scanner/domain/store_barcode_check.dart';
import 'package:opennutritracker/features/scanner/util/barcode_check_digit.dart';

class _FakeConfigDataSource implements ConfigDataSource {
  ConfigDBO config = ConfigDBO(false, false, false, AppThemeDBO.system);

  @override
  Future<ConfigDBO> getConfig() async => config;

  @override
  Future<void> addConfig(ConfigDBO configDBO) async => config = configDBO;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('Unexpected call: ${invocation.memberName}');
}

MealEntity _product(String code, {MealSourceEntity? source}) => MealEntity(
  code: code,
  name: 'Milk chocolate de Noël',
  brands: 'Favorina',
  url: null,
  mealQuantity: null,
  mealUnit: 'g',
  servingQuantity: null,
  servingUnit: 'g',
  servingSize: null,
  nutriments: MealNutrimentsEntity.empty(),
  source: source ?? MealSourceEntity.off,
);

void main() {
  group('isStoreInternalBarcode', () {
    test('eight digits starting with 2 are a store code', () {
      expect(isStoreInternalBarcode('20697112'), isTrue);
      expect(isStoreInternalBarcode('29012345'), isTrue);
    });

    test('other codes are not', () {
      expect(isStoreInternalBarcode('40084015'), isFalse);
      expect(isStoreInternalBarcode('4056489123456'), isFalse);
      expect(isStoreInternalBarcode('2069711'), isFalse);
      expect(isStoreInternalBarcode('2069711a'), isFalse);
      expect(isStoreInternalBarcode('2000000000008'), isFalse);
    });
  });

  group('StoreBarcodeCheck', () {
    late _FakeConfigDataSource config;
    late StoreBarcodeCheck check;

    setUp(() {
      config = _FakeConfigDataSource();
      check = StoreBarcodeCheck(config);
    });

    test('asks for an Open Food Facts product on a store code', () async {
      expect(await check.needsConfirmation(_product('20697112')), isTrue);
    });

    test('does not ask for an EAN-13 product', () async {
      expect(await check.needsConfirmation(_product('4056489123456')), isFalse);
    });

    test('does not ask for an own food on a store code', () async {
      expect(
        await check.needsConfirmation(
          _product('20697112', source: MealSourceEntity.custom),
        ),
        isFalse,
      );
    });

    test('asks once per code: a confirmed code is not asked again', () async {
      await check.confirm('20697112');

      expect(await check.needsConfirmation(_product('20697112')), isFalse);
      expect(await check.needsConfirmation(_product('20123459')), isTrue);
      expect(config.config.confirmedStoreBarcodes, ['20697112']);
    });

    test('confirming twice stores the code once', () async {
      await check.confirm('20697112');
      await check.confirm('20697112');

      expect(config.config.confirmedStoreBarcodes, ['20697112']);
    });

    test('confirmed codes travel in the config JSON', () async {
      await check.confirm('20697112');

      final json = config.config.toJson();
      expect(json['confirmedStoreBarcodes'], ['20697112']);
      expect(ConfigDBO.fromJson(json).confirmedStoreBarcodes, ['20697112']);
    });
  });
}
