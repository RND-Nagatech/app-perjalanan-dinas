import 'package:get_it/get_it.dart';

import '../data/repositories/history_repository_impl.dart';
import '../domain/repositories/history_repository.dart';
import '../domain/usecases/get_history.dart';
import '../presentation/bloc/history_bloc.dart';
import '../data/datasources/history_remote_data_source.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import 'package:trips_apps/core/services/refresh_coordinator.dart';

final sl = GetIt.instance;

void initHistoryModule() {
  if (!sl.isRegistered<HistoryRepository>()) {
    // Register remote datasource first
    if (!sl.isRegistered<HistoryRemoteDataSource>()) {
      sl.registerLazySingleton<HistoryRemoteDataSource>(
        () => HistoryRemoteDataSourceImpl(sl<Dio>(), sl<SharedPreferences>()),
      );
    }

    sl.registerLazySingleton<HistoryRepository>(
      () => HistoryRepositoryImpl(sl<HistoryRemoteDataSource>()),
    );
  }

  if (!sl.isRegistered<GetHistory>()) {
    sl.registerLazySingleton<GetHistory>(() => GetHistory(sl()));
  }

  // Register a history refresh callback so Home can trigger a refresh for history
  try {
    RefreshCoordinator.instance.register('history', () async {
      // call repository to fetch/refresh; ignore returned list
      await sl<HistoryRepository>().fetchAll();
    });
  } catch (_) {}

  if (!sl.isRegistered<HistoryBloc>()) {
    sl.registerFactory<HistoryBloc>(() => HistoryBloc(sl()));
  }
}
