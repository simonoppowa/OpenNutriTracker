import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:opennutritracker/core/data/repository/config_repository.dart';
import 'package:opennutritracker/core/domain/entity/app_theme_entity.dart';
import 'package:opennutritracker/core/domain/usecase/add_config_usecase.dart';
import 'package:opennutritracker/core/utils/demo/demo_seeder.dart';
import 'package:opennutritracker/core/utils/locator.dart';
import 'package:opennutritracker/core/utils/logger_config.dart';
import 'package:opennutritracker/main.dart';

/// Dev-only entry point for shooting the README and Play Store
/// screenshots. Identical to `lib/dev/main_dev.dart` except for two
/// things:
///
///  * the seed preset — [DemoSeedOptions.screenshots] leaves `isDemoData`
///    unset, so the demo banner stays out of the frame (see
///    `demo_mode_banner.dart`);
///  * theme, locale and Material You are pinned rather than inherited from
///    the capture device. Material You defaults on
///    (`ConfigEntity.useMaterialYou`), so the accent would otherwise come
///    from the device wallpaper — that is how the previous screenshot set
///    came out purple. Theme and locale follow the system too, so a phone
///    in dark mode and German produces dark German frames. Pinned, the
///    same command yields identical light, English, leaf-green captures
///    anywhere.
///
/// Run with `just screenshots`, then drive the capture with
/// `tools/adb/capture-screenshots.sh`.
Future<void> main() async {
  if (kReleaseMode) {
    throw UnsupportedError(
      'lib/dev/main_screenshots.dart seeds demo data and must never be built in release mode',
    );
  }

  WidgetsFlutterBinding.ensureInitialized();
  LoggerConfig.intiLogger();
  await initLocator();

  await seedDemoData(DemoSeedOptions.screenshots);

  // Pin everything the capture device would otherwise decide for us, so the
  // same command produces the same frames on any phone or emulator.
  final addConfig = locator<AddConfigUsecase>();
  await addConfig.setConfigUseMaterialYou(false);
  await addConfig.setConfigAppTheme(AppThemeEntity.light);
  await addConfig.setSelectedLocale('en');

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
