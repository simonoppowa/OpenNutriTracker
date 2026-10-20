import 'dart:convert';
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
  /// Bumped by every [clear]. A caller that read its figures before a
  /// clear passes the generation it saw to [write], which then drops them,
  /// so a wiped or switched-away profile cannot be written back.
  int get generation;

  /// Skipped when [generation] is given and a [clear] has run since.
  Future<void> write(
    CalorieWidgetSnapshot snapshot,
    CalorieWidgetLabels labels, {
    int? generation,
  });

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
  int _generation = 0;
  Future<void> _last = Future.value();

  HomeWidgetCalorieStore({
    @visibleForTesting bool? isIOS,
    @visibleForTesting Future<String> Function()? bundleId,
  }) : _isIOS = isIOS ?? Platform.isIOS,
       _bundleId = bundleId ?? _platformBundleId;

  static Future<String> _platformBundleId() async =>
      (await PackageInfo.fromPlatform()).packageName;

  @override
  int get generation => _generation;

  /// Runs [operation] after every earlier one, so a write's keys never
  /// interleave with a clear's and the generation check sees every clear
  /// queued before it.
  Future<void> _serially(Future<void> Function() operation) {
    final next = _last.then((_) {}, onError: (_) {}).then((_) => operation());
    _last = next;
    return next;
  }

  @override
  Future<void> write(
    CalorieWidgetSnapshot snapshot,
    CalorieWidgetLabels labels, {
    int? generation,
  }) => _serially(() async {
    if (generation != null && generation != _generation) return;
    await _save({
      CalorieWidgetLabels.storageKey: labels.encodeLanguage(),
      CalorieWidgetSnapshot.storageKey: snapshot.encode(labels),
    });
  });

  /// A null value makes the plugin remove the key, which the extension
  /// reads as "no data yet" and answers with its placeholder.
  @override
  Future<void> clear() {
    _generation++;
    return _serially(() => _save({CalorieWidgetSnapshot.storageKey: null}));
  }

  /// Without a stored snapshot (before the first Home load, or after a
  /// wipe) only the language-only labels are written; the figure labels
  /// would describe numbers the widget does not have.
  @override
  Future<void> relabel(S s) => _serially(() => _relabel(s));

  Future<void> _relabel(S s) async {
    final group = await _enterAppGroup();
    final stored = await _readSnapshot(group);
    final labels = CalorieWidgetLabels.forFigures(
      s,
      consumedKcal: (stored?['consumed'] as int?) ?? 0,
      goalKcal: (stored?['goal'] as int?) ?? 0,
    );
    await _save({
      CalorieWidgetLabels.storageKey: labels.encodeLanguage(),
      if (stored != null)
        CalorieWidgetSnapshot.storageKey: jsonEncode({
          ...stored,
          'labels': labels.figureJson(),
        }),
    });
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

  Future<Map<String, Object?>?> _readSnapshot(String group) async {
    final value = await HomeWidget.getWidgetData<String>(
      CalorieWidgetSnapshot.storageKey,
      appGroupId: group,
    );
    if (value == null) return null;
    try {
      final decoded = jsonDecode(value);
      return decoded is Map<String, Object?> ? decoded : null;
    } on FormatException {
      return null;
    }
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
