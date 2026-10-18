import 'package:flutter/material.dart';
import 'package:opennutritracker/core/utils/app_locale.dart';

/// The app's chosen locale for the widget tree — and, through [AppLocale],
/// for the code that has no BuildContext. This is the only writer of
/// [AppLocale]: whatever a widget shows is what a food search asks for.
class LocaleProvider extends ChangeNotifier {
  Locale? locale;

  /// Told about every change after start-up, from the in-app picker,
  /// Android's per-app language setting and, while following "System
  /// default", the device language alike. Used to reschedule the daily
  /// reminder, whose text the OS holds in the language it was scheduled in
  /// (#1366).
  final void Function(Locale? locale)? onChanged;

  LocaleProvider({this.locale, this.onChanged}) {
    AppLocale.select(locale?.toString());
  }

  void updateLocale(Locale? newLocale) {
    locale = newLocale;
    AppLocale.select(newLocale?.toString());
    notifyListeners();
    onChanged?.call(newLocale);
  }

  /// The device's language list changed. While following "System default"
  /// (null) `MaterialApp` re-resolves by itself, but [onChanged] has to hear
  /// of it too — this is also how a cleared per-app override settles, since
  /// Android delivers the corrected list after [updateLocale] ran (#1366).
  void systemLocalesChanged() {
    if (locale == null) onChanged?.call(null);
  }
}
