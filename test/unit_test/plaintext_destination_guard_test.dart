import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:opennutritracker/core/utils/plaintext_destination_guard.dart';

/// Records the request that reached the socket, or the fact that none did.
class _RecordingClient extends http.BaseClient {
  http.BaseRequest? sent;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    sent = request;
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
      expect(inner.sent!.headers['host'], 'ollama.lan');
      expect(inner.sent!.headers['content-type'], 'application/json');
      expect((inner.sent! as http.Request).body, 'payload');
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
}
