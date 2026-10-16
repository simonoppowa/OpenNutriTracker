import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:home_widget/home_widget.dart';
import 'package:opennutritracker/core/utils/widget/calorie_widget_labels.dart';
import 'package:opennutritracker/core/utils/widget/calorie_widget_snapshot.dart';

/// Writes a [CalorieWidgetSnapshot] where the widget extension can read it.
abstract class CalorieWidgetStore {
  Future<void> write(
    CalorieWidgetSnapshot snapshot,
    CalorieWidgetLabels labels,
  );

  /// Removes everything [write] stored and reloads the widget, so it stops
  /// showing a profile whose data was just deleted.
  Future<void> clear();
}

/// App Group on iOS, shared preferences on Android. Android has no
/// widget UI in this milestone; the save still runs so a later widget
/// can reuse the same keys.
class HomeWidgetCalorieStore implements CalorieWidgetStore {
  final bool _isIOS;

  HomeWidgetCalorieStore({@visibleForTesting bool? isIOS})
    : _isIOS = isIOS ?? Platform.isIOS;

  @override
  Future<void> write(
    CalorieWidgetSnapshot snapshot,
    CalorieWidgetLabels labels,
  ) => _save({...snapshot.toPayload(), ...labels.toPayload()});

  /// A null value makes the plugin remove the key, which the extension
  /// reads as "no data yet" and answers with its placeholder.
  @override
  Future<void> clear() => _save({
    for (final key in [
      ...CalorieWidgetSnapshot.keys,
      ...CalorieWidgetLabels.keys,
    ])
      key: null,
  });

  Future<void> _save(Map<String, String?> values) async {
    if (_isIOS) {
      await HomeWidget.setAppGroupId(CalorieWidgetSnapshot.appGroupId);
    }
    for (final entry in values.entries) {
      await HomeWidget.saveWidgetData<String>(
        entry.key,
        entry.value,
        appGroupId: CalorieWidgetSnapshot.appGroupId,
      );
    }
    if (!_isIOS) return;
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
