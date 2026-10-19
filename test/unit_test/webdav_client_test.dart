import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:opennutritracker/features/settings/data/webdav_client.dart';

void main() {
  final folder = Uri.parse('https://files.example.org/dav/backups/nutri/');
  final requests = <http.Request>[];

  WebDavClient clientAnswering(
    http.Response Function(http.Request request) answer,
  ) {
    requests.clear();
    return WebDavClient(
      MockClient((request) async {
        requests.add(request);
        return answer(request);
      }),
      folder: folder,
      token: 'secret-token',
    );
  }

  test('authenticates with the token as the basic-auth password', () async {
    final client = clientAnswering((_) => http.Response('', 201));

    await client.put('a.zip', [1, 2, 3]);

    final auth = requests.single.headers['Authorization']!;
    expect(auth, startsWith('Basic '));
    expect(
      utf8.decode(base64Decode(auth.substring('Basic '.length))),
      endsWith(':secret-token'),
    );
  });

  test('uploads a file into the folder', () async {
    final client = clientAnswering((_) => http.Response('', 201));

    await client.put('nutritracker-backup-20261019-093000.zip', [1, 2, 3]);

    expect(requests.single.method, 'PUT');
    expect(
      requests.single.url.toString(),
      'https://files.example.org/dav/backups/nutri/nutritracker-backup-20261019-093000.zip',
    );
    expect(requests.single.bodyBytes, [1, 2, 3]);
  });

  test('lists the files of the folder, not the folder itself', () async {
    const multistatus = '''<?xml version="1.0" encoding="UTF-8"?>
<D:multistatus xmlns:D="DAV:">
  <D:response><D:href>/dav/backups/nutri/</D:href></D:response>
  <D:response><D:href>/dav/backups/nutri/nutritracker-backup-20261018-093000.zip</D:href></D:response>
  <D:response><D:href>/dav/backups/nutri/notes%20old.txt</D:href></D:response>
</D:multistatus>''';
    final client = clientAnswering((_) => http.Response(multistatus, 207));

    final names = await client.list();

    expect(requests.single.method, 'PROPFIND');
    expect(requests.single.headers['Depth'], '1');
    expect(names, ['nutritracker-backup-20261018-093000.zip', 'notes old.txt']);
  });

  test('reads lower-case and unprefixed href elements', () async {
    const multistatus =
        '<multistatus xmlns="DAV:">'
        '<response><href>https://files.example.org/dav/backups/nutri/</href></response>'
        '<response><href>https://files.example.org/dav/backups/nutri/b.zip</href></response>'
        '</multistatus>';
    final client = clientAnswering((_) => http.Response(multistatus, 207));

    expect(await client.list(), ['b.zip']);
  });

  test('downloads and deletes a file', () async {
    final client = clientAnswering(
      (request) => request.method == 'GET'
          ? http.Response.bytes([9, 8], 200)
          : http.Response('', 204),
    );

    expect(await client.get('b.zip'), [9, 8]);
    await client.delete('b.zip');

    expect(requests.map((r) => r.method), ['GET', 'DELETE']);
  });

  test('creates the folder when it is missing', () async {
    final client = clientAnswering(
      (request) => request.method == 'PROPFIND'
          ? http.Response('', 404)
          : http.Response('', 201),
    );

    await client.ensureFolder();

    expect(requests.map((r) => r.method), ['PROPFIND', 'MKCOL']);
  });

  test('a rejected token is reported as unauthorized', () async {
    final client = clientAnswering((_) => http.Response('', 401));

    await expectLater(
      client.list(),
      throwsA(
        isA<WebDavException>().having((e) => e.isUnauthorized, 'auth', isTrue),
      ),
    );
  });

  test('any other failure carries its status code', () async {
    final client = clientAnswering((_) => http.Response('', 507));

    await expectLater(
      client.put('a.zip', [1]),
      throwsA(isA<WebDavException>().having((e) => e.statusCode, 'code', 507)),
    );
  });

  test('refuses an address that is not https', () {
    expect(
      () => WebDavClient(
        MockClient((_) async => http.Response('', 200)),
        folder: Uri.parse('http://files.example.org/dav/'),
        token: 't',
      ),
      throwsArgumentError,
    );
  });

  test('gives up on a server that stops answering', () async {
    final client = WebDavClient(
      MockClient((_) => Completer<http.Response>().future),
      folder: folder,
      token: 't',
      timeout: const Duration(milliseconds: 20),
    );

    await expectLater(client.list(), throwsA(isA<TimeoutException>()));
  });
}
