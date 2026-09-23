import 'dart:io';

import 'package:flutter/services.dart';
import 'package:home_widget/home_widget.dart';
import 'package:opennutritracker/core/utils/widget/calorie_widget_snapshot.dart';

/// Writes a [CalorieWidgetSnapshot] where the widget extension can read it.
abstract class CalorieWidgetStore {
  Future<void> write(CalorieWidgetSnapshot snapshot);
}

/// App Group on iOS, shared preferences on Android. Android has no
/// widget UI in this milestone; the save still runs so a later widget
/// can reuse the same keys.
class HomeWidgetCalorieStore implements CalorieWidgetStore {
  @override
  Future<void> write(CalorieWidgetSnapshot snapshot) async {
    if (Platform.isIOS) {
      await HomeWidget.setAppGroupId(CalorieWidgetSnapshot.appGroupId);
    }
    for (final entry in snapshot.toPayload().entries) {
      await HomeWidget.saveWidgetData<String>(
        entry.key,
        entry.value,
        appGroupId: CalorieWidgetSnapshot.appGroupId,
      );
    }
    if (!Platform.isIOS) return;
    try {
      await HomeWidget.updateWidget(
        iOSName: CalorieWidgetSnapshot.iosWidgetKind,
      );
    } on MissingPluginException {
      // Tests and platforms without the plugin skip the reload.
    } on PlatformException {
      // The extension is absent until the iOS target is embedded.
    }
  }
}
