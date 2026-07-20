import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:opennutritracker/core/data/repository/config_repository.dart';
import 'package:opennutritracker/core/utils/locator.dart';
import 'package:opennutritracker/core/utils/logger_config.dart';
import 'package:opennutritracker/dev/demo_data_seeder.dart';
import 'package:opennutritracker/main.dart';

/// Dev-only entry point: wipes the active profile and reseeds it with
/// realistic demo data (user, a week of meals and activities, weight/water
/// history, a recipe, fasting sessions), then boots straight past
/// onboarding.
///
/// Run with `flutter run -t lib/dev/main_dev.dart` (or `just dev_seed`)
/// instead of the normal `flutter run` when you want a populated app to
/// test against rather than walking onboarding by hand on every run.
Future<void> main() async {
  if (kReleaseMode) {
    throw UnsupportedError(
      'lib/dev/main_dev.dart seeds demo data and must never be built in release mode',
    );
  }

  WidgetsFlutterBinding.ensureInitialized();
  LoggerConfig.intiLogger();
  await initLocator();

  await seedDemoData();

  final configRepo = locator<ConfigRepository>();
  final config = await configRepo.getConfig();
  final savedLocaleCode = await configRepo.getSelectedLocale();
  final savedLocale =
      savedLocaleCode != null ? Locale(savedLocaleCode) : null;
  final savedAppTheme = await configRepo.getConfigAppTheme();

  runAppWithChangeNotifiers(
    true,
    savedAppTheme,
    savedLocale,
    config.usesKilojoules,
    config.useMaterialYou,
    config.accentColor,
  );
}
