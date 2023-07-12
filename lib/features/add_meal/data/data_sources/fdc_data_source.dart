import 'dart:convert';

import 'package:logging/logging.dart';

import 'package:http/http.dart' as http;
import 'package:opennutritracker/core/utils/env.dart';
import 'package:opennutritracker/features/add_meal/data/dto/fdc/fdc_const.dart';
import 'package:opennutritracker/features/add_meal/data/dto/fdc/fdc_word_response_dto.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

class FDCDataSource {
  static const _timeoutDuration = Duration(seconds: 10);
  final log = Logger('FDCDataSource');

  Future<FDCWordResponseDTO> fetchSearchWordResults(String searchString) async {
    try {
      final searchUrlString =
          FDCConst.getFDCWordSearchUrl(searchString, Env.fdcApiKey);

      final response =
          await http.get(searchUrlString).timeout(_timeoutDuration);
      log.fine('Fetching FDC results from: $searchUrlString');

      final wordResponse = FDCWordResponseDTO.fromJson(jsonDecode(response.body));
      log.fine('Successful response from FDC');
      return wordResponse;
    } catch (exception, stacktrace) {
      log.severe('Exception while getting FDC word search $exception');
      Sentry.captureException(exception, stackTrace: stacktrace);
      return Future.error(exception);
    }
  }
}
