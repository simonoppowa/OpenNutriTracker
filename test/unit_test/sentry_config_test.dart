import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/utils/sentry_config.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

/// Print breadcrumbs are the one Sentry setting this app cannot let drift back
/// to its default. `LoggerConfig` sends the entire application log through
/// `debugPrint` at `Level.ALL`, and Sentry replaces `debugPrint` in release
/// builds, so a `true` here would put diary content — searches, scanned
/// barcodes, water and weight entries — into crash reports the user was told
/// contain none of it.
void main() {
  SentryOptions configured() {
    final options = SentryOptions();
    configureSentryOptions(options, dsn: 'https://key@example.invalid/1');
    return options;
  }

  test('release options never send print breadcrumbs', () {
    expect(configured().enablePrintBreadcrumbs, isFalse);
  });

  test('release options do not attach default PII', () {
    // Not set by `configureSentryOptions` — this pins the SDK's own default,
    // because the README states that `sendDefaultPii` stays false and an SDK
    // upgrade is the only thing that could quietly change it.
    expect(configured().sendDefaultPii, isFalse);
  });
}
