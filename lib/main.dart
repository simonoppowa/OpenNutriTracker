import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:logging/logging.dart';
import 'package:opennutritracker/core/data/data_source/config_data_source.dart';
import 'package:opennutritracker/core/data/data_source/intake_data_source.dart';
import 'package:opennutritracker/core/data/data_source/physical_activity_data_source.dart';
import 'package:opennutritracker/core/data/data_source/tracked_day_data_source.dart';
import 'package:opennutritracker/core/data/data_source/user_activity_data_source.dart';
import 'package:opennutritracker/core/data/data_source/user_data_source.dart';
import 'package:opennutritracker/core/data/repository/config_repository.dart';
import 'package:opennutritracker/core/data/repository/intake_repository.dart';
import 'package:opennutritracker/core/data/repository/physical_activity_repository.dart';
import 'package:opennutritracker/core/data/repository/tracked_day_repository.dart';
import 'package:opennutritracker/core/data/repository/user_activity_repository.dart';
import 'package:opennutritracker/core/data/repository/user_repository.dart';
import 'package:opennutritracker/core/presentation/main_screen.dart';
import 'package:opennutritracker/core/styles/color_schemes.dart';
import 'package:opennutritracker/core/styles/fonts.dart';
import 'package:opennutritracker/core/utils/hive_db_provider.dart';
import 'package:opennutritracker/core/utils/logger_config.dart';
import 'package:opennutritracker/core/utils/navigation_options.dart';
import 'package:opennutritracker/core/utils/secure_app_storage_provider.dart';
import 'package:opennutritracker/features/activity_detail/activity_detail_screen.dart';
import 'package:opennutritracker/features/add_meal/presentation/add_item_screen.dart';
import 'package:opennutritracker/features/add_activity/presentation/add_activity_screen.dart';
import 'package:opennutritracker/features/diary/presentation/bloc/diary_bloc.dart';
import 'package:opennutritracker/features/home/presentation/bloc/home_bloc.dart';
import 'package:opennutritracker/features/onboarding/onboarding_screen.dart';
import 'package:opennutritracker/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:opennutritracker/features/scanner/scanner_screen.dart';
import 'package:opennutritracker/features/meal_detail/meal_detail_screen.dart';
import 'package:opennutritracker/features/settings/settings_screen.dart';
import 'package:opennutritracker/generated/l10n.dart';
import 'package:provider/provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  LoggerConfig.intiLogger();
  final secureAppStorageProvider = SecureAppStorageProvider();
  final hiveDBProvider = HiveDBProvider();
  await hiveDBProvider
      .initHiveDB(await secureAppStorageProvider.getHiveEncryptionKey());
  final ConfigDataSource configDataSource =
      ConfigDataSource(hiveDBProvider.configBox);
  final IntakeDataSource intakeDataSource =
      IntakeDataSource(hiveDBProvider.intakeBox);
  final userActivityDataSource =
      UserActivityDataSource(hiveDBProvider.userActivityBox);
  final physicalActivityDataSource = PhysicalActivityDataSource();
  final UserDataSource userDataSource = UserDataSource(hiveDBProvider.userBox);
  final TrackedDayDataSource trackedDayDataSource =
      TrackedDayDataSource(hiveDBProvider.trackedDayBox);

  await initializeConfig(configDataSource);
  final userInitialized = await userDataSource.hasUserData();

  final log = Logger('main');
  log.info('Starting App ...');

  runApp(MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => hiveDBProvider),
        BlocProvider<HomeBloc>(create: (context) => HomeBloc()),
        BlocProvider<DiaryBloc>(create: (context) => DiaryBloc()),
        BlocProvider<ProfileBloc>(create: (context) => ProfileBloc()),
        RepositoryProvider(
            create: (context) => ConfigRepository(configDataSource)),
        RepositoryProvider(
            create: (context) => IntakeRepository(intakeDataSource)),
        RepositoryProvider(
            create: (context) =>
                UserActivityRepository(userActivityDataSource)),
        RepositoryProvider(create: (context) => UserRepository(userDataSource)),
        RepositoryProvider(
            create: (context) => TrackedDayRepository(trackedDayDataSource))
      ],
      child: OpenNutriTrackerApp(
        userInitialized: userInitialized,
      )));
}

Future<void> initializeConfig(ConfigDataSource configDataSource) async {
  if (!await configDataSource.configInitialized()) {
    configDataSource.initializeConfig();
  }
}

class OpenNutriTrackerApp extends StatelessWidget {
  final bool userInitialized;

  const OpenNutriTrackerApp({super.key, required this.userInitialized});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      onGenerateTitle: (context) => S.of(context).appTitle,
      theme: ThemeData(
          useMaterial3: true,
          colorScheme: lightColorScheme,
          textTheme: appTextTheme),
      // darkTheme: ThemeData(
      //     useMaterial3: true,
      //     colorScheme: darkColorScheme,
      //     textTheme: appTextTheme),
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
        NavigationOptions.addItemRoute: (context) => const AddItemScreen(),
        NavigationOptions.scannerRoute: (context) => const ScannerScreen(),
        NavigationOptions.itemDetailRoute: (context) =>
            const MealDetailScreen(),
        NavigationOptions.addActivityRoute: (context) =>
            const AddActivityScreen(),
        NavigationOptions.activityDetailRoute: (context) =>
            const ActivityDetailScreen()
      },
    );
  }
}
