import 'package:flutter/services.dart';

/// Bridges the Android share-intent MethodChannel. Call [consumeSharedText]
/// once on startup and once each time the app returns to the foreground —
/// Kotlin stores the most recent shared text in [pendingSharedText] and
/// clears it the moment Flutter reads it, so double-import is not possible.
class ShareIntentService {
  static const _channel = MethodChannel('com.opennutritracker/share_intent');

  /// Returns the text that another Android app shared to OpenNutriTracker,
  /// or null when nothing is pending. Consuming the value clears it on the
  /// native side so a subsequent call returns null until a new share arrives.
  static Future<String?> consumeSharedText() async {
    try {
      return await _channel.invokeMethod<String?>('getSharedText');
    } on PlatformException {
      return null;
    }
  }
}
