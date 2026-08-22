import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';
import 'package:opennutritracker/core/utils/plaintext_destination_guard.dart';

/// How long the app waits for a server to say what it has.
///
/// Deliberately **not** `ownServerTimeout`'s two minutes. That budget exists
/// because a meal request pays for a cold model load — #774 measured 22–24s
/// of it on an M4 Mac mini — and none of the four runtimes loads a model to
/// answer `/v1/models`. It reads a directory. A server that cannot list its
/// own files in fifteen seconds is not busy thinking, it is unreachable, and
/// making the user watch a spinner for two minutes to be told so is worse
/// than telling them at fifteen and leaving the field they can type into.
const aiModelListTimeout = Duration(seconds: 15);

/// Why a server could not be asked what models it has.
///
/// Three, not one, because they want three different fixes and the user is
/// the only one who can apply any of them. A list that collapses them into
/// "something went wrong" sends someone to check a cable when the address is
/// wrong, or to retype an address when the app is the thing that refused.
enum AiModelListFailure {
  /// Nothing answered. Asleep, on another network, behind a VPN that is off,
  /// a name that does not resolve, or a port nobody is listening on.
  unreachable,

  /// The app declined to send. Plaintext to an address that is not private,
  /// per #758 — the server may be perfectly healthy and was never contacted.
  insecureDestination,

  /// Something answered, and it was not a model list. A 404 from a web server
  /// on that port, a 401 from a reverse proxy, a 500, or a body that is not
  /// the shape `/v1/models` returns.
  rejected,
}

/// What a server said when asked what models it has.
///
/// An empty list is a **result**, not a failure: the server answered and has
/// nothing pulled. It is kept distinct from [failure] because those two are
/// the pair the user most needs told apart — "I could not reach it" and "it
/// is there and empty" are the same blank picker and opposite problems.
class AiModelListResult {
  /// What the server reported, in the order it reported it. Empty when
  /// [failure] is set, and empty is also a legitimate answer.
  ///
  /// **A single element is an ordinary answer.** llama.cpp serves exactly one
  /// model — the file it was started with — so a one-entry list is the normal
  /// shape there rather than a truncated one.
  final List<String> ids;

  /// Null when the server answered with a list, whatever length.
  final AiModelListFailure? failure;

  const AiModelListResult.models(this.ids) : failure = null;

  const AiModelListResult.failed(AiModelListFailure this.failure)
    : ids = const [];
}

/// Asks an OpenAI-compatible server what models it serves.
///
/// **This is a picker's contents and nothing more.** `/v1/models` reports an
/// `id` and little else, and none of Ollama, LM Studio, llama.cpp or vLLM
/// flags vision or tool support there — so the reply says what *exists* on
/// that machine and never what *works* for this app. Nothing here may be read
/// as a capability signal; that question is #735's probe, which asks by
/// sending a real request.
///
/// Every request goes through [GuardedPlaintextClient], so #758's rule —
/// plaintext to private and loopback addresses only, checked against the
/// resolved address per request — covers this call the same way it covers a
/// meal. The refusal comes back as [AiModelListFailure.insecureDestination]
/// rather than as an exception the settings dialog would have to catch.
class AiModelListApi {
  static final _log = Logger('AiModelListApi');

  final http.Client _client;
  final Duration timeout;

  AiModelListApi({http.Client? client, this.timeout = aiModelListTimeout})
    : _client = GuardedPlaintextClient(client ?? http.Client());

  /// Asks [endpoint] — the `/v1/models` route, per
  /// `AiCredentialStorage.resolveModelsEndpoint` — for its model ids.
  ///
  /// Never throws. A settings screen asking a question is not a place to
  /// surface a socket error, and every way this can fail is something the
  /// user can act on or ignore.
  ///
  /// [apiKey] is sent when there is one. None of the four runtimes requires
  /// it by default, and a reverse proxy in front of one will.
  Future<AiModelListResult> list(Uri endpoint, {String? apiKey}) async {
    final http.Response response;
    try {
      response = await _client
          .get(
            endpoint,
            headers: {
              if (apiKey != null && apiKey.isNotEmpty)
                'authorization': 'Bearer $apiKey',
            },
          )
          .timeout(timeout);
    } on InsecureDestinationException {
      // Ahead of the catch-all, which would report this as unreachable and
      // send the user to wake a machine the app never spoke to. The host is
      // not logged — it is an address on somebody's home network.
      _log.warning('Refused a plaintext model list to a public address');
      return const AiModelListResult.failed(
        AiModelListFailure.insecureDestination,
      );
    } catch (e) {
      // `e` is not logged: a socket error can carry the request back with it,
      // and the request names a machine on the user's network.
      _log.info('Could not reach the endpoint for a model list');
      return const AiModelListResult.failed(AiModelListFailure.unreachable);
    }

    if (response.statusCode != 200) {
      _log.warning('Model list request failed with ${response.statusCode}');
      return const AiModelListResult.failed(AiModelListFailure.rejected);
    }

    final ids = _idsFrom(response.body);
    if (ids == null) {
      _log.warning('Model list reply was not the shape /v1/models returns');
      return const AiModelListResult.failed(AiModelListFailure.rejected);
    }
    _log.info('Model list returned ${ids.length} id(s)');
    return AiModelListResult.models(ids);
  }

  /// The ids in a `/v1/models` body, or null when the body is not one.
  ///
  /// Order is the server's. Ollama lists most-recently-modified first and
  /// vLLM lists what it was launched with; neither ordering means anything to
  /// this app, and sorting would invent a ranking over a list whose whole
  /// point is that nothing about it has been measured.
  ///
  /// A missing or non-list `data` is [AiModelListFailure.rejected] rather than
  /// an empty list, because it is something other than a model server
  /// answering — and "it is there and empty" is a claim this must not make on
  /// a 200 from an unrelated web server.
  List<String>? _idsFrom(String body) {
    try {
      final data = (jsonDecode(body) as Map<String, dynamic>)['data'];
      if (data is! List) return null;
      return [
        for (final entry in data)
          if (entry is Map<String, dynamic>)
            if (entry['id'] case final String id when id.isNotEmpty) id,
      ];
    } catch (_) {
      return null;
    }
  }

  /// Only for a caller that let this class create its own client.
  void close() => _client.close();
}
