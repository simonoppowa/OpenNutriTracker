import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:opennutritracker/features/off_contribution/data/off_contribution_settings.dart';
import 'package:opennutritracker/features/off_contribution/domain/off_nutrition_upload.dart';

/// Why an upload to Open Food Facts did not go through.
enum OffContributionFailure { offline, rejected, serverBusy }

class OffContributionException implements Exception {
  final OffContributionFailure failure;

  const OffContributionException(this.failure);

  @override
  String toString() => 'OffContributionException($failure)';
}

/// Writes nutrition values to Open Food Facts through its product write
/// form (`/cgi/product_jqm2.pl`), on the test server unless the settings
/// say otherwise. The test server sits behind the basic auth `off:off`
/// that Open Food Facts publishes for it.
class OffContributionClient {
  static const _testHost = 'world.openfoodfacts.net';
  static const _productionHost = 'world.openfoodfacts.org';
  static const _timeout = Duration(seconds: 20);

  final String _userAgent;
  final http.Client _client;

  OffContributionClient({required String userAgent, http.Client? client})
    : _userAgent = userAgent,
      _client = client ?? http.Client();

  /// Whether Open Food Facts already has any of the values an upload would
  /// write for [barcode]; an unknown product has none.
  Future<bool> hasNutritionValues(
    OffContributionSettings settings,
    String barcode,
  ) async {
    final response = await _send(
      http.Request(
        'GET',
        Uri.https(_host(settings), '/api/v2/product/$barcode', {
          'fields': 'nutriments',
        }),
      ),
      settings,
    );
    if (response.statusCode == 404) return false;
    _throwOnServerError(response);
    final body = _decode(response);
    final product = body is Map<String, dynamic> ? body['product'] : null;
    final nutriments = product is Map<String, dynamic>
        ? product['nutriments']
        : null;
    if (nutriments is! Map<String, dynamic>) return false;
    return const [
      'energy-kcal_100g',
      'energy_100g',
      'fat_100g',
      'saturated-fat_100g',
      'carbohydrates_100g',
      'sugars_100g',
      'fiber_100g',
      'proteins_100g',
      'salt_100g',
      'sodium_100g',
    ].any((key) => nutriments[key] != null);
  }

  /// Sends [upload] as [settings]' user. Throws an
  /// [OffContributionException].
  Future<void> upload(
    OffContributionSettings settings,
    OffNutritionUpload upload,
  ) async {
    final request =
        http.Request('POST', Uri.https(_host(settings), '/cgi/product_jqm2.pl'))
          ..bodyFields = {
            'code': upload.barcode,
            'user_id': settings.userId,
            'password': settings.password,
            ...upload.fields,
          };
    final response = await _send(request, settings);
    _throwOnServerError(response);
    final body = _decode(response);
    if (body is! Map<String, dynamic> || body['status'] != 1) {
      throw const OffContributionException(OffContributionFailure.rejected);
    }
  }

  String _host(OffContributionSettings settings) =>
      settings.useTestServer ? _testHost : _productionHost;

  Future<http.Response> _send(
    http.Request request,
    OffContributionSettings settings,
  ) async {
    request.headers['User-Agent'] = _userAgent;
    if (settings.useTestServer) {
      request.headers['Authorization'] =
          'Basic ${base64Encode(utf8.encode('off:off'))}';
    }
    try {
      return await _client
          .send(request)
          .then(http.Response.fromStream)
          .timeout(_timeout);
    } on Exception {
      throw const OffContributionException(OffContributionFailure.offline);
    }
  }

  /// The JSON body, or null when the server answered with something else
  /// (an HTML error page, for one).
  Object? _decode(http.Response response) {
    try {
      return jsonDecode(response.body);
    } on FormatException {
      return null;
    }
  }

  void _throwOnServerError(http.Response response) {
    if (response.statusCode == 401 || response.statusCode == 403) {
      throw const OffContributionException(OffContributionFailure.rejected);
    }
    if (response.statusCode == 429 || response.statusCode >= 500) {
      throw const OffContributionException(OffContributionFailure.serverBusy);
    }
    if (response.statusCode != 200) {
      throw const OffContributionException(OffContributionFailure.rejected);
    }
  }
}
