import 'package:flutter/services.dart';

/// Answers Health Connect when it asks the app to explain what it wants health
/// data for.
///
/// Health Connect offers the user two ways to ask that question — the "why
/// does this app need this" affordance on the grant dialog, and the app's entry
/// in Health Connect's own settings once permissions are held. Both arrive as
/// intents aimed at `MainActivity`, which records them; this reads the record.
///
/// Declaring the intent filters is not enough on its own, and that is the bug
/// this exists to fix (#927): the manifest was correct while the activity
/// ignored the intent, so the user was dropped on the diary home screen with
/// no explanation of what had been asked.
///
/// Only Android registers the other end of this channel. On iOS, the Linux
/// desktop build and every widget test the call raises
/// [MissingPluginException] and is answered as "nothing pending", which is the
/// truth on a platform that has no Health Connect to be asked by. Mirrors
/// `AppLocaleService`, deliberately: same shape, same reason for having no
/// `Platform.isAndroid` guard.
class HealthRationaleService {
  static const _channel = MethodChannel(
    'com.opennutritracker/health_rationale',
  );

  /// Whether Health Connect has asked for an explanation since this was last
  /// called. Reading clears it on the platform side, so two callers racing
  /// cannot both open the screen.
  static Future<bool> consumePendingRequest() async {
    try {
      return await _channel.invokeMethod<bool>('consumePendingRequest') ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }
}
