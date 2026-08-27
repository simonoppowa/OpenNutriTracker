import 'package:sentry_flutter/sentry_flutter.dart';

/// The Sentry options a release build runs with, kept out of `main.dart` so
/// that the one setting which must not drift can be pinned by a test rather
/// than by a reviewer noticing an absent line.
///
/// [SentryOptions.enablePrintBreadcrumbs] defaults to `true`, and Sentry's
/// `DebugPrintIntegration` is registered unconditionally and bows out only in
/// debug mode — so it is live in exactly the builds where crash reporting
/// runs. `LoggerConfig` pipes the whole application log through `debugPrint`
/// at `Level.ALL`, which means every log line would become a breadcrumb
/// riding along on the next event of any kind: the food search terms the user
/// typed, the barcodes they scanned, their water and weight entries, the names
/// of their custom activities.
///
/// The consent they gave says the opposite — "No food log, weight, or personal
/// data is included" — so the breadcrumbs are turned off at the source.
/// Sanitising the individual log statements was the alternative and was
/// rejected: they are spread across data sources, blocs and screens, and
/// nothing about writing the next `log.fine` would remind its author that the
/// line can leave the device.
void configureSentryOptions(SentryOptions options, {required String dsn}) {
  options.dsn = dsn;
  options.tracesSampleRate = 1.0;
  options.enablePrintBreadcrumbs = false;
  options.beforeSend = _stripUser;
}

/// Drops the `user` block from every event before it leaves the device.
///
/// The native SDKs attach a randomly generated per-installation UUID as
/// `user.id`, and `sendDefaultPii` does not gate it — it is set regardless,
/// then carried onto Dart events along with the rest of the native user map.
/// Measured on a live event: the id is stable across launches, so every crash
/// from one installation is linkable to every other.
///
/// That makes the reports *pseudonymous*, and the consent the user gave calls
/// them anonymous. Removing the identifier is what makes the claim true, and
/// it restores the README's "no user or device identifier" rather than
/// requiring the sentence to be qualified a third time.
///
/// The cost is deliberate: `user.id` is what Sentry counts to say how many
/// users an issue affects, so an issue can no longer distinguish one
/// installation crash-looping from many installations hitting the same bug.
///
/// This cannot reach `user.geo` — the country, region and city Sentry records
/// per event. That is derived server-side at ingest from the connection
/// address, which the client never sends, so it has to be dealt with by a
/// data-scrubbing rule on the organisation instead.
SentryEvent? _stripUser(SentryEvent event, Hint hint) {
  event.user = null;
  return event;
}
