import 'package:flutter/material.dart';
import 'package:opennutritracker/core/utils/app_locale.dart';

/// The app's chosen locale for the widget tree — and, through [AppLocale],
/// for the code that has no BuildContext. This is the only writer of
/// [AppLocale]: whatever a widget shows is what a food search asks for.
class LocaleProvider extends ChangeNotifier {
  Locale? locale;

  LocaleProvider({this.locale}) {
    AppLocale.select(locale?.toString());
  }

  void updateLocale(Locale? newLocale) {
    locale = newLocale;
    AppLocale.select(newLocale?.toString());
    notifyListeners();
  }
}
