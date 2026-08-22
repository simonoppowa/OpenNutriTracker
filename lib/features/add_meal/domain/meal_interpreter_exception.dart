/// What a caller can usefully do about a failed interpretation.
///
/// Provider-neutral on purpose. The same HTTP status means different things
/// to different providers — 404 is a capability refusal on a broker that
/// could not find an endpoint, and merely a wrong URL somewhere else — so
/// the mapping from status to meaning belongs in each client, where the
/// evidence for it lives. Callers switch on the meaning and never see the
/// number.
enum MealInterpreterFailure {
  /// A retry might survive this: no network, a rate limit, a 5xx, a reply
  /// that did not parse. The default, because anything unrecognised is
  /// better offered as retryable than declared permanent.
  transient,

  /// The provider rejected the credential itself. Shown differently from a
  /// transient failure: telling someone to "try again later" when their key
  /// is wrong is the puzzle [AiCredentialStorage] already goes out of its
  /// way to avoid.
  auth,

  /// The provider rejected the request rather than failing to serve it. On
  /// the photo path that means the image.
  rejected,

  /// Nothing on the other end can serve this kind of request at all — the
  /// chosen model takes no images, or no provider of it honours a forced
  /// tool call. Points the user at their settings, not at their network.
  unsupported,

  /// The account cannot pay: no credit, or a spend cap reached.
  ///
  /// Its own meaning because both of the alternatives are actively wrong.
  /// [transient] tells someone to retry, which is a loop with no exit —
  /// OpenRouter states that retrying "billing, spend, or quota errors won't
  /// restore API access". [auth] sends them to check a key that works, which
  /// is exactly the misdirection this vocabulary exists to prevent.
  ///
  /// Both shipped providers answer **402** for it and **429** for an
  /// ordinary rate limit, so the two are separable on status alone with no
  /// body parsing.
  billing,

  /// The destination did not answer inside the budget the client allowed.
  ///
  /// Told apart from [transient] because they are different facts about
  /// different things. A transient failure is the *connection* — dropped,
  /// rate limited, refused — and checking the network is sensible advice for
  /// it. This one is the *server*: the connection worked, the request
  /// arrived, and the answer was still not finished when the client stopped
  /// waiting. Advice about a network fixes nothing.
  ///
  /// **Which destinations use it is a per-client policy, not a property of
  /// timing out** — see `OpenAiCompatibleMealItemsApi.timeoutFailure`. A
  /// hosted API that misses a 20s budget really has had a blip and really
  /// should be retried, so those clients keep reporting [transient]. A
  /// machine in the user's house that misses a 120s budget has told them
  /// something durable about that machine (#774).
  timeout,
}

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

  /// What the caller should do about it, decided by the client that threw.
  ///
  /// Defaults to [MealInterpreterFailure.transient] so a failure with no
  /// status behind it — a socket error, a reply that did not parse — stays
  /// retryable without every throw site having to say so.
  final MealInterpreterFailure failure;

  /// The provider's HTTP status, when there was one. **Diagnostic only.**
  ///
  /// Nothing decides anything from this: a raw number is what a reader of a
  /// log wants, and what a caller must not have, because interpreting it
  /// correctly needs to know which provider answered.
  final int? statusCode;

  const MealInterpreterException(
    this.reason, {
    this.failure = MealInterpreterFailure.transient,
    this.statusCode,
  });

  @override
  String toString() =>
      'MealInterpreterException($reason, ${failure.name}'
      '${statusCode == null ? '' : ', status: $statusCode'})';
}
