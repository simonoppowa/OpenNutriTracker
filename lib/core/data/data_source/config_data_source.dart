import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:logging/logging.dart';
import 'package:opennutritracker/core/data/dbo/app_theme_dbo.dart';
import 'package:opennutritracker/core/data/dbo/config_dbo.dart';
import 'package:opennutritracker/core/utils/hive_db_provider.dart';

/// Reads and writes the app config, which is split across two boxes:
///
/// - the **shared** [HiveDBProvider.appConfigBox] holds everything that is
///   a device-wide preference (theme, accent, language, units, energy unit,
///   notifications, anonymous-data consent, legal acceptances, and the
///   various view toggles), so it stays consistent whichever profile is
///   active;
/// - the **per-profile** [HiveDBProvider.configBox] holds the personal
///   nutrition goals (kcal adjustment, macro split, per-meal kcal shares and
///   the daily water goal) plus the health-import settings (opt-in flag,
///   calorie-credit multiplier, import watermark), which differ from one
///   profile to the next. The health settings belong here because the
///   activity box they write into is itself per-profile
///   ([HiveDBProvider.perProfileBoxNames]): each profile opts in for itself,
///   imports its own copy of a workout, and tracks its own watermark.
///
/// Reads merge the two — shared fields from the app box, personal fields
/// from the active profile's box. Writes store a detached copy of the merged
/// config into both boxes; because reads always source each field from its
/// authoritative box, the redundant copy in the other box is simply ignored,
/// so the two never disagree on a field that matters.
class ConfigDataSource {
  static const _configKey = "ConfigKey";

  final _log = Logger('ConfigDataSource');
  final HiveDBProvider _db;

  ConfigDataSource(this._db);

  Box<ConfigDBO> get _appBox => _db.appConfigBox;
  Box<ConfigDBO> get _profileBox => _db.configBox;

  /// Builds a detached config from the shared app box with the personal
  /// fields overlaid from the active profile's box. Detached (via JSON) so
  /// callers can't accidentally mutate a stored instance.
  ///
  /// Personal fields come exclusively from the active profile's box — if
  /// that box is absent (fresh profile or after a reset) they are cleared
  /// so stale values don't leak from the app box.
  ConfigDBO _readMerged() {
    final app = _appBox.get(_configKey);
    final profile = _profileBox.get(_configKey);
    final merged = app != null
        ? ConfigDBO.fromJson(app.toJson())
        : ConfigDBO.empty();
    if (profile != null) {
      merged.userKcalAdjustment = profile.userKcalAdjustment;
      merged.userCarbGoalPct = profile.userCarbGoalPct;
      merged.userProteinGoalPct = profile.userProteinGoalPct;
      merged.userFatGoalPct = profile.userFatGoalPct;
      merged.mealKcalSharesPct = profile.mealKcalSharesPct;
      merged.dailyWaterGoalMl = profile.dailyWaterGoalMl;
      merged.healthImportEnabled = profile.healthImportEnabled;
      merged.healthWorkoutKcalMultiplier = profile.healthWorkoutKcalMultiplier;
      merged.healthLastImportAt = profile.healthLastImportAt;
      merged.healthDeletedExternalIds = profile.healthDeletedExternalIds;
      merged.healthDeletedWorkouts = profile.healthDeletedWorkouts;
    } else {
      // Explicitly clear personal fields so they don't leak from the
      // app box after a profile reset. A fresh profile therefore reads as
      // opted out of the health import with no watermark of its own, which
      // is what it is.
      merged.userKcalAdjustment = null;
      merged.userCarbGoalPct = null;
      merged.userProteinGoalPct = null;
      merged.userFatGoalPct = null;
      merged.mealKcalSharesPct = null;
      merged.dailyWaterGoalMl = null;
      merged.healthImportEnabled = null;
      merged.healthWorkoutKcalMultiplier = null;
      merged.healthLastImportAt = null;
      merged.healthDeletedExternalIds = null;
      merged.healthDeletedWorkouts = null;
    }
    return merged;
  }

  /// Persists [config] to both boxes. Each box gets its own detached copy so
  /// the same `HiveObject` instance is never shared between boxes.
  Future<void> _writeBoth(ConfigDBO config) async {
    await _appBox.put(_configKey, ConfigDBO.fromJson(config.toJson()));
    await _profileBox.put(_configKey, ConfigDBO.fromJson(config.toJson()));
  }

  Future<bool> configInitialized() async =>
      _appBox.containsKey(_configKey) && _profileBox.containsKey(_configKey);

  Future<void> initializeConfig() async {
    if (!_appBox.containsKey(_configKey)) {
      await _appBox.put(_configKey, ConfigDBO.empty());
    }
    if (!_profileBox.containsKey(_configKey)) {
      await _profileBox.put(_configKey, ConfigDBO.empty());
    }
  }

  /// One-time upgrade path: an existing single-user install keeps all its
  /// settings in what is now the default profile's ConfigBox. On first launch
  /// after the split, seed the shared app box from it so the user's theme,
  /// language, units and so on carry across untouched.
  Future<void> migrateAppConfigFromProfile() async {
    if (_appBox.containsKey(_configKey)) return;
    final profile = _profileBox.get(_configKey);
    if (profile != null) {
      await _appBox.put(_configKey, ConfigDBO.fromJson(profile.toJson()));
    }
  }

  Future<void> addConfig(ConfigDBO configDBO) async {
    _log.fine('Adding new config item to db');
    await _writeBoth(configDBO);
  }

  Future<void> _update(void Function(ConfigDBO config) mutate) async {
    final config = _readMerged();
    mutate(config);
    await _writeBoth(config);
  }

  Future<void> setConfigDisclaimer(bool hasAcceptedDisclaimer) async {
    await _update((c) => c.hasAcceptedDisclaimer = hasAcceptedDisclaimer);
  }

  Future<void> setConfigAcceptedAnonymousData(
    bool hasAcceptedAnonymousData,
  ) async {
    await _update(
      (c) => c.hasAcceptedSendAnonymousData = hasAcceptedAnonymousData,
    );
  }

  Future<void> setConfigAcceptedPolicy(bool hasAcceptedPolicy) async {
    await _update((c) => c.hasAcceptedPolicy = hasAcceptedPolicy);
  }

  /// Records that the user has been shown the policy-change notice for
  /// [revision]. Device-wide: it is not in [_readMerged]'s personal-field
  /// overlay, so it is read from the shared app box and a second profile is
  /// not notified again.
  Future<void> setConfigPolicyNoticeRevisionSeen(int revision) async {
    await _update((c) => c.policyNoticeRevisionSeen = revision);
  }

  Future<AppThemeDBO> getAppTheme() async => _readMerged().selectedAppTheme;

  Future<void> setConfigAppTheme(AppThemeDBO appTheme) async {
    await _update((c) => c.selectedAppTheme = appTheme);
  }

  Future<void> setConfigUsesImperialUnits(bool usesImperialUnits) async {
    await _update((c) => c.usesImperialUnits = usesImperialUnits);
  }

  Future<void> setConfigUsesImperialFoodUnits(bool usesImperial) async {
    // Mirror the legacy single flag to the food choice so a downgrade to an
    // older build (which only knows usesImperialUnits) still reads a coherent
    // value. Height and body weight can't be expressed by one bool, so they
    // don't mirror.
    await _update((c) {
      c.usesImperialFoodUnits = usesImperial;
      c.usesImperialUnits = usesImperial;
    });
  }

  Future<void> setConfigUsesImperialHeightUnits(bool usesImperial) async {
    await _update((c) => c.usesImperialHeightUnits = usesImperial);
  }

  Future<void> setConfigBodyWeightUnitIndex(int index) async {
    await _update((c) => c.bodyWeightUnitIndex = index);
  }

  Future<double> getKcalAdjustment() async =>
      _readMerged().userKcalAdjustment ?? 0;

  Future<void> setConfigKcalAdjustment(double kcalAdjustment) async {
    await _update((c) => c.userKcalAdjustment = kcalAdjustment);
  }

  Future<void> setConfigCarbGoalPct(double carbGoalPct) async {
    await _update((c) => c.userCarbGoalPct = carbGoalPct);
  }

  Future<void> setConfigProteinGoalPct(double proteinGoalPct) async {
    await _update((c) => c.userProteinGoalPct = proteinGoalPct);
  }

  Future<void> setConfigFatGoalPct(double fatGoalPct) async {
    await _update((c) => c.userFatGoalPct = fatGoalPct);
  }

  Future<void> setConfigShowActivityTracking(bool show) async {
    await _update((c) => c.showActivityTracking = show);
  }

  Future<void> setConfigShowMealMacros(bool show) async {
    await _update((c) => c.showMealMacros = show);
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    await _update((c) => c.notificationsEnabled = enabled);
  }

  Future<void> setNotificationTime(int hour, int minute) async {
    await _update((c) {
      c.notificationHour = hour;
      c.notificationMinute = minute;
    });
  }

  Future<String?> getSelectedLocale() async {
    final raw = _readMerged().selectedLocale;
    // Backward-compat: the project used to ship Czech as 'cz' (non-standard).
    // It was renamed to the BCP-47 code 'cs' so iOS surfaces it correctly in
    // its system language picker. Migrate any stored 'cz' value silently so
    // existing users keep their language preference across the rename.
    if (raw == 'cz') return 'cs';
    return raw;
  }

  Future<void> setSelectedLocale(String? locale) async {
    await _update((c) => c.selectedLocale = locale);
  }

  Future<void> setConfigShowMicronutrients(bool show) async {
    await _update((c) => c.showMicronutrients = show);
  }

  Future<void> setConfigUsesKilojoules(bool usesKilojoules) async {
    await _update((c) => c.usesKilojoules = usesKilojoules);
  }

  Future<void> setConfigMealKcalSharesPct(Map<String, int> shares) async {
    // Copy into a fresh map so Hive sees a distinct object reference on save.
    await _update((c) => c.mealKcalSharesPct = Map<String, int>.from(shares));
  }

  Future<String?> getCustomMealFormMode() async =>
      _readMerged().customMealFormMode;

  Future<void> setCustomMealFormMode(String mode) async {
    await _update((c) => c.customMealFormMode = mode);
  }

  Future<Map<String, int>?> getDiarySortPreferences() async {
    final stored = _readMerged().diarySortPreferences;
    if (stored == null) return null;
    // Eagerly copy into a concrete Map<String, int> rather than handing back
    // a lazy cast view that could throw on access.
    return Map<String, int>.from(stored);
  }

  Future<void> setDiarySortPreference(String mealKey, int sortIndex) async {
    await _update((c) {
      final current = c.diarySortPreferences;
      c.diarySortPreferences = <String, int>{
        if (current != null) ...Map<String, int>.from(current),
        mealKey: sortIndex,
      };
    });
  }

  Future<void> setConfigNutrientPanelVisibility(
    Map<String, bool> visibility,
  ) async {
    // Persist a defensive copy — a caller-owned map mutating later would
    // otherwise silently change the saved value.
    await _update(
      (c) => c.nutrientPanelVisibility = Map<String, bool>.from(visibility),
    );
  }

  Future<void> setConfigDayStartOffsetHours(int hours) async {
    await _update((c) => c.dayStartOffsetHours = hours);
  }

  Future<void> setConfigDayStartOffsetMinutes(int minutes) async {
    await _update((c) => c.dayStartOffsetMinutes = minutes);
  }

  Future<void> setConfigDailyWaterGoalMl(int goalMl) async {
    await _update((c) => c.dailyWaterGoalMl = goalMl);
  }

  Future<void> setFastingWarningAcknowledged(bool acknowledged) async {
    await _update((c) => c.fastingWarningAcknowledged = acknowledged);
  }

  Future<void> setIsDemoData(bool isDemoData) async {
    await _update((c) => c.isDemoData = isDemoData);
  }

  Future<void> setConfigUseMaterialYou(bool useMaterialYou) async {
    await _update((c) => c.useMaterialYou = useMaterialYou);
  }

  Future<void> setConfigAccentColor(int? value) async {
    await _update((c) => c.accentColor = value);
  }

  Future<void> setConfigScannerPortraitLock(bool value) async {
    await _update((c) => c.scannerPortraitLock = value);
  }

  /// Per-source enable flags for the food search, keyed by backend
  /// food_source code. Null means the user never touched the setting —
  /// every source is enabled. Returned as a defensive copy.
  Future<Map<String, bool>?> getFoodSourceToggles() async {
    final stored = _readMerged().foodSourceToggles;
    if (stored == null) return null;
    return Map<String, bool>.from(stored);
  }

  Future<void> setConfigFoodSourceToggles(Map<String, bool> toggles) async {
    // Copy into a fresh map so Hive sees a distinct object reference on save.
    await _update((c) => c.foodSourceToggles = Map<String, bool>.from(toggles));
  }

  Future<void> setConfigHealthImportEnabled(bool enabled) async {
    await _update((c) => c.healthImportEnabled = enabled);
  }

  Future<void> setConfigHealthWorkoutKcalMultiplier(double multiplier) async {
    await _update((c) => c.healthWorkoutKcalMultiplier = multiplier);
  }

  Future<void> setConfigHealthLastImportAt(DateTime? importedAt) async {
    await _update((c) => c.healthLastImportAt = importedAt);
  }

  /// Records that the imported workout behind [externalId], which started at
  /// [startedAt], was deleted — so the importer stops re-creating it.
  ///
  /// [startedAt] is the workout's own start time rather than the moment of
  /// deletion, because it is what the import window is compared against: the
  /// tombstone stops being useful when the *workout* falls out of range, not
  /// when the deletion does. Writes a fresh map so Hive sees a distinct object
  /// reference on save.
  Future<void> addConfigHealthDeletedWorkout(
    String externalId,
    DateTime startedAt,
  ) async {
    await _update((c) {
      final current = _mergedDeletedWorkouts(c);
      if (current[externalId] == startedAt) return;
      c.healthDeletedWorkouts = {...current, externalId: startedAt};
      c.healthDeletedExternalIds = null;
    });
  }

  /// Drops tombstones for workouts that started before [cutoff].
  ///
  /// Those can never match again — the platform will not return them for any
  /// window a future import asks for — so they are dead weight rather than
  /// protection. See `ConfigEntity.oldestUsefulTombstone` for how the caller
  /// arrives at [cutoff]. A no-op when nothing is stale, so the common case
  /// costs no write.
  Future<void> pruneConfigHealthDeletedWorkouts(DateTime cutoff) async {
    await _update((c) {
      final current = _mergedDeletedWorkouts(c);
      final kept = <String, DateTime>{
        for (final entry in current.entries)
          if (!entry.value.isBefore(cutoff)) entry.key: entry.value,
      };
      if (kept.length == current.length && c.healthDeletedExternalIds == null) {
        return;
      }
      c.healthDeletedWorkouts = kept;
      c.healthDeletedExternalIds = null;
    });
  }

  /// The dated tombstones, with any undated legacy ids folded in.
  ///
  /// Before #768 a tombstone was an id with no date, so there is nothing to
  /// compare a legacy entry against. It is dated *now* instead, which keeps it
  /// for one more full window and then lets it drain — erring toward keeping a
  /// deletion honoured, which is the direction that cannot annoy anyone.
  ///
  /// Only pre-release installs can carry any: #651 has not shipped. This can
  /// be deleted once 2.1.0 is out and no dev build predates it.
  static Map<String, DateTime> _mergedDeletedWorkouts(ConfigDBO config) {
    final dated = config.healthDeletedWorkouts ?? const <String, DateTime>{};
    final legacy = config.healthDeletedExternalIds;
    if (legacy == null || legacy.isEmpty) return dated;
    final now = DateTime.now();
    return {for (final id in legacy) id: now, ...dated};
  }

  Future<ConfigDBO> getConfig() async => _readMerged();

  Future<bool> getHasAcceptedAnonymousData() async =>
      _readMerged().hasAcceptedSendAnonymousData;
}
