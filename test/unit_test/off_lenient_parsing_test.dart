// ignore_for_file: non_constant_identifier_names

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:opennutritracker/features/add_meal/data/data_sources/off_data_source.dart';
import 'package:opennutritracker/features/add_meal/data/dto/off/off_product_dto.dart';
import 'package:opennutritracker/features/add_meal/data/dto/off/off_product_response_dto.dart';
import 'package:opennutritracker/features/add_meal/data/dto/off/off_word_response_dto.dart';
import 'package:opennutritracker/features/scanner/data/product_not_found_exception.dart';
import 'package:package_info_plus/package_info_plus.dart';

Map<String, dynamic> _goodProduct(String code) => {
      'code': code,
      'product_name': 'Product $code',
      'nutriments': {'energy-kcal_100g': 100},
    };

OFFDataSource _barcodeDataSource(Map<String, dynamic> body) => OFFDataSource(
      clientFactory: () =>
          MockClient((_) async => http.Response(jsonEncode(body), 200)),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    PackageInfo.setMockInitialValues(
      appName: 'ont-test',
      packageName: 'test',
      version: '0.0.0',
      buildNumber: '1',
      buildSignature: '',
    );
  });

  group('OFFDataSource.fetchBarcodeResults without a product', () {
    test('status 0 and no product key throws ProductNotFoundException',
        () async {
      final dataSource = _barcodeDataSource({
        'code': '0000000000000',
        'status': 0,
        'status_verbose': 'product not found',
      });

      await expectLater(
        dataSource.fetchBarcodeResults('0000000000000'),
        throwsA(isA<ProductNotFoundException>()),
      );
    });

    test('an explicit null product throws ProductNotFoundException', () async {
      final dataSource = _barcodeDataSource({
        'status': 1,
        'status_verbose': 'product found',
        'product': null,
      });

      await expectLater(
        dataSource.fetchBarcodeResults('123'),
        throwsA(isA<ProductNotFoundException>()),
      );
    });

    test('status 0 throws even when a stub product is attached', () async {
      final dataSource = _barcodeDataSource({
        'status': 0,
        'status_verbose': 'product not found',
        'product': {'code': '123'},
      });

      await expectLater(
        dataSource.fetchBarcodeResults('123'),
        throwsA(isA<ProductNotFoundException>()),
      );
    });

    test('a normal response still returns the product', () async {
      final dataSource = _barcodeDataSource({
        'status': 1,
        'status_verbose': 'product found',
        'product': _goodProduct('123'),
      });

      final response = await dataSource.fetchBarcodeResults('123');

      expect(response.product?.code, '123');
    });
  });

  group('OFFProductResponseDTO.fromJson', () {
    test('parses a response with no product instead of throwing', () {
      final dto = OFFProductResponseDTO.fromJson({'status': 0});

      expect(dto.product, isNull);
      expect(dto.status, 0);
      expect(dto.status_verbose, isNull);
    });
  });

  group('OFFProductDTO.fromJson leniency', () {
    test('null nutriments reads as absent', () {
      final dto = OFFProductDTO.fromJson({'code': '1', 'nutriments': null});

      expect(dto.nutriments, isNull);
    });

    test('a non-object nutriments reads as absent', () {
      final dto = OFFProductDTO.fromJson({'code': '1', 'nutriments': 'n/a'});

      expect(dto.nutriments, isNull);
    });

    test('a numeric field delivered as a string is parsed', () {
      final dto = OFFProductDTO.fromJson({
        'code': '1',
        'popularity_key': '12.5',
      });

      expect(dto.popularity_key, 12.5);
    });

    test('a comma-decimal string is parsed', () {
      final dto = OFFProductDTO.fromJson({'popularity_key': '12,5'});

      expect(dto.popularity_key, 12.5);
    });

    test('an unparseable numeric string becomes null', () {
      final dto = OFFProductDTO.fromJson({'popularity_key': 'lots'});

      expect(dto.popularity_key, isNull);
    });

    test('a real number is untouched', () {
      final dto = OFFProductDTO.fromJson({'popularity_key': 42});

      expect(dto.popularity_key, 42);
    });

    test('countries_tags tolerates a non-list value', () {
      final dto = OFFProductDTO.fromJson({'countries_tags': 'en:france'});

      expect(dto.countries_tags, isNull);
    });
  });

  group('OFFWordResponseDTO.fromJson leniency', () {
    test('one malformed product is skipped and the good ones are kept', () {
      final dto = OFFWordResponseDTO.fromJson({
        'count': 3,
        'page': 1,
        'page_count': '3',
        'page_size': 100,
        'hits': [
          _goodProduct('1'),
          // A string where a list is required throws inside the product.
          {'code': '2', 'brands': 'ok', 'product_name': 5},
          'not even an object',
          _goodProduct('3'),
        ],
      });

      expect(dto.products.map((p) => p.code), ['1', '3']);
      expect(dto.page_count, 3);
    });

    test('the classic products key is lenient too', () {
      final dto = OFFWordResponseDTO.fromJson({
        'products': [
          {'code': '1', 'popularity_key': '7'},
          null,
        ],
      });

      expect(dto.products, hasLength(1));
      expect(dto.products.single.popularity_key, 7);
    });

    test('a missing or non-list hits value gives an empty list', () {
      expect(OFFWordResponseDTO.fromJson({}).products, isEmpty);
      expect(OFFWordResponseDTO.fromJson({'hits': null}).products, isEmpty);
    });
  });
}
