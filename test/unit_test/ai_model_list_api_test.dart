import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:opennutritracker/core/utils/ai_credential_storage.dart';
import 'package:opennutritracker/core/utils/ai_model_list_api.dart';

/// A `/v1/models` body, in the shape all four runtimes serve it.
String _reply(List<String> ids) => jsonEncode({
  'object': 'list',
  'data': [
    for (final id in ids) {'id': id, 'object': 'model', 'owned_by': 'library'},
  ],
});

void main() {
  group('where to ask', () {
    test('a base address becomes the models route, not the chat route', () {
      // The two are derived from one resolution so they cannot disagree about
      // what the user typed — a picker that read a different host from the one
      // meals go to would be worse than no picker.
      expect(
        AiCredentialStorage.resolveModelsEndpoint('http://192.168.1.5:11434'),
        Uri.parse('http://192.168.1.5:11434/v1/models'),
      );
      expect(
        AiCredentialStorage.resolveEndpoint('http://192.168.1.5:11434'),
        Uri.parse('http://192.168.1.5:11434/v1/chat/completions'),
      );
    });

    test('the base URL LM Studio prints resolves too', () {
      expect(
        AiCredentialStorage.resolveModelsEndpoint('http://127.0.0.1:1234/v1'),
        Uri.parse('http://127.0.0.1:1234/v1/models'),
      );
    });

    test('a fully typed chat route swaps its last segment', () {
      expect(
        AiCredentialStorage.resolveModelsEndpoint(
          'https://ollama.example.com/v1/chat/completions',
        ),
        Uri.parse('https://ollama.example.com/v1/models'),
      );
    });

    test('what cannot be requested at all has nowhere to ask', () {
      // The form Ollama's own documentation shows, and not a URL.
      expect(AiCredentialStorage.resolveModelsEndpoint('192.168.1.5:11434'),
          isNull);
      expect(AiCredentialStorage.resolveModelsEndpoint(''), isNull);
    });
  });

  group('asking', () {
    test('reports the ids the server listed, in the order it listed them',
        () async {
      // Order is the server's. Sorting would invent a ranking over a list
      // whose whole point is that nothing about it has been measured.
      final api = AiModelListApi(
        client: MockClient(
          (_) async => http.Response(_reply(['qwen3:8b', 'gemma3:4b']), 200),
        ),
      );

      final result = await api.list(
        Uri.parse('http://127.0.0.1:11434/v1/models'),
      );

      expect(result.ids, ['qwen3:8b', 'gemma3:4b']);
      expect(result.failure, isNull);
    });

    test('one model is a normal answer, not an error', () async {
      // llama.cpp serves exactly the one file it was started with, so a
      // single-element list is the ordinary shape there. Treating it as a
      // truncated or failed reply would make the runtime with the smallest
      // footprint the one this dialog cannot configure.
      final api = AiModelListApi(
        client: MockClient(
          (_) async => http.Response(_reply(['Meta-Llama-3.1-8B-Q4_K_M']), 200),
        ),
      );

      final result = await api.list(Uri.parse('http://127.0.0.1:8080/v1/models'));

      expect(result.failure, isNull);
      expect(result.ids, ['Meta-Llama-3.1-8B-Q4_K_M']);
    });

    test('an empty list is an answer, and an unreachable server is not', () async {
      // The pair that must never collapse into one message: both produce an
      // empty picker, and they want opposite fixes.
      final empty = await AiModelListApi(
        client: MockClient((_) async => http.Response(_reply([]), 200)),
      ).list(Uri.parse('http://127.0.0.1:11434/v1/models'));
      final unreachable = await AiModelListApi(
        client: MockClient(
          (_) async => throw const SocketException('connection refused'),
        ),
      ).list(Uri.parse('http://127.0.0.1:11434/v1/models'));

      expect(empty.failure, isNull, reason: 'the server answered');
      expect(empty.ids, isEmpty);
      expect(unreachable.failure, AiModelListFailure.unreachable);
    });

    test('a server that gives up on us is unreachable, not empty', () async {
      final api = AiModelListApi(
        client: MockClient((_) async {
          await Future<void>.delayed(const Duration(milliseconds: 50));
          return http.Response(_reply(['gemma3:4b']), 200);
        }),
        timeout: const Duration(milliseconds: 5),
      );

      final result = await api.list(Uri.parse('http://127.0.0.1:11434/v1/models'));

      expect(result.failure, AiModelListFailure.unreachable);
    });

    test('something answering with the wrong thing is neither', () async {
      // A 404 from a web server on that port, or a 401 from a reverse proxy.
      // The machine is reachable and the address is wrong, which is a
      // different sentence from "could not reach it".
      final notFound = await AiModelListApi(
        client: MockClient((_) async => http.Response('nope', 404)),
      ).list(Uri.parse('http://127.0.0.1:80/v1/models'));

      expect(notFound.failure, AiModelListFailure.rejected);
    });

    test('a 200 that is not a model list is rejected, not read as empty', () async {
      // A router's admin page answers 200 to anything. Calling that "this
      // server lists no models" would state a fact about a machine that never
      // served a model in its life.
      final api = AiModelListApi(
        client: MockClient(
          (_) async => http.Response('<html>Welcome</html>', 200),
        ),
      );

      final result = await api.list(Uri.parse('http://192.168.1.1/v1/models'));

      expect(result.failure, AiModelListFailure.rejected);
    });

    test('entries without a usable id are skipped rather than fabricated', () async {
      final api = AiModelListApi(
        client: MockClient(
          (_) async => http.Response(
            jsonEncode({
              'data': [
                {'id': 'gemma3:4b'},
                {'object': 'model'},
                {'id': ''},
                'not-an-object',
              ],
            }),
            200,
          ),
        ),
      );

      final result = await api.list(Uri.parse('http://127.0.0.1:11434/v1/models'));

      expect(result.ids, ['gemma3:4b']);
    });

    test('the key is sent when there is one, and no header when there is not',
        () async {
      // None of the four runtimes wants one by default; a reverse proxy in
      // front of one will. An empty bearer is worse than no bearer.
      final seen = <Map<String, String>>[];
      final api = AiModelListApi(
        client: MockClient((request) async {
          seen.add(request.headers);
          return http.Response(_reply(['gemma3:4b']), 200);
        }),
      );

      await api.list(Uri.parse('http://127.0.0.1:11434/v1/models'), apiKey: 'k');
      await api.list(Uri.parse('http://127.0.0.1:11434/v1/models'));

      expect(seen[0]['authorization'], 'Bearer k');
      expect(seen[1].containsKey('authorization'), isFalse);
    });

    test('plaintext to a public address is refused, and says which it is',
        () async {
      // #758's rule covers this call the same way it covers a meal, because
      // the request goes through the same guard. Reporting it as unreachable
      // would send the user to wake a machine the app never spoke to.
      final api = AiModelListApi(
        client: MockClient(
          (_) async => fail('the guard must refuse before anything is sent'),
        ),
      );

      final result = await api.list(Uri.parse('http://93.184.216.34/v1/models'));

      expect(result.failure, AiModelListFailure.insecureDestination);
    });
  });
}
