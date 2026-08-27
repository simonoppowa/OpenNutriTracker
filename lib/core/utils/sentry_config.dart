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
}
