import 'dart:async';

import 'package:flutter/material.dart';
import 'package:opennutritracker/core/utils/app_locale.dart';
import 'package:opennutritracker/core/utils/widget/calorie_widget_labels.dart';
import 'package:opennutritracker/core/utils/widget/calorie_widget_writer.dart';

/// The app's chosen locale for the widget tree — and, through [AppLocale],
/// for the code that has no BuildContext. This is the only writer of
/// [AppLocale]: whatever a widget shows is what a food search asks for.
class LocaleProvider extends ChangeNotifier {
  Locale? locale;
  final CalorieWidgetStore _calorieWidgetStore;

  /// Told about every change after start-up, from the in-app picker,
  /// Android's per-app language setting and, while following "System
  /// default", the device language alike. Used to reschedule the daily
  /// reminder, whose text the OS holds in the language it was scheduled in
  /// (#1366).
  final void Function(Locale? locale)? onChanged;

  /// [relabelCalorieWidget] is for a launch that goes to onboarding, where
  /// Home never writes the widget's labels: if the device language changed
  /// while the app was closed, the widget would otherwise keep the old one.
  /// A launch into Home leaves it off, since Home writes the labels with
  /// today's figures and a second write could race it.
  LocaleProvider({
    this.locale,
    this.onChanged,
    CalorieWidgetStore? calorieWidgetStore,
    bool relabelCalorieWidget = false,
  }) : _calorieWidgetStore = calorieWidgetStore ?? HomeWidgetCalorieStore() {
    AppLocale.select(locale?.toString());
    if (relabelCalorieWidget) unawaited(_relabelCalorieWidget());
  }

  void updateLocale(Locale? newLocale) {
    locale = newLocale;
    AppLocale.select(newLocale?.toString());
    notifyListeners();
    // The home-screen widget keeps its own copy of the labels, written
    // when Home loads. A language change does not reload Home, so without
    // this the widget and its gallery entry stay in the old language.
    unawaited(_relabelCalorieWidget());
    onChanged?.call(newLocale);
  }

  /// The device's language list changed. While following "System default"
  /// (null) `MaterialApp` re-resolves by itself, but [onChanged] has to hear
  /// of it too — this is also how a cleared per-app override settles, since
  /// Android delivers the corrected list after [updateLocale] ran (#1366).
  /// The widget's labels follow "System default" the same way.
  void systemLocalesChanged() {
    if (locale != null) return;
    unawaited(_relabelCalorieWidget());
    onChanged?.call(null);
  }

  Future<void> _relabelCalorieWidget() async {
    try {
      await _calorieWidgetStore.relabel(CalorieWidgetLabels.appStrings());
    } catch (_) {
      // The widget must never stand in the way of a language change.
    }
  }
}
