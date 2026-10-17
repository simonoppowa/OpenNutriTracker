import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:home_widget/home_widget.dart';
import 'package:opennutritracker/core/utils/widget/calorie_widget_labels.dart';
import 'package:opennutritracker/core/utils/widget/calorie_widget_snapshot.dart';
import 'package:opennutritracker/generated/l10n.dart';
import 'package:package_info_plus/package_info_plus.dart';

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
  final Future<String> Function() _bundleId;
  String? _appGroupId;

  HomeWidgetCalorieStore({
    @visibleForTesting bool? isIOS,
    @visibleForTesting Future<String> Function()? bundleId,
  }) : _isIOS = isIOS ?? Platform.isIOS,
       _bundleId = bundleId ?? _platformBundleId;

  static Future<String> _platformBundleId() async =>
      (await PackageInfo.fromPlatform()).packageName;

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
    final group = await _enterAppGroup();
    final consumed = await _readInt(group, CalorieWidgetSnapshot.consumedKey);
    final goal = await _readInt(group, CalorieWidgetSnapshot.goalKey);
    final labels = CalorieWidgetLabels.forFigures(
      s,
      consumedKcal: consumed ?? 0,
      goalKcal: goal ?? 0,
    );
    final hasFigures = consumed != null && goal != null;
    await _save(hasFigures ? labels.toPayload() : labels.languagePayload());
  }

  /// The App Group of this build's flavour, from its bundle id. Kept once
  /// found, since the bundle id cannot change while the app runs.
  Future<String> _enterAppGroup() async {
    final group = _appGroupId ??= CalorieWidgetSnapshot.appGroupIdFor(
      await _bundleId(),
    );
    if (_isIOS) await HomeWidget.setAppGroupId(group);
    return group;
  }

  Future<int?> _readInt(String group, String key) async {
    final value = await HomeWidget.getWidgetData<String>(
      key,
      appGroupId: group,
    );
    return int.tryParse(value ?? '');
  }

  Future<void> _save(Map<String, String?> values) async {
    final group = await _enterAppGroup();
    for (final entry in values.entries) {
      await HomeWidget.saveWidgetData<String>(
        entry.key,
        entry.value,
        appGroupId: group,
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
