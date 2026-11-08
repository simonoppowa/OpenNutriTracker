import 'package:flutter/services.dart';

/// Bridges Android's per-app language setting, so the app's own language
/// picker and the one in Android's Settings stay in step.
///
/// Android 13 shows a language picker for every app that declares a
/// `localeConfig`. Flutter reads its locale from our saved config rather than
/// from the system, so without writing through to the platform that picker
/// would be visible and inert for anyone who had ever chosen a language in
/// the app: they would change it, nothing would happen, and there would be no
/// way to tell why.
///
/// Only Android registers the other end of this channel. Everywhere else --
/// iOS, the Linux desktop build, any widget test -- the call raises
/// [MissingPluginException] and is answered as "no override", which is the
/// truth on a platform with no per-app language setting to read. That is the
/// whole platform check: a `Platform.isAndroid` guard on top would say the
/// same thing less honestly, and would make this untestable off a handset.
class AppLocaleService {
  static const _channel = MethodChannel('com.opennutritracker/locale');

  /// The language tag the user chose in Android's Settings, or a null tag
  /// when they have not overridden it and the app should follow its own saved
  /// choice.
  ///
  /// `readFailed` separates "the platform says there is no override" from
  /// "the platform could not be asked". [reconcileAppLocale] treats a missing
  /// override as the user having cleared it, so a transient channel failure
  /// reported as a plain null would destroy their saved language.
  /// [MissingPluginException] is not a failure: no registered handler means a
  /// platform with no per-app language setting at all, where "no override" is
  /// the honest answer.
  static Future<({String? tag, bool readFailed})> getApplicationLocale() async {
    try {
      final tag = await _channel.invokeMethod<String?>('getApplicationLocale');
      return (tag: tag, readFailed: false);
    } on PlatformException {
      return (tag: null, readFailed: true);
    } on MissingPluginException {
      return (tag: null, readFailed: false);
    }
  }

  /// Tells Android which language the app is being read in. Pass null to
  /// clear the override, which is what "System default" means in our picker.
  static Future<void> setApplicationLocale(String? languageTag) async {
    try {
      await _channel.invokeMethod<void>('setApplicationLocale', {
        'tag': languageTag,
      });
    } on PlatformException {
      // A language that failed to reach the OS still applies inside the app.
      // The two pickers disagreeing is worth less than a crash on the screen
      // someone opened to fix their language.
    } on MissingPluginException {
      // No native side registered — iOS, desktop, or a widget test.
    }
  }
}
