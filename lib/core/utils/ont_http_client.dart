import 'package:http/http.dart' as http;

class ONTHttpClient extends http.BaseClient {
  final String userAgent;
  final http.Client _client;

  ONTHttpClient(this.userAgent, this._client);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    request.headers['User-Agent'] = userAgent;
    return _client.send(request);
  }
}
