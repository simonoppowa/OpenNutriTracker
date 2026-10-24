import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:opennutritracker/core/utils/sentry_config.dart';
import 'package:opennutritracker/features/scanner/data/product_not_found_exception.dart';
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

  test('release options strip the user block before sending', () async {
    // The native SDKs attach a stable per-install UUID as user.id regardless
    // of sendDefaultPii, so an event that still carries a user block is one
    // that carries an identifier. The consent the user gave calls these
    // reports anonymous; this hook is what makes that true.
    final options = configured();
    final beforeSend = options.beforeSend;
    expect(beforeSend, isNotNull, reason: 'no beforeSend hook is configured');

    final event = SentryEvent(
      user: SentryUser(
        id: 'a-per-install-uuid',
        geo: SentryGeo(city: 'Essen'),
      ),
    );
    final sent = await beforeSend!(event, Hint());

    expect(sent, isNotNull, reason: 'the hook must not drop the event itself');
    expect(sent!.user, isNull);
  });

  test('release options send no performance transactions', () {
    // A traces sample rate is what turns transaction sending on, and
    // enableAutoPerformanceTracing defaults to true — so a non-null rate here
    // means app-start and screen-load transactions for ordinary sessions, with
    // no crash involved. The switch says "Send crash reports to help fix bugs".
    final options = configured();

    expect(options.tracesSampleRate, isNull);
    expect(
      options.isTracingEnabled(),
      isFalse,
      reason: 'tracing is on, so ordinary sessions reach the network',
    );
  });

  test('release options do not attach default PII', () {
    // Not set by `configureSentryOptions` — this pins the SDK's own default,
    // because the README states that `sendDefaultPii` stays false and an SDK
    // upgrade is the only thing that could quietly change it.
    expect(configured().sendDefaultPii, isFalse);
  });

  group('expected errors are not reported', () {
    Future<SentryEvent?> run(Object throwable) async {
      final event = SentryEvent(
        throwable: throwable,
        user: SentryUser(id: 'x'),
      );
      return configured().beforeSend!(event, Hint());
    }

    final dropped = <String, Object>{
      'ProductNotFoundException': ProductNotFoundException(),
      'SocketException no host': const SocketException(
        'Failed host lookup',
        osError: OSError('No address associated with hostname', 7),
      ),
      'SocketException reset': const SocketException(
        'Connection reset by peer',
        osError: OSError('Connection reset by peer', 104),
      ),
      'SocketException refused': const SocketException('Connection refused'),
      'SocketException unreachable': const SocketException(
        'Network is unreachable',
        osError: OSError('Network is unreachable', 101),
      ),
      'HandshakeException': const HandshakeException('Handshake error'),
      'TlsException': const TlsException('TLS error'),
      'http ClientException': http.ClientException('Connection closed'),
      'TimeoutException': TimeoutException(
        'Future not completed',
        const Duration(minutes: 1),
      ),
      'OFF HTTP 503': Exception('OFF HTTP 503'),
      'OFF HTTP 504': Exception('OFF HTTP 504'),
      'OFF HTTP 429': Exception('OFF HTTP 429'),
    };

    for (final entry in dropped.entries) {
      test('drops ${entry.key}', () async {
        expect(await run(entry.value), isNull);
      });
    }

    test('drops an event that only has the serialised exception', () async {
      final event = SentryEvent(
        exceptions: [SentryException(type: 'SocketException', value: 'x')],
      );
      expect(await configured().beforeSend!(event, Hint()), isNull);
    });

    test('drops an event that only has a serialised OSError', () async {
      final event = SentryEvent(
        exceptions: [
          SentryException(
            type: 'OSError',
            value: 'OS Error: No address associated with hostname, errno = 7',
          ),
        ],
      );
      expect(await configured().beforeSend!(event, Hint()), isNull);
    });

    final kept = <String, Object>{
      'TypeError': TypeError(),
      'FormatException': const FormatException('bad json'),
      'StateError': StateError('bug'),
      'OFF HTTP 400': Exception('OFF HTTP 400'),
      'OFF HTTP 404': Exception('OFF HTTP 404'),
    };

    for (final entry in kept.entries) {
      test('still reports ${entry.key} with the user stripped', () async {
        final sent = await run(entry.value);
        expect(sent, isNotNull);
        expect(sent!.user, isNull);
      });
    }
  });
}
