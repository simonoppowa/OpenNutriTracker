import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:opennutritracker/core/data/repository/config_repository.dart';
import 'package:opennutritracker/core/utils/app_locale_service.dart';
import 'package:opennutritracker/core/utils/app_locale_sync.dart';
import 'package:opennutritracker/core/utils/demo/demo_seeder.dart';
import 'package:opennutritracker/core/utils/locator.dart';
import 'package:opennutritracker/core/utils/logger_config.dart';
import 'package:opennutritracker/generated/l10n.dart';
import 'package:opennutritracker/main.dart';

/// Dev-only entry point: wipes the active profile and reseeds it with
/// realistic demo data (user, a year of meals and activities, weight/water
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

  await seedDemoData(DemoSeedOptions.dev);

  final configRepo = locator<ConfigRepository>();
  final config = await configRepo.getConfig();
  // Mirrors the reconciliation in main.dart so a dev build behaves the same
  // way when the OS holds a per-app language.
  final localeCode = await reconcileAppLocale(
    savedLocaleCode: await configRepo.getSelectedLocale(),
    systemLocaleTag: await AppLocaleService.getApplicationLocale(),
    supportedLocales: S.supportedLocales,
    persistSelectedLocale: configRepo.setSelectedLocale,
    pushToSystem: AppLocaleService.setApplicationLocale,
  );
  final savedLocale = localeCode != null ? Locale(localeCode) : null;
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
