import 'package:http/http.dart' as http;
import 'package:opennutritracker/core/utils/off_const.dart';

class OFFDataSource {
  Future<void> fetchSearchWordResults(String searchString) async {
    try {
      final response =
          await http.get(OFFConst.getOffWordSearchUrl(searchString));

      if(response.statusCode == OFFConst.offHttpSuccessCode) {

      } else {
        return Future.error('Error while fetching');
      }

      print(response.body);


    } catch (error) {
      return Future.error(error);
    }
  }
}
