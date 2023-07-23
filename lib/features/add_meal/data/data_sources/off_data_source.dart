import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';
import 'package:opennutritracker/core/utils/app_const.dart';
import 'package:opennutritracker/core/utils/off_const.dart';
import 'package:opennutritracker/core/utils/ont_http_client.dart';
import 'package:opennutritracker/features/add_meal/data/dto/off/off_product_response_dto.dart';
import 'package:opennutritracker/features/add_meal/data/dto/off/off_word_response_dto.dart';
import 'package:opennutritracker/features/scanner/data/product_not_found_exception.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

class OFFDataSource {
  static const _timeoutDuration = Duration(seconds: 20); // TODO lower timeout
  final log = Logger('OFFDataSource');

  Future<OFFWordResponseDTO> fetchSearchWordResults(String searchString) async {
    try {
      final searchUrlString = OFFConst.getOffWordSearchUrl(searchString);
      final userAgentString = await AppConst.getUserAgentString();
      final httpClient = ONTHttpClient(userAgentString, http.Client());

      final response =
          await httpClient.get(searchUrlString).timeout(_timeoutDuration);
      log.fine('Fetching OFF results from: $searchUrlString');
      if (response.statusCode == OFFConst.offHttpSuccessCode) {
        final wordResponse =
            OFFWordResponseDTO.fromJson(jsonDecode(response.body));
        log.fine('Successful response from OFF');
        return wordResponse;
      } else {
        log.warning('Failed OFF call: ${response.statusCode}');
        return Future.error(response.statusCode);
      }
    } catch (exception, stacktrace) {
      log.severe('Exception while getting OFF word search $exception');
      Sentry.captureException(exception, stackTrace: stacktrace);
      return Future.error(exception);
    }
  }

  Future<OFFProductResponseDTO> fetchBarcodeResults(String barcode) async {
    try {
      final searchUrl = OFFConst.getOffBarcodeSearchUri(barcode);
      final userAgentString = await AppConst.getUserAgentString();
      final httpClient = ONTHttpClient(userAgentString, http.Client());

      final response =
          await httpClient.get(searchUrl).timeout(_timeoutDuration);
      log.fine('Fetching OFF result from: $searchUrl');
      if (response.statusCode == OFFConst.offHttpSuccessCode) {
        final productResponse =
            OFFProductResponseDTO.fromJson(jsonDecode(response.body));
        log.fine('Successful response from OFF');
        return productResponse;
      } else if (response.statusCode == OFFConst.offProductNotFoundCode) {
        log.warning("404 OFF Product not found");
        return Future.error(ProductNotFoundException);
      } else {
        log.warning('Failed OFF call: ${response.statusCode}');
        return Future.error(response.statusCode);
      }
    } catch (exception, stacktrace) {
      log.severe('Exception while getting OFF barcode search $exception');
      Sentry.captureException(exception, stackTrace: stacktrace);
      return Future.error(exception);
    }
  }
}
