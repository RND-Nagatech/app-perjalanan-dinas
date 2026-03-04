import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';

import '../data/datasources/app_update_remote_data_source.dart';
import '../data/repositories/app_update_repository_impl.dart';
import '../domain/repositories/app_update_repository.dart';
import '../domain/usecases/check_app_update.dart';
import '../presentation/cubit/app_update_cubit.dart';

final sl = GetIt.instance;

void initAppUpdateModule() {
  const manifestUrl = String.fromEnvironment(
    'APP_UPDATE_MANIFEST_URL',
    defaultValue:
        'https://raw.githubusercontent.com/RND-Nagatech/app-perjalanan-dinas/main/deploy/update/app-update.json',
  );

  if (!sl.isRegistered<AppUpdateRemoteDataSource>()) {
    sl.registerLazySingleton<AppUpdateRemoteDataSource>(
      () => AppUpdateRemoteDataSourceImpl(
        dio: sl<Dio>(),
        manifestUrl: manifestUrl,
      ),
    );
  }

  if (!sl.isRegistered<AppUpdateRepository>()) {
    sl.registerLazySingleton<AppUpdateRepository>(
      () => AppUpdateRepositoryImpl(sl<AppUpdateRemoteDataSource>()),
    );
  }

  if (!sl.isRegistered<CheckAppUpdate>()) {
    sl.registerLazySingleton<CheckAppUpdate>(
      () => CheckAppUpdate(sl<AppUpdateRepository>()),
    );
  }

  if (!sl.isRegistered<AppUpdateCubit>()) {
    sl.registerFactory<AppUpdateCubit>(
      () => AppUpdateCubit(checkAppUpdate: sl<CheckAppUpdate>()),
    );
  }
}
