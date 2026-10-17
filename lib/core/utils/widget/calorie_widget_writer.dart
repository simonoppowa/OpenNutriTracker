import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:home_widget/home_widget.dart';
import 'package:opennutritracker/core/utils/widget/calorie_widget_labels.dart';
import 'package:opennutritracker/core/utils/widget/calorie_widget_snapshot.dart';
import 'package:opennutritracker/generated/l10n.dart';

/// Writes a [CalorieWidgetSnapshot] where the widget extension can read it.
abstract class CalorieWidgetStore {
  Future<void> write(
    CalorieWidgetSnapshot snapshot,
    CalorieWidgetLabels labels,
  );

  /// Removes the profile's figures and reloads the widget, so it stops
  /// showing a profile whose data was just deleted. The language-only
  /// labels stay, so the placeholder it falls back to is still translated.
  Future<void> clear();

  /// Rewrites the labels in [s]'s language around the figures already
  /// stored, for when the app's language changes without a Home reload.
  Future<void> relabel(S s);
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
      ...CalorieWidgetLabels.figureKeys,
    ])
      key: null,
  });

  /// Without stored figures (before the first Home load, or after a wipe)
  /// only the language-only labels are written; the figure labels would
  /// describe numbers the widget does not have.
  @override
  Future<void> relabel(S s) async {
    if (_isIOS) {
      await HomeWidget.setAppGroupId(CalorieWidgetSnapshot.appGroupId);
    }
    final consumed = await _readInt(CalorieWidgetSnapshot.consumedKey);
    final goal = await _readInt(CalorieWidgetSnapshot.goalKey);
    final labels = CalorieWidgetLabels.forFigures(
      s,
      consumedKcal: consumed ?? 0,
      goalKcal: goal ?? 0,
    );
    final hasFigures = consumed != null && goal != null;
    await _save(hasFigures ? labels.toPayload() : labels.languagePayload());
  }

  Future<int?> _readInt(String key) async {
    final value = await HomeWidget.getWidgetData<String>(
      key,
      appGroupId: CalorieWidgetSnapshot.appGroupId,
    );
    return int.tryParse(value ?? '');
  }

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
