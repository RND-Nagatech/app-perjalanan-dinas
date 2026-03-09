// External types (Dio, SharedPreferences, etc.) are provided by core init
import 'package:get_it/get_it.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:perjalanan_dinas/features/Auth/domain/repositories/auth_repository.dart';

import '../data/datasources/auth_remote_data_source.dart';
import '../data/repositories/auth_repository_impl.dart';
import '../domain/usecases/get_current_user_usecase.dart';
import '../domain/usecases/login_usecase.dart';
import '../domain/usecases/logout_usecase.dart';
import '../domain/usecases/register_usecase.dart';
import '../domain/usecases/clear_saved_credentials_usecase.dart';
import '../presentation/bloc/auth_bloc.dart';
import '../../home_page/injection/injection.dart' as home_inject;
import 'package:perjalanan_dinas/features/home_page/domain/usecases/refresh_trips.dart';
import 'package:perjalanan_dinas/features/home_page/domain/usecases/clear_trips_cache.dart';
import 'package:perjalanan_dinas/core/services/refresh_coordinator.dart';

final GetIt getIt = GetIt.instance;

void initAuthModule() {
  /// ===============================
  /// External
  /// ===============================
  // External dependencies are provided by core init (Dio, SharedPreferences)

  /// ===============================
  /// Data Source
  /// ===============================
  getIt.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(getIt<Dio>()),
  );

  /// ===============================
  /// Repository (ABSTRACTION)
  /// ===============================
  getIt.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      getIt<AuthRemoteDataSource>(),
      getIt<SharedPreferences>(),
    ),
  );

  /// ===============================
  /// UseCases
  /// ===============================
  getIt.registerLazySingleton(() => LoginUseCase(getIt<AuthRepository>()));

  getIt.registerLazySingleton(() => RegisterUseCase(getIt<AuthRepository>()));

  getIt.registerLazySingleton(() => LogoutUseCase(getIt<AuthRepository>()));

  getIt.registerLazySingleton(
    () => GetCurrentUserUseCase(getIt<AuthRepository>()),
  );

  getIt.registerLazySingleton(
    () => ClearSavedCredentialsUseCase(getIt<AuthRepository>()),
  );

  /// ===============================
  /// Bloc
  /// ===============================
  // Register AuthBloc as a singleton so all resolves use the same instance
  if (!getIt.isRegistered<AuthBloc>()) {
    getIt.registerLazySingleton<AuthBloc>(
      () => AuthBloc(
        loginUseCase: getIt(),
        registerUseCase: getIt(),
        logoutUseCase: getIt(),
        getCurrentUserUseCase: getIt(),
        refreshTrips: getIt<RefreshTrips>(),
        clearTripsCache: getIt<ClearTripsCache>(),
        clearSavedCredentialsUseCase: getIt(),
        refreshCoordinator: RefreshCoordinator.instance,
      ),
    );
  }

  /// Init Home Module
  home_inject.initHomeModule();
}
