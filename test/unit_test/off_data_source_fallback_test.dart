import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:opennutritracker/features/add_meal/data/data_sources/off_data_source.dart';

const _salHost = 'search.openfoodfacts.org';
const _legacyPath = '/cgi/search.pl';

String _legacyBody() => jsonEncode({
      'count': 1,
      'page': 1,
      'page_count': 1,
      'page_size': 100,
      // Classic API key: `products`, not Search-a-licious's `hits`.
      'products': [
        {
          'code': '123',
          'product_name': 'Brot',
          'nutriments': {'energy-kcal_100g': 250},
        },
      ],
    });

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    // OFFDataSource builds its User-Agent from PackageInfo.
    PackageInfo.setMockInitialValues(
      appName: 'ont-test',
      packageName: 'test',
      version: '0.0.0',
      buildNumber: '1',
      buildSignature: '',
    );
  });

  group('OFFDataSource Search-a-licious fallback', () {
    test('a 502 from Search-a-licious falls back to the classic search API',
        () async {
      final requestedUrls = <Uri>[];
      final dataSource = OFFDataSource(
        clientFactory: () => MockClient((request) async {
          requestedUrls.add(request.url);
          if (request.url.host == _salHost) {
            return http.Response('Bad Gateway', 502);
          }
          expect(request.url.path, _legacyPath);
          return http.Response(_legacyBody(), 200);
        }),
      );

      final response = await dataSource.fetchSearchWordResults('brot');

      expect(requestedUrls.first.host, _salHost,
          reason: 'Search-a-licious stays the primary source');
      expect(requestedUrls, hasLength(2));
      expect(response.products, hasLength(1));
      expect(response.products.single.code, '123');
      expect(response.products.single.product_name, 'Brot');
    });

    test(
        'after a failure the circuit breaker skips Search-a-licious for the '
        'cooldown, then probes it again', () async {
      var now = DateTime(2026, 1, 1, 12, 0);
      var salHealthy = false;
      final requestedHosts = <String>[];
      final dataSource = OFFDataSource(
        now: () => now,
        clientFactory: () => MockClient((request) async {
          requestedHosts.add(request.url.host);
          if (request.url.host == _salHost) {
            return salHealthy
                ? http.Response(
                    jsonEncode({
                      'count': 0,
                      'page': 1,
                      'page_count': 0,
                      'page_size': 100,
                      'hits': <Map<String, dynamic>>[],
                    }),
                    200,
                  )
                : http.Response('Bad Gateway', 502);
          }
          return http.Response(_legacyBody(), 200);
        }),
      );

      // First search: probes Search-a-licious, fails, falls back.
      await dataSource.fetchSearchWordResults('brot');
      expect(requestedHosts.where((h) => h == _salHost), hasLength(1));

      // Within the cooldown: straight to the classic API, no dead probe.
      now = now.add(const Duration(minutes: 2));
      await dataSource.fetchSearchWordResults('milch');
      expect(requestedHosts.where((h) => h == _salHost), hasLength(1),
          reason: 'Search-a-licious must not be probed during the cooldown');

      // After the cooldown: probed again, and a healthy answer closes the
      // breaker (the follow-up search goes primary-only).
      now = now.add(const Duration(minutes: 10));
      salHealthy = true;
      await dataSource.fetchSearchWordResults('kaese');
      await dataSource.fetchSearchWordResults('apfel');
      expect(requestedHosts.where((h) => h == _salHost), hasLength(3));
      expect(requestedHosts.last, _salHost);
    });

    test('a healthy Search-a-licious response never hits the fallback',
        () async {
      final requestedUrls = <Uri>[];
      final dataSource = OFFDataSource(
        clientFactory: () => MockClient((request) async {
          requestedUrls.add(request.url);
          expect(request.url.host, _salHost);
          return http.Response(
            jsonEncode({
              'count': 0,
              'page': 1,
              'page_count': 0,
              'page_size': 100,
              'hits': <Map<String, dynamic>>[],
            }),
            200,
          );
        }),
      );

      final response = await dataSource.fetchSearchWordResults('brot');

      expect(requestedUrls, hasLength(1));
      expect(response.products, isEmpty);
    });
  });
}
