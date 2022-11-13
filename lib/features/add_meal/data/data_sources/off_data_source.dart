import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';
import 'package:opennutritracker/core/utils/off_const.dart';
import 'package:opennutritracker/features/addItem/data/dto/off_product_response.dart';
import 'package:opennutritracker/features/addItem/data/dto/off_word_response.dart';

class OFFDataSource {
  final log = Logger('OFFDataSource');

  Future<OFFWordResponse> fetchSearchWordResults(String searchString) async {
    try {
      final searchUrlString = OFFConst.getOffWordSearchUrl(searchString);

      final response = await http.get(searchUrlString);
      log.fine('Fetching OFF results from: $searchUrlString');
      if (response.statusCode == OFFConst.offHttpSuccessCode) {
        final wordResponse =
            OFFWordResponse.fromJson(jsonDecode(response.body));
        log.fine('Successful response from OFF');
        return wordResponse;
      } else {
        log.warning('Failed OFF call: ${response.statusCode}');
        return Future.error(response.statusCode);
      }
    } catch (error) {
      log.severe('Exception while getting OFF word search $error');
      return Future.error(error);
    }
  }

  Future<OFFProductResponse> fetchBarcodeResults(String barcode) async {
    try {
      final searchUrl = OFFConst.getOffBarcodeSearchUri(barcode);

      final response = await http.get(searchUrl);
      log.fine('Fetching OFF result from: $searchUrl');
      if (response.statusCode == OFFConst.offHttpSuccessCode) {
        final productResponse =
            OFFProductResponse.fromJson(jsonDecode(response.body));
        log.fine('Successful response from OFF');
        return productResponse;
      } else {
        log.warning('Failed OFF call: ${response.statusCode}');
        return Future.error(response.statusCode);
      }
    } catch (error) {
      log.severe('Exception while getting OFF barcode search $error');
      return Future.error(error);
    }
  }
}
