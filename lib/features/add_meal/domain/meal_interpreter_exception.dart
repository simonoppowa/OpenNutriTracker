/// Raised when an interpreter cannot produce a result. Carries no response
/// body: provider payloads can echo the submitted text, and this ends up in
/// logs.
///
/// Shared by the text and photo interpreters. The two differ in what the
/// caller does about it — a failed text read falls back to the deterministic
/// parser, a failed photo read has nothing to fall back to and must be shown
/// — but the failures themselves are the same handful of things: no network,
/// a rejected key, a rate limit, a malformed reply.
class MealInterpreterException implements Exception {
  final String reason;

  /// Set when the provider answered with an HTTP status, so a caller can
  /// tell "your key is wrong" (401/403) from "try again later" (429/5xx).
  final int? statusCode;

  const MealInterpreterException(this.reason, {this.statusCode});

  /// True for failures that a retry might survive. An auth failure is not
  /// one of them.
  bool get isTransient =>
      statusCode == null || statusCode == 429 || (statusCode! >= 500);

  /// True when the provider rejected the credential itself. The photo path
  /// shows this differently from a transient failure: telling someone to
  /// "try again later" when their key is wrong is the puzzle
  /// [AiCredentialStorage] already goes out of its way to avoid.
  bool get isAuthFailure => statusCode == 401 || statusCode == 403;

  /// True when the provider rejected the request itself rather than failing
  /// to serve it. On the photo path that means the image.
  ///
  /// Found by running a corpus of real photographs: JPEGs carrying Adobe
  /// APP14 markers were refused with a 400 on every attempt, while the same
  /// picture re-encoded went through. Retrying one of those never succeeds,
  /// so it must not be offered to the user as retryable.
  bool get isRejectedRequest => statusCode == 400 || statusCode == 422;

  /// True when nothing on the other end can serve this kind of request at
  /// all — the chosen model takes no images, or no provider of it honours a
  /// forced tool call.
  ///
  /// A probe of OpenRouter with `provider.require_parameters` set returned
  /// **404** for both, with the messages "No endpoints found that support
  /// image input" and "No endpoints found that can handle the requested
  /// parameters". Neither improves on a retry, and neither is anything to do
  /// with the connection — so this must be told apart from a transient
  /// failure, or the user is sent to check their network forever over a
  /// choice they made in settings.
  ///
  /// Anthropic direct cannot produce this: its model is pinned and takes
  /// images. It exists because a broker can be pointed at a model that does
  /// not.
  bool get isCapabilityRefusal => statusCode == 404;

  @override
  String toString() =>
      'MealInterpreterException($reason${statusCode == null ? '' : ', '
                'status: $statusCode'})';
}
