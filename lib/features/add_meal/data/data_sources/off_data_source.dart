import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';
import 'package:opennutritracker/core/utils/app_const.dart';
import 'package:opennutritracker/core/utils/off_const.dart';
import 'package:opennutritracker/core/utils/ont_http_client.dart';
import 'package:opennutritracker/core/utils/retry_util.dart';
import 'package:opennutritracker/core/utils/supported_language.dart';
import 'package:opennutritracker/features/add_meal/data/dto/off/off_product_response_dto.dart';
import 'package:opennutritracker/features/add_meal/data/dto/off/off_word_response_dto.dart';
import 'package:opennutritracker/features/scanner/data/product_not_found_exception.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

class OFFDataSource {
  static const _timeoutDuration = Duration(seconds: 60);

  /// How long to skip Search-a-licious after a failure before probing it
  /// again. Its outages historically last hours, and every probe of a dead
  /// service costs the user a ~2 s wait before the fallback kicks in — so
  /// during the cooldown searches go straight to the classic API.
  static const _salCooldown = Duration(minutes: 5);

  final log = Logger('OFFDataSource');

  /// Injectable for tests; production uses a fresh client per call, matching
  /// the previous behaviour.
  final http.Client Function() _clientFactory;

  /// Injectable clock for testing the Search-a-licious cooldown.
  final DateTime Function() _now;

  /// End of the current Search-a-licious cooldown, null when the service
  /// is considered healthy. Instance state — the data source is a locator
  /// singleton, so the breaker spans searches.
  DateTime? _skipSalUntil;

  OFFDataSource({
    http.Client Function()? clientFactory,
    DateTime Function()? now,
  })  : _clientFactory = clientFactory ?? http.Client.new,
        _now = now ?? DateTime.now;

  /// The device language as a Search-a-licious relevance context, always with
  /// English appended as a fallback so non-English locales still match the
  /// large English-only slice of the catalogue.
  String _searchLangs() {
    final lang = SupportedLanguage.fromCode(Platform.localeName).name;
    return lang == 'en' ? 'en' : '$lang,en';
  }

  Future<OFFWordResponseDTO> fetchSearchWordResults(String searchString) async {
    try {
      return await withRetry(() async {
        // Search-a-licious runs on its own infrastructure and goes down
        // independently of the main OFF site — its 502s can last hours.
        // After a failure the circuit breaker sends searches straight to
        // the classic API for [_salCooldown] instead of paying the dead
        // round-trip on every keystroke, then probes again.
        final skipUntil = _skipSalUntil;
        final salInCooldown = skipUntil != null && _now().isBefore(skipUntil);
        if (!salInCooldown) {
          try {
            final result = await _fetchWordResults(
              OFFConst.getOffWordSearchUrl(searchString, langs: _searchLangs()),
            );
            _skipSalUntil = null;
            return result;
          } catch (error) {
            _skipSalUntil = _now().add(_salCooldown);
            log.warning(
              'Search-a-licious failed ($error); using the classic OFF '
              'search API for the next ${_salCooldown.inMinutes} minutes',
            );
          }
        }
        return await _fetchWordResults(
          OFFConst.getOffLegacyWordSearchUrl(searchString),
        );
      });
    } catch (exception, stacktrace) {
      log.severe('Exception while getting OFF word search $exception');
      Sentry.captureException(exception, stackTrace: stacktrace);
      return Future.error(exception);
    }
  }

  Future<OFFWordResponseDTO> _fetchWordResults(Uri searchUrl) async {
    final userAgentString = await AppConst.getUserAgentString();
    final httpClient = ONTHttpClient(userAgentString, _clientFactory());
    final response =
        await httpClient.get(searchUrl).timeout(_timeoutDuration);
    log.fine('Fetching OFF results from: $searchUrl');
    if (response.statusCode == OFFConst.offHttpSuccessCode) {
      final wordResponse = OFFWordResponseDTO.fromJson(
        jsonDecode(response.body),
      );
      log.fine('Successful response from OFF');
      return wordResponse;
    }
    log.warning('Failed OFF call: ${response.statusCode}');
    throw Exception('OFF HTTP ${response.statusCode}');
  }

  Future<OFFProductResponseDTO> fetchBarcodeResults(String barcode) async {
    try {
      return await withRetry(
        () async {
          final searchUrl = OFFConst.getOffBarcodeSearchUri(barcode);
          final userAgentString = await AppConst.getUserAgentString();
          final httpClient = ONTHttpClient(userAgentString, _clientFactory());
          final response =
              await httpClient.get(searchUrl).timeout(_timeoutDuration);
          log.fine('Fetching OFF result from: $searchUrl');
          if (response.statusCode == OFFConst.offHttpSuccessCode) {
            final productResponse = OFFProductResponseDTO.fromJson(
              jsonDecode(response.body),
            );
            log.fine('Successful response from OFF');
            return productResponse;
          } else if (response.statusCode == OFFConst.offProductNotFoundCode) {
            log.warning('404 OFF Product not found');
            throw ProductNotFoundException();
          }
          log.warning('Failed OFF call: ${response.statusCode}');
          throw Exception('OFF HTTP ${response.statusCode}');
        },
        shouldRetry: (e) => e is! ProductNotFoundException,
      );
    } catch (exception, stacktrace) {
      log.severe('Exception while getting OFF barcode search $exception');
      Sentry.captureException(exception, stackTrace: stacktrace);
      return Future.error(exception);
    }
  }
}
