import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:opennutritracker/features/scanner/data/product_not_found_exception.dart';
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
  options.tracesSampleRate = _tracesSampleRate;
  options.enablePrintBreadcrumbs = false;
  options.beforeSend = _beforeSend;
}

/// Null, which is what switches performance monitoring off: `isTracingEnabled`
/// is `tracesSampleRate != null || tracesSampler != null`, so a null rate means
/// no transaction is ever sampled or sent.
///
/// It was `1.0`. A traces sample rate is what turns transaction sending on, and
/// `enableAutoPerformanceTracing` defaults to true, so app-start and
/// screen-load transactions were produced for ordinary sessions at a 100%
/// sample rate — with no crash involved.
///
/// The switch the user actually agreed to says *"Send crash reports to help fix
/// bugs"*. A report every time the app opens is not that. It also changes how
/// often Sentry observes the coarse location it derives server-side from the
/// connection: once per session rather than once per crash, which is a
/// materially different picture from the one the consent describes.
///
/// Written as an explicit null rather than an omitted line, because an absent
/// setting reads as an oversight and this one is a decision.
///
/// The alternative was to keep the tracing and widen the consent string and the
/// policy to "crash and performance reports". That stays available — nothing
/// here is hard to reverse — but it asks the user for more, and nothing in this
/// repository reads the performance data.
const double? _tracesSampleRate = null;

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

/// The single `beforeSend` hook: drops events for errors the app already
/// handles, then strips the user from the rest.
SentryEvent? _beforeSend(SentryEvent event, Hint hint) {
  if (isExpectedError(event)) return null;
  return _stripUser(event, hint);
}

/// An OFF response the server gave while overloaded or rate limiting: 429 and
/// every 5xx. A 4xx other than 429 is a request we built wrongly, so it is not
/// matched and keeps being reported.
final RegExp _offTransientHttp = RegExp(r'OFF HTTP (429|5\d\d)\b');

/// Whether [event] carries an error that is expected in normal use and that
/// the app already surfaces to the user, so reporting it is only noise:
///
/// - [ProductNotFoundException]: the barcode is not in Open Food Facts.
/// - [SocketException]: offline, DNS failure, connection reset, refused or
///   unreachable.
/// - [HandshakeException] / [TlsException]: TLS failed on a bad connection.
/// - [http.ClientException]: the `http` package's connection failed, closed
///   or aborted.
/// - [TimeoutException]: every `.timeout(...)` in the app wraps a network
///   call.
/// - `Exception('OFF HTTP 429|5xx')`: Open Food Facts is down or rate
///   limiting. Thrown as a plain `Exception`, so it is matched on its message.
///
/// The runtime type is checked first; the serialised exception type and value
/// are only a fallback for events whose throwable is gone. TypeError,
/// FormatException, PostgrestException, PlatformException and `OFF HTTP` 4xx
/// (other than 429) are deliberately not matched.
bool isExpectedError(SentryEvent event) {
  final throwable = event.throwable;
  if (throwable != null) {
    if (throwable is ProductNotFoundException ||
        throwable is SocketException ||
        throwable is TlsException ||
        throwable is http.ClientException ||
        throwable is TimeoutException) {
      return true;
    }
    return throwable is Exception &&
        _offTransientHttp.hasMatch(throwable.toString());
  }
  for (final exception in event.exceptions ?? const <SentryException>[]) {
    final type = exception.type;
    if (type == 'ProductNotFoundException' ||
        type == 'SocketException' ||
        // The OS error Sentry splits out of a SocketException as its own
        // entry; the offline issues are titled by it.
        type == 'OSError' ||
        type == 'HandshakeException' ||
        type == 'TlsException' ||
        type == 'ClientException' ||
        type == 'TimeoutException') {
      return true;
    }
    if (type == '_Exception' &&
        _offTransientHttp.hasMatch(exception.value ?? '')) {
      return true;
    }
  }
  return false;
}
