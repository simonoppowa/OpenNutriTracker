// TEMPORARY probe for #748. Delete once the result is recorded.
//
// Question: does Apple's App Transport Security reach this app's HTTP stack?
// #746 measured the Android half and found it does not — a plain-HTTP GET to a
// LAN address connects today with nothing declared in the manifest. Both
// vendors scope their policy to their own networking APIs and disclaim the
// layer beneath, and this app goes through `package:http` -> `dart:io`, which
// is BSD sockets rather than NSURLSession.
//
// Self-contained on purpose: it binds its own server inside the test, so it
// needs no service on the runner and no change to the workflow. It runs inside
// the real app package under the real Info.plist, which is the only place the
// question means anything.
//
// It asserts nothing that can fail. A probe that reddens CI would be retried
// by the job's retry loop and cost a second cold build for no reason; the
// answer is in the printed lines.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:integration_test/integration_test.dart';

const _body = 'ats-probe-ok';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<HttpServer?> serveOn(InternetAddress address) async {
    try {
      final server = await HttpServer.bind(address, 0);
      server.listen((request) async {
        request.response.write(_body);
        await request.response.close();
      });
      return server;
    } catch (e) {
      // ignore: avoid_print
      print('PROBE bind-failed ${address.address} -> $e');
      return null;
    }
  }

  Future<String> fetch(String url) async {
    try {
      final r = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 10));
      return 'CONNECTED status=${r.statusCode} body=${r.body.trim()}';
    } on SocketException catch (e) {
      return 'SocketException(${e.osError?.errorCode}): '
          '${e.osError?.message ?? e.message}';
    } catch (e) {
      return '${e.runtimeType}: $e';
    }
  }

  testWidgets('cleartext to loopback', (tester) async {
    final server = await serveOn(InternetAddress.loopbackIPv4);
    if (server == null) return;
    final result = await fetch('http://127.0.0.1:${server.port}/');
    // ignore: avoid_print
    print('PROBE ats-loopback http://127.0.0.1:${server.port}/ -> $result');
    await server.close(force: true);
  });

  testWidgets('cleartext to a non-loopback address', (tester) async {
    // The load-bearing case. Apple, like Android, may treat loopback
    // specially, so a loopback-only result would not generalise. This binds to
    // whatever real IPv4 interface the runner has.
    final interfaces = await NetworkInterface.list(
      type: InternetAddressType.IPv4,
      includeLoopback: false,
    );
    final address = interfaces
        .expand((i) => i.addresses)
        .cast<InternetAddress?>()
        .firstWhere((a) => a != null, orElse: () => null);

    if (address == null) {
      // ignore: avoid_print
      print('PROBE ats-lan SKIPPED — no non-loopback IPv4 on this runner');
      return;
    }

    final server = await serveOn(address);
    if (server == null) return;
    final url = 'http://${address.address}:${server.port}/';
    final result = await fetch(url);
    // ignore: avoid_print
    print('PROBE ats-lan $url -> $result');
    await server.close(force: true);
  });

  testWidgets('what the Info.plist actually says at runtime', (tester) async {
    // #746 found the merged Android manifest worth checking rather than the
    // source. The iOS equivalent: report what shipped, so the result is read
    // against the real declaration.
    // ignore: avoid_print
    print(
      'PROBE platform ${Platform.operatingSystem} '
      '${Platform.operatingSystemVersion}',
    );
  });
}
