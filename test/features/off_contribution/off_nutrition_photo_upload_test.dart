import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:opennutritracker/features/off_contribution/data/off_contribution_client.dart';
import 'package:opennutritracker/features/off_contribution/data/off_contribution_settings.dart';

void main() {
  late http.Request sent;

  OffContributionClient client(http.Response Function() answer) =>
      OffContributionClient(
        userAgent: 'NutriTracker test',
        client: MockClient((request) async {
          sent = request;
          return answer();
        }),
      );

  const settings = OffContributionSettings(
    enabled: true,
    userId: 'theo',
    password: 's3cret',
  );

  Future<void> upload(
    OffContributionClient c, {
    OffContributionSettings s = settings,
  }) => c.uploadNutritionPhoto(s, '20697112', const [1, 2, 3], 'label.jpg');

  http.Response ok() =>
      http.Response(jsonEncode({'status': 'status ok', 'imgid': 3}), 200);

  test('posts the photo as the German nutrition image', () async {
    await upload(client(ok));

    expect(sent.method, 'POST');
    expect(sent.url.host, 'world.openfoodfacts.net');
    expect(sent.url.path, '/cgi/product_image_upload.pl');
    expect(sent.headers['User-Agent'], 'NutriTracker test');
    expect(sent.headers['Authorization'], startsWith('Basic '));
    expect(sent.headers['content-type'], startsWith('multipart/form-data'));
    final body = latin1.decode(sent.bodyBytes);
    for (final (name, value) in [
      ('code', '20697112'),
      ('user_id', 'theo'),
      ('password', 's3cret'),
      ('imagefield', 'nutrition_de'),
    ]) {
      expect(body, contains('name="$name"\r\n\r\n$value\r\n'));
    }
    expect(
      body,
      contains('name="imgupload_nutrition_de"; filename="label.jpg"'),
    );
    expect(body, contains(String.fromCharCodes(const [1, 2, 3])));
  });

  test('goes to the real database when the test server is off', () async {
    await upload(
      client(ok),
      s: const OffContributionSettings(
        enabled: true,
        userId: 'theo',
        password: 's3cret',
        useTestServer: false,
      ),
    );

    expect(sent.url.host, 'world.openfoodfacts.org');
    expect(sent.headers['Authorization'], isNull);
  });

  test('an uploaded photo that was not selected still counts', () async {
    await upload(
      client(
        () => http.Response(
          jsonEncode({'status': 'status not ok', 'imgid': 7}),
          200,
        ),
      ),
    );
  });

  test('a photo the server did not take is rejected', () async {
    expect(
      () => upload(
        client(
          () => http.Response(
            jsonEncode({'status': 'status not ok', 'debug': 'too small'}),
            200,
          ),
        ),
      ),
      throwsA(
        isA<OffContributionException>().having(
          (e) => e.failure,
          'failure',
          OffContributionFailure.rejected,
        ),
      ),
    );
  });

  test('a busy server reads as busy', () async {
    expect(
      () => upload(client(() => http.Response('', 503))),
      throwsA(
        isA<OffContributionException>().having(
          (e) => e.failure,
          'failure',
          OffContributionFailure.serverBusy,
        ),
      ),
    );
  });
}
