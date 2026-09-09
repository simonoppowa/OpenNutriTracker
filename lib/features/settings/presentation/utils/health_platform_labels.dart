/// What the platform health store is called in front of the user, and which
/// data types it is asked for.
///
/// Split out of `health_sync_screen.dart` because three presentation-layer
/// callers need these — the settings row, the sync screen, and the disclosure
/// dialog the screen shows — and the dialog reaching back into the screen for
/// them made the two libraries import each other.
library;

import 'dart:io' show Platform;

/// What the platform health store is called in front of the user. Both names
/// are product names, so they are deliberately not localized.
String get healthPlatformName =>
    Platform.isIOS ? 'Apple Health' : 'Health Connect';

/// Whether the platform health store is asked for body fat as well as
/// workouts, which decides whether the disclosure mentions it.
///
/// Only HealthKit is. Play's Health Connect permissions policy refused this
/// app READ_BODY_FAT as excessive for what it does, so Android reads workouts
/// alone and the calorie-credit suggestion falls back to the BMI-derived
/// percentile it already used for anyone with no body fat on record.
///
/// Kept in step with `HealthPackageService.readLatestBodyFatPercent`, which
/// returns null on Android for the same reason (#1123). If body fat is ever
/// read there again, both have to change together — a disclosure that omits
/// what is read is an under-disclosure, which is the direction Play
/// penalises.
bool get healthStoreReadsBodyFat => Platform.isIOS;
