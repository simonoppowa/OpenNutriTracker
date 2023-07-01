import 'package:get_it/get_it.dart';
import 'package:opennutritracker/core/data/data_source/config_data_source.dart';
import 'package:opennutritracker/core/data/data_source/user_data_source.dart';
import 'package:opennutritracker/core/data/repository/config_repository.dart';
import 'package:opennutritracker/core/data/repository/user_repository.dart';
import 'package:opennutritracker/core/domain/usecase/add_config_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/add_user_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_config_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_user_usecase.dart';
import 'package:opennutritracker/core/utils/hive_db_provider.dart';
import 'package:opennutritracker/core/utils/secure_app_storage_provider.dart';
import 'package:opennutritracker/features/activity_detail/presentation/bloc/activity_detail_bloc.dart';
import 'package:opennutritracker/features/home/presentation/bloc/home_bloc.dart';
import 'package:opennutritracker/features/meal_detail/presentation/bloc/meal_detail_bloc.dart';
import 'package:opennutritracker/features/onboarding/presentation/bloc/onboarding_bloc.dart';
import 'package:opennutritracker/features/profile/presentation/bloc/profile_bloc.dart';

final locator = GetIt.instance;

Future<void> initLocator() async {
  // Init secure storage and Hive database;
  final secureAppStorageProvider = SecureAppStorageProvider();
  final hiveDBProvider = HiveDBProvider();
  locator.registerSingleton<HiveDBProvider>(hiveDBProvider); // TODO remove
  await hiveDBProvider
      .initHiveDB(await secureAppStorageProvider.getHiveEncryptionKey());

  // BLoCs
  locator
      .registerLazySingleton<OnboardingBloc>(() => OnboardingBloc(locator()));
  locator.registerLazySingleton<HomeBloc>(
      () => HomeBloc(locator(), locator(), locator()));
  locator.registerLazySingleton<ActivityDetailBloc>(
      () => ActivityDetailBloc(locator()));
  locator
      .registerLazySingleton<MealDetailBloc>(() => MealDetailBloc(locator()));
  locator.registerLazySingleton<ProfileBloc>(
      () => ProfileBloc(locator(), locator()));

  // UseCases
  locator.registerLazySingleton<GetConfigUsecase>(
      () => GetConfigUsecase(locator()));
  locator.registerLazySingleton<AddConfigUsecase>(
      () => AddConfigUsecase(locator()));
  locator
      .registerLazySingleton<GetUserUsecase>(() => GetUserUsecase(locator()));
  locator
      .registerLazySingleton<AddUserUsecase>(() => AddUserUsecase(locator()));

  // Repositories
  locator.registerLazySingleton(() => ConfigRepository(locator()));
  locator
      .registerLazySingleton<UserRepository>(() => UserRepository(locator()));

  // DataSources
  locator
      .registerLazySingleton(() => ConfigDataSource(hiveDBProvider.configBox));
  locator.registerLazySingleton<UserDataSource>(
      () => UserDataSource(hiveDBProvider.userBox));
}
