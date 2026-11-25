import 'package:http/http.dart' as http;

/// Asks once more after a 429, a moment later, so a provider's brief rate
/// limit does not reach the user as a failed read.
///
/// Every client `mealItemsApiFor` builds sends through one. Runs through
/// OpenRouter got occasional 429s from the OpenAI and Anthropic endpoints
/// with a single request in flight, and they cleared on the next try. On the
/// typed path that 429 quietly cost the user the model's rows; on the photo
/// path it cost them the read.
///
/// **One retry, and only a short wait.** The client's own timeout wraps the
/// whole send, so it covers both attempts and a read never takes longer than
/// it did before. A `retry-after` longer than [maxWait] is passed on at once,
/// as is a second 429, and the client classifies it exactly as it always did
/// — an OpenAI 429 naming `insufficient_quota` is still a billing failure.
class RateLimitRetryClient extends http.BaseClient {
  /// The wait when the provider names none.
  static const defaultWait = Duration(seconds: 2);

  /// The longest wait worth taking inside a 20 s read.
  static const maxWait = Duration(seconds: 5);

  final http.Client _inner;
  final Future<void> Function(Duration) _sleep;

  RateLimitRetryClient(this._inner, {Future<void> Function(Duration)? sleep})
    : _sleep = sleep ?? Future<void>.delayed;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    // Only a plain request can be sent a second time: its body is in memory.
    if (request is! http.Request) return _inner.send(request);
    final first = await _inner.send(request);
    if (first.statusCode != 429) return first;
    final wait = _waitFor(first.headers['retry-after']);
    if (wait == null) return first;
    await first.stream.drain<void>();
    await _sleep(wait);
    return _inner.send(_copy(request));
  }

  /// A request can be sent only once, so the second attempt is a copy.
  static http.Request _copy(http.Request request) =>
      http.Request(request.method, request.url)
        ..headers.addAll(request.headers)
        ..followRedirects = request.followRedirects
        ..maxRedirects = request.maxRedirects
        ..persistentConnection = request.persistentConnection
        ..bodyBytes = request.bodyBytes;

  /// [defaultWait] without a `retry-after`, its seconds when within
  /// [maxWait], or null for a longer one — and for an HTTP date, which in
  /// practice means a longer one.
  static Duration? _waitFor(String? retryAfter) {
    if (retryAfter == null) return defaultWait;
    final seconds = double.tryParse(retryAfter.trim());
    if (seconds == null || seconds < 0) return null;
    final wait = Duration(milliseconds: (seconds * 1000).round());
    return wait > maxWait ? null : wait;
  }
}
