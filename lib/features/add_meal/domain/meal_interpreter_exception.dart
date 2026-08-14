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

  @override
  String toString() =>
      'MealInterpreterException($reason${statusCode == null ? '' : ', '
                'status: $statusCode'})';
}
