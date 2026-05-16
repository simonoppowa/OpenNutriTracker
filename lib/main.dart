import 'dart:async';

import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:logging/logging.dart';
import 'package:opennutritracker/core/data/data_source/remote_search_cache_data_source.dart';
import 'package:opennutritracker/core/data/data_source/user_data_source.dart';
import 'package:opennutritracker/core/data/repository/config_repository.dart';
import 'package:opennutritracker/core/domain/entity/app_theme_entity.dart';
import 'package:opennutritracker/core/presentation/main_screen.dart';
import 'package:opennutritracker/core/presentation/widgets/image_full_screen.dart';
import 'package:opennutritracker/core/styles/color_schemes.dart';
import 'package:opennutritracker/core/styles/fonts.dart';
import 'package:opennutritracker/core/utils/env.dart';
import 'package:opennutritracker/core/utils/locator.dart';
import 'package:opennutritracker/core/utils/logger_config.dart';
import 'package:opennutritracker/core/utils/notification_service.dart';
import 'package:opennutritracker/core/utils/navigation_options.dart';
import 'package:opennutritracker/core/utils/energy_unit_provider.dart';
import 'package:opennutritracker/core/utils/locale_provider.dart';
import 'package:opennutritracker/core/utils/theme_mode_provider.dart';
import 'package:opennutritracker/features/activity_detail/activity_detail_screen.dart';
import 'package:opennutritracker/features/add_meal/presentation/add_meal_screen.dart';
import 'package:opennutritracker/features/add_activity/presentation/add_activity_screen.dart';
import 'package:opennutritracker/features/edit_meal/presentation/edit_meal_screen.dart';
import 'package:opennutritracker/features/onboarding/onboarding_screen.dart';
import 'package:opennutritracker/features/profile/presentation/weight_history_screen.dart';
import 'package:opennutritracker/features/recipes/presentation/screens/import_recipe_scanner_screen.dart';
import 'package:opennutritracker/features/recipes/presentation/screens/recipe_builder_screen.dart';
import 'package:opennutritracker/features/recipes/presentation/screens/recipe_detail_screen.dart';
import 'package:opennutritracker/features/recipes/presentation/screens/recipes_page.dart';
import 'package:opennutritracker/features/home/presentation/screens/import_activity_scanner_screen.dart';
import 'package:opennutritracker/features/home/presentation/screens/import_meal_scanner_screen.dart';
import 'package:opennutritracker/features/scanner/scanner_screen.dart';
import 'package:opennutritracker/features/meal_detail/meal_detail_screen.dart';
import 'package:opennutritracker/features/settings/presentation/widgets/accent_colour_screen.dart';
import 'package:opennutritracker/features/settings/settings_screen.dart';
import 'package:opennutritracker/generated/l10n.dart';
import 'package:provider/provider.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  LoggerConfig.intiLogger();
  await initLocator();

  // Drop cached remote-search results that haven't been touched in 90
  // days. Done once per app start; no need to schedule a recurring task.
  unawaited(
    locator<RemoteSearchCacheDataSource>().pruneStale(const Duration(days: 90)),
  );

  final isUserInitialized = await locator<UserDataSource>().hasUserData();
  final configRepo = locator<ConfigRepository>();

  // #312: Restore scheduled notifications after app start / device reboot
  final config = await configRepo.getConfig();
  if (config.notificationsEnabled) {
    final notificationService = locator<NotificationService>();
    await notificationService.initialize();
    await notificationService.scheduleDailyReminder(
      hour: config.notificationHour,
      minute: config.notificationMinute,
      title: 'OpenNutriTracker',
      body: 'Don\'t forget to log your meals today!',
    );
  }
  final hasAcceptedAnonymousData =
      await configRepo.getConfigHasAcceptedAnonymousData();
  final savedAppTheme = await configRepo.getConfigAppTheme();
  final savedLocaleCode = await configRepo.getSelectedLocale();
  final savedLocale =
      savedLocaleCode != null ? Locale(savedLocaleCode) : null;
  final savedUsesKilojoules = config.usesKilojoules;
  final savedUseMaterialYou = config.useMaterialYou;
  final savedAccentColor = config.accentColor;
  final log = Logger('main');

  // If the user has accepted anonymous data collection, run the app with
  // sentry enabled, else run without it
  if (kReleaseMode && hasAcceptedAnonymousData) {
    log.info('Starting App with Sentry enabled ...');
    _runAppWithSentryReporting(isUserInitialized, savedAppTheme, savedLocale,
        savedUsesKilojoules, savedUseMaterialYou, savedAccentColor);
  } else {
    log.info('Starting App ...');
    runAppWithChangeNotifiers(isUserInitialized, savedAppTheme, savedLocale,
        savedUsesKilojoules, savedUseMaterialYou, savedAccentColor);
  }
}

void _runAppWithSentryReporting(
  bool isUserInitialized,
  AppThemeEntity savedAppTheme,
  Locale? savedLocale,
  bool savedUsesKilojoules,
  bool savedUseMaterialYou,
  int? savedAccentColor,
) async {
  await SentryFlutter.init(
    (options) {
      options.dsn = Env.sentryDns;
      options.tracesSampleRate = 1.0;
    },
    appRunner: () => runAppWithChangeNotifiers(isUserInitialized, savedAppTheme,
        savedLocale, savedUsesKilojoules, savedUseMaterialYou, savedAccentColor),
  );
}

void runAppWithChangeNotifiers(
  bool userInitialized,
  AppThemeEntity savedAppTheme,
  Locale? savedLocale,
  bool savedUsesKilojoules,
  bool savedUseMaterialYou,
  int? savedAccentColor,
) =>
    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(
            create: (_) => ThemeModeProvider(
              appTheme: savedAppTheme,
              useMaterialYou: savedUseMaterialYou,
              accentColor: savedAccentColor,
            ),
          ),
          ChangeNotifierProvider(
            create: (_) => LocaleProvider(locale: savedLocale),
          ),
          ChangeNotifierProvider(
            create: (_) =>
                EnergyUnitProvider(usesKilojoules: savedUsesKilojoules),
          ),
        ],
        child: OpenNutriTrackerApp(userInitialized: userInitialized),
      ),
    );

class OpenNutriTrackerApp extends StatelessWidget {
  final bool userInitialized;

  const OpenNutriTrackerApp({super.key, required this.userInitialized});

  @override
  Widget build(BuildContext context) {
    // #415: DynamicColorBuilder hands back null on platforms that don't
    // support wallpaper-derived colours (iOS, older Android, desktop test
    // builds), so the static palette always remains as a graceful fallback.
    final themeProvider = Provider.of<ThemeModeProvider>(context);
    final useMaterialYou = themeProvider.useMaterialYou;
    final accentColor = themeProvider.accentColor;
    return DynamicColorBuilder(
      builder: (lightDynamic, darkDynamic) {
        final ColorScheme lightScheme;
        final ColorScheme darkScheme;
        if (useMaterialYou && lightDynamic != null && darkDynamic != null) {
          lightScheme = lightDynamic.harmonized();
          darkScheme = darkDynamic.harmonized();
        } else if (accentColor != null) {
          final seed = Color(accentColor);
          lightScheme = ColorScheme.fromSeed(seedColor: seed);
          darkScheme = ColorScheme.fromSeed(
            seedColor: seed,
            brightness: Brightness.dark,
          );
        } else {
          lightScheme = lightColorScheme;
          darkScheme = darkColorScheme;
        }
        return _buildMaterialApp(context, lightScheme, darkScheme);
      },
    );
  }

  Widget _buildMaterialApp(
    BuildContext context,
    ColorScheme lightScheme,
    ColorScheme darkScheme,
  ) {
    return MaterialApp(
      onGenerateTitle: (context) => S.of(context).appTitle,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: lightScheme,
        textTheme: appTextTheme,
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: darkScheme,
        textTheme: appTextTheme,
      ),
      themeMode: Provider.of<ThemeModeProvider>(context).themeMode,
      locale: Provider.of<LocaleProvider>(context).locale,
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: S.delegate.supportedLocales,
      initialRoute: userInitialized
          ? NavigationOptions.mainRoute
          : NavigationOptions.onboardingRoute,
      routes: {
        NavigationOptions.mainRoute: (context) => const MainScreen(),
        NavigationOptions.onboardingRoute: (context) =>
            const OnboardingScreen(),
        NavigationOptions.settingsRoute: (context) => const SettingsScreen(),
        NavigationOptions.accentColourRoute: (context) =>
            const AccentColourScreen(),
        NavigationOptions.addMealRoute: (context) => const AddMealScreen(),
        NavigationOptions.scannerRoute: (context) => const ScannerScreen(),
        NavigationOptions.mealDetailRoute: (context) =>
            const MealDetailScreen(),
        NavigationOptions.editMealRoute: (context) => const EditMealScreen(),
        NavigationOptions.addActivityRoute: (context) =>
            const AddActivityScreen(),
        NavigationOptions.activityDetailRoute: (context) =>
            const ActivityDetailScreen(),
        NavigationOptions.imageFullScreenRoute: (context) =>
            const ImageFullScreen(),
        NavigationOptions.importMealScannerRoute: (context) =>
            const ImportMealScannerScreen(),
        NavigationOptions.importActivityScannerRoute: (context) =>
            const ImportActivityScannerScreen(),
        NavigationOptions.recipesRoute: (context) => const RecipesPage(),
        NavigationOptions.recipeBuilderRoute: (context) =>
            const RecipeBuilderScreen(),
        NavigationOptions.recipeDetailRoute: (context) =>
            const RecipeDetailScreen(),
        NavigationOptions.importRecipeScannerRoute: (context) =>
            const ImportRecipeScannerScreen(),
        NavigationOptions.weightHistoryRoute: (context) =>
            const WeightHistoryScreen(),
      },
    );
  }
}
