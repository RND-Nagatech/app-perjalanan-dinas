import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';

import '../../home_page/injection/injection.dart' as home_inject;
import 'package:trips_apps/features/perjalanan/data/datasources/perjalanan_remote_data_source.dart';
import 'package:trips_apps/features/perjalanan/data/repositories/perjalanan_repository_impl.dart';
import 'package:trips_apps/features/perjalanan/domain/repositories/perjalanan_repository.dart';
import 'package:trips_apps/features/perjalanan/domain/usecases/get_perjalanan.dart';
import 'package:trips_apps/features/perjalanan/domain/usecases/refresh_perjalanan.dart';
import 'package:trips_apps/features/perjalanan/presentation/bloc/perjalanan_bloc.dart';
import 'package:trips_apps/core/services/refresh_coordinator.dart';

final sl = GetIt.instance;

/// Initialize Perjalanan feature dependencies.
/// This feature registers its own datasource/repository/usecase but ensures
/// the Home module (and shared externals) are initialized first.
void initPerjalananModule() {
  // Ensure Home module is initialized (registers shared home usecases if needed)
  try {
    home_inject.initHomeModule();
  } catch (_) {}

  // External deps (Dio, SharedPreferences) come from core module
  if (!sl.isRegistered<PerjalananRemoteDataSource>()) {
    sl.registerLazySingleton<PerjalananRemoteDataSource>(
      () => PerjalananRemoteDataSourceImpl(sl<Dio>(), sl<SharedPreferences>()),
    );
  }

  if (!sl.isRegistered<PerjalananRepository>()) {
    sl.registerLazySingleton<PerjalananRepository>(
      () => PerjalananRepositoryImpl(
        sl<PerjalananRemoteDataSource>(),
        sl<SharedPreferences>(),
      ),
    );
  }

  if (!sl.isRegistered<GetPerjalanan>()) {
    sl.registerLazySingleton<GetPerjalanan>(() => GetPerjalanan(sl()));
  }

  // Register refresh callback with coordinator so Home refresh can trigger this feature
  try {
    RefreshCoordinator.instance.register(
      'perjalanan',
      () => sl<PerjalananRepository>().refreshPerjalanan(),
    );
  } catch (_) {}

  if (!sl.isRegistered<RefreshPerjalananUseCase>()) {
    sl.registerLazySingleton<RefreshPerjalananUseCase>(
      () => RefreshPerjalananUseCase(sl()),
    );
  }

  // Register Bloc factory
  if (!sl.isRegistered<PerjalananBloc>()) {
    sl.registerFactory(
      () => PerjalananBloc(sl<GetPerjalanan>(), sl<RefreshPerjalananUseCase>()),
    );
  }
}
