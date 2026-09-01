import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:opennutritracker/core/utils/plaintext_destination_guard.dart';

/// Records the request that reached the socket, or the fact that none did.
///
/// [sentCount] records how many times [GuardedPlaintextClient] called through.
/// It cannot see a redirect being followed — that happens inside `dart:io`,
/// below this fake — so it pins that the guard itself sends once, and nothing
/// more than that.
class _RecordingClient extends http.BaseClient {
  http.BaseRequest? sent;
  int sentCount = 0;

  /// Returned instead of a bare 200 when a test needs a specific status —
  /// a 30x, for the redirect cases.
  final http.StreamedResponse? response;

  _RecordingClient({this.response});

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    sent = request;
    sentCount++;
    // The injected response keeps the request association too, so an
    // assertion on `response.request` reads the same either way.
    final canned = response;
    if (canned != null) {
      return http.StreamedResponse(
        canned.stream,
        canned.statusCode,
        headers: canned.headers,
        request: request,
      );
    }
    return http.StreamedResponse(const Stream.empty(), 200, request: request);
  }
}

InternetAddress _v4(String s) => InternetAddress(s, type: InternetAddressType.IPv4);
InternetAddress _v6(String s) => InternetAddress(s, type: InternetAddressType.IPv6);

/// The only thing standing between the feature and plaintext health data
/// crossing the internet.
///
/// #746 and #748 measured that neither platform blocks cleartext for this
/// app's stack — `dart:io` is BSD sockets, not NSURLSession, so ATS and
/// Android's cleartext policy never see these requests. There is no second
/// line of defence behind these tests.
void main() {
  group('what counts as private', () {
    test('the RFC 1918 ranges, at their edges', () {
      for (final address in [
        '10.0.0.0', '10.255.255.255',
        '172.16.0.0', '172.31.255.255',
        '192.168.0.0', '192.168.255.255',
      ]) {
        expect(isPrivateDestination(_v4(address)), isTrue, reason: address);
      }
    });

    test('and the addresses just outside them', () {
      // 172.15 and 172.32 bracket the /12. Getting this wrong by one octet
      // is the classic version of this bug and it fails open.
      for (final address in [
        '11.0.0.0', '172.15.255.255', '172.32.0.0', '192.167.255.255',
        '192.169.0.0', '8.8.8.8', '1.1.1.1',
      ]) {
        expect(isPrivateDestination(_v4(address)), isFalse, reason: address);
      }
    });

    test('loopback and link-local, both families', () {
      expect(isPrivateDestination(_v4('127.0.0.1')), isTrue);
      expect(isPrivateDestination(_v4('169.254.1.1')), isTrue);
      expect(isPrivateDestination(_v6('::1')), isTrue);
      expect(isPrivateDestination(_v6('fe80::1')), isTrue);
    });

    test('IPv6 unique-local, and global-scope v6 is not', () {
      expect(isPrivateDestination(_v6('fd00::1')), isTrue);
      expect(isPrivateDestination(_v6('fc00::1')), isTrue);
      // A global address from the measured dual-stack case.
      expect(isPrivateDestination(_v6('2001:db8::1')), isFalse);
      expect(isPrivateDestination(_v6('2606:4700::1111')), isFalse);
    });

    test('an IPv4-mapped v6 address is judged as the v4 it is', () {
      // `::ffff:192.168.1.5` is a LAN destination wearing a v6 shape. Reading
      // its v6 bytes would call it public, which is the mirror image of the
      // bug this whole check exists to prevent.
      expect(isPrivateDestination(_v6('::ffff:192.168.1.5')), isTrue);
      expect(isPrivateDestination(_v6('::ffff:8.8.8.8')), isFalse);
    });
  });

  group('what may actually be sent', () {
    PlaintextDestinationGuard guardResolving(List<InternetAddress> answers) =>
        PlaintextDestinationGuard(lookup: (_) async => answers);

    test('https goes anywhere, untouched', () async {
      // The rule is about plaintext, not about remoteness: a rented box with
      // TLS is squarely inside what this provider is for. And the URL must
      // come back unchanged, because rewriting the host would break SNI and
      // name-based virtual hosting.
      final url = Uri.parse('https://ollama.example.com/v1/chat/completions');
      final guard = guardResolving([_v4('93.184.216.34')]);

      expect(await guard.approve(url), url);
    });

    test('a private literal is allowed and left alone', () async {
      final url = Uri.parse('http://192.168.1.5:11434/v1/chat/completions');

      expect(await PlaintextDestinationGuard().approve(url), url);
    });

    test('a public literal is refused', () async {
      final url = Uri.parse('http://93.184.216.34:11434/v1/chat/completions');

      await expectLater(
        PlaintextDestinationGuard().approve(url),
        throwsA(isA<InsecureDestinationException>()),
      );
    });

    test('a name resolving privately is pinned to that address', () async {
      // The gap this closes: checking a name and then handing the name back
      // to the socket layer leaves a second lookup free to answer
      // differently. The request goes to the address that was approved.
      final guard = guardResolving([_v4('192.168.1.5')]);

      final approved = await guard.approve(
        Uri.parse('http://ollama.lan:11434/v1/chat/completions'),
      );

      expect(approved.host, '192.168.1.5');
      expect(approved.port, 11434);
      expect(approved.path, '/v1/chat/completions');
    });

    test('a name resolving only to a public v6 is refused', () async {
      // A measured dual-stack case:
      // `example-server.home.arpa` reverse-resolves to 192.168.1.46, but
      // its forward lookup returns only a global-scope v6. An IPv4-only
      // check would never see where the connection actually went.
      final guard = guardResolving([_v6('2001:db8::1')]);

      await expectLater(
        guard.approve(Uri.parse('http://example-server.home.arpa:11434/v1')),
        throwsA(isA<InsecureDestinationException>()),
      );
    });

    test('a private v6 is honoured even when a public v4 answers too', () async {
      // Both families are considered, and the private answer wins — the app
      // is about to prove the claim by connecting there.
      final guard = guardResolving([_v4('93.184.216.34'), _v6('fd00::5')]);

      final approved = await guard.approve(
        Uri.parse('http://ollama.lan:11434/v1'),
      );

      expect(approved.host, isNot('93.184.216.34'));
      expect(InternetAddress.tryParse(approved.host)?.type,
          InternetAddressType.IPv6);
    });

    test('a name that does not resolve is not a policy refusal', () async {
      // Telling someone their address is unsafe when it is merely
      // unreachable sends them to fix the wrong thing.
      final guard = PlaintextDestinationGuard(
        lookup: (_) async => throw const SocketException('no such host'),
      );

      await expectLater(
        guard.approve(Uri.parse('http://nowhere.lan:11434/v1')),
        throwsA(isA<SocketException>()),
      );
    });

    test('an empty answer is refused rather than sent hopefully', () async {
      final guard = guardResolving([]);

      await expectLater(
        guard.approve(Uri.parse('http://ollama.lan:11434/v1')),
        throwsA(isA<InsecureDestinationException>()),
      );
    });

    test('the request is rebuilt against the approved address', () async {
      // Not just checked and waved through: the socket connects to the
      // address the check approved, and the original name rides in the Host
      // header so a name-based server still routes it.
      final inner = _RecordingClient();
      final client = GuardedPlaintextClient(
        inner,
        guard: PlaintextDestinationGuard(
          lookup: (_) async => [_v4('192.168.1.5')],
        ),
      );

      await client.post(
        Uri.parse('http://ollama.lan:11434/v1/chat/completions'),
        body: 'payload',
        headers: {'content-type': 'application/json'},
      );

      expect(inner.sent!.url.host, '192.168.1.5');
      // With the port. `ollama.lan` alone is a different authority from the
      // `ollama.lan:11434` that was typed, and a local model server is
      // essentially never on 80, so dropping it is the common case rather
      // than the corner one.
      expect(inner.sent!.headers['host'], 'ollama.lan:11434');
      expect(inner.sent!.headers['content-type'], 'application/json');
      expect((inner.sent! as http.Request).body, 'payload');
    });

    test('a URL without a port sends the bare name, not a redundant :80',
        () async {
      final inner = _RecordingClient();
      final client = GuardedPlaintextClient(
        inner,
        guard: PlaintextDestinationGuard(
          lookup: (_) async => [_v4('192.168.1.5')],
        ),
      );

      await client.post(Uri.parse('http://ollama.lan/v1'), body: 'payload');

      expect(inner.sent!.headers['host'], 'ollama.lan');
    });

    test('an https request reaches the socket untouched', () async {
      final inner = _RecordingClient();
      final client = GuardedPlaintextClient(inner);
      final url = Uri.parse('https://ollama.example.com/v1/chat/completions');

      await client.post(url, body: 'payload');

      expect(inner.sent!.url, url);
      expect(inner.sent!.headers.containsKey('host'), isFalse);
    });

    test('a refused request never reaches the socket at all', () async {
      // The point of the whole exercise: the bytes do not leave.
      final inner = _RecordingClient();
      final client = GuardedPlaintextClient(
        inner,
        guard: PlaintextDestinationGuard(
          lookup: (_) async => [_v4('93.184.216.34')],
        ),
      );

      await expectLater(
        client.post(Uri.parse('http://ollama.lan:11434/v1'), body: 'payload'),
        throwsA(isA<InsecureDestinationException>()),
      );
      expect(inner.sent, isNull);
    });

    test('redirects are not followed, on the rebound path', () async {
      // The gap this closes: `dart:io` follows a 30x below `BaseClient.send`,
      // so the hop never re-enters the guard. A private server answering with
      // a public `http://` Location would have had that connection made, out
      // of a check that reported the destination private.
      final inner = _RecordingClient();
      final client = GuardedPlaintextClient(
        inner,
        guard: PlaintextDestinationGuard(
          lookup: (_) async => [_v4('192.168.1.5')],
        ),
      );

      await client.post(
        Uri.parse('http://ollama.lan:11434/v1/chat/completions'),
        body: 'payload',
      );

      expect(inner.sent!.followRedirects, isFalse);
    });

    test('redirects are not followed on the https pass-through either', () async {
      // `approve` waves https straight through, so the pass-through branch
      // needs its own guarantee: an encrypted first hop says nothing about
      // where a `Location` header points.
      final inner = _RecordingClient();
      final client = GuardedPlaintextClient(inner);

      await client.post(
        Uri.parse('https://ollama.example.com/v1/chat/completions'),
        body: 'payload',
      );

      expect(inner.sent!.followRedirects, isFalse);
    });

    test('a 30x comes back to the caller as a response, not a second hop', () async {
      // Contract, not regression: the following happens inside `dart:io`,
      // below this fake, so this test passes with or without the fix above.
      // It pins what a caller sees — a 30x surfacing rather than being
      // swallowed — while the two tests above are the ones that fail if
      // `followRedirects` is ever turned back on.
      final inner = _RecordingClient(
        response: http.StreamedResponse(
          const Stream.empty(),
          302,
          headers: {'location': 'http://93.184.216.34/v1/chat/completions'},
        ),
      );
      final client = GuardedPlaintextClient(
        inner,
        guard: PlaintextDestinationGuard(
          lookup: (_) async => [_v4('192.168.1.5')],
        ),
      );

      final response = await client.post(
        Uri.parse('http://ollama.lan:11434/v1/chat/completions'),
        body: 'payload',
      );

      // Surfaced rather than chased. The caller sees a failed request; what
      // it does not see is a payload delivered to 93.184.216.34.
      expect(response.statusCode, 302);
      expect(inner.sentCount, 1);
    });

    test('the exception names the host and nothing else', () async {
      // Raised on a request that may be carrying a photograph of somebody's
      // dinner. The path and body must not reach a log through it.
      final guard = guardResolving([_v4('93.184.216.34')]);

      try {
        await guard.approve(
          Uri.parse('http://ollama.lan:11434/v1/chat?note=zzq-private-zzq'),
        );
        fail('expected a refusal');
      } on InsecureDestinationException catch (e) {
        expect(e.toString(), contains('ollama.lan'));
        expect(e.toString(), isNot(contains('zzq-private-zzq')));
      }
    });
  });

  /// The claims above are made against a fake, which cannot follow a redirect
  /// — `dart:io` does that below `BaseClient.send`, where no fake reaches. So
  /// these run against a real `HttpServer` on loopback and a real `dart:io`
  /// client, which is the only place the redirect rule is actually decided.
  group('against a real socket', () {
    late HttpServer server;
    late List<String> paths;
    late List<String?> hosts;
    HttpOverrides? savedOverrides;

    setUp(() async {
      // `flutter_test` installs an override that answers every request with a
      // canned 400 rather than opening a socket. These tests are about what
      // the socket layer really does, so they need it out of the way — and
      // put back, because the rest of the suite may rely on it.
      savedOverrides = HttpOverrides.current;
      HttpOverrides.global = null;

      paths = [];
      hosts = [];
      server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      server.listen((request) async {
        paths.add(request.uri.path);
        hosts.add(request.headers.value('host'));
        if (request.uri.path == '/first') {
          request.response.statusCode = HttpStatus.found;
          request.response.headers.set('location', '/second');
        } else {
          request.response.statusCode = HttpStatus.ok;
        }
        await request.response.close();
      });
    });

    tearDown(() async {
      await server.close(force: true);
      HttpOverrides.global = savedOverrides;
    });

    test('an unguarded client really does follow the redirect', () async {
      // The control. Without it the two tests below prove nothing: they would
      // pass just as well against a server that never redirected, or a client
      // stack that had stopped following redirects on its own.
      final client = http.Client();
      addTearDown(client.close);

      final response =
          await client.get(Uri.parse('http://127.0.0.1:${server.port}/first'));

      expect(paths, ['/first', '/second']);
      expect(response.statusCode, 200);
    });

    test('the guarded client stops at the 30x — literal pass-through',
        () async {
      // A private literal is waved through `approve` untouched, so this is
      // the branch where the request object reaches the socket as the caller
      // built it. `followRedirects` still has to have been turned off.
      final client = GuardedPlaintextClient(http.Client());
      addTearDown(client.close);

      final response =
          await client.get(Uri.parse('http://127.0.0.1:${server.port}/first'));

      expect(paths, ['/first']);
      expect(response.statusCode, 302);
      expect(response.headers['location'], '/second');
    });

    test('the guarded client stops at the 30x — rebound path', () async {
      // The same claim on the other branch: a name pinned to its resolved
      // address, rebuilt into a new request. The rebuild must not hand back a
      // request that follows redirects.
      final client = GuardedPlaintextClient(
        http.Client(),
        guard: PlaintextDestinationGuard(
          lookup: (_) async => [_v4('127.0.0.1')],
        ),
      );
      addTearDown(client.close);

      final response = await client
          .get(Uri.parse('http://ollama.lan:${server.port}/first'));

      expect(paths, ['/first']);
      expect(response.statusCode, 302);
    });

    test('the Host header arrives at the server with its port', () async {
      // Read off the wire rather than off the request object: the header has
      // to survive `dart:io`, which sets a Host of its own from the
      // connection URI and would otherwise report 127.0.0.1.
      final client = GuardedPlaintextClient(
        http.Client(),
        guard: PlaintextDestinationGuard(
          lookup: (_) async => [_v4('127.0.0.1')],
        ),
      );
      addTearDown(client.close);

      await client.get(Uri.parse('http://ollama.lan:${server.port}/second'));

      expect(hosts.single, 'ollama.lan:${server.port}');
    });
  });

}
