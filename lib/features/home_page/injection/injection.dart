import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';

import '../data/datasources/home_remote_data_source.dart';
import '../data/repositories/home_repository_impl.dart';

import '../domain/repositories/home_repository.dart';
import '../domain/usecases/get_trips.dart';
import '../domain/usecases/get_today_trips.dart';
import '../domain/usecases/get_total_inject.dart';
import '../domain/usecases/get_sisa_dana.dart';
import '../domain/usecases/get_total_transaksi.dart';
import '../domain/usecases/toggle_spd_subscription.dart';
import '../domain/usecases/refresh_trips.dart';
import '../domain/usecases/clear_trips_cache.dart';
import '../domain/usecases/get_trip_expenses.dart';
import 'package:trips_apps/features/perjalanan/domain/usecases/refresh_perjalanan.dart';

import '../presentation/bloc/home_page_bloc.dart';
import 'package:trips_apps/core/services/refresh_coordinator.dart';

final sl = GetIt.instance;

void initHomeModule() {
  /// External deps are registered in core init

  /// ===== Data Layer =====
  if (!sl.isRegistered<HomeRemoteDataSource>()) {
    sl.registerLazySingleton<HomeRemoteDataSource>(
      () => HomeRemoteDataSourceImpl(sl<Dio>(), sl<SharedPreferences>()),
    );
  }

  if (!sl.isRegistered<HomeRepository>()) {
    sl.registerLazySingleton<HomeRepository>(
      () => HomeRepositoryImpl(
        sl<HomeRemoteDataSource>(),
        sl<SharedPreferences>(),
      ),
    );
  }

  /// ===== Domain Layer =====
  /// ===== Domain Layer =====
  if (!sl.isRegistered<GetTrips>()) {
    sl.registerLazySingleton<GetTrips>(() => GetTrips(sl()));
  }

  if (!sl.isRegistered<GetTodayTrips>()) {
    sl.registerLazySingleton<GetTodayTrips>(() => GetTodayTrips(sl()));
  }

  if (!sl.isRegistered<GetTotalInject>()) {
    sl.registerLazySingleton<GetTotalInject>(() => GetTotalInject(sl()));
  }

  if (!sl.isRegistered<GetSisaDana>()) {
    sl.registerLazySingleton<GetSisaDana>(() => GetSisaDana(sl()));
  }

  if (!sl.isRegistered<GetTotalTransaksi>()) {
    sl.registerLazySingleton<GetTotalTransaksi>(() => GetTotalTransaksi(sl()));
  }

  if (!sl.isRegistered<ToggleSpdSubscription>()) {
    sl.registerLazySingleton<ToggleSpdSubscription>(
      () => ToggleSpdSubscription(sl()),
    );
  }

  if (!sl.isRegistered<RefreshTrips>()) {
    sl.registerLazySingleton<RefreshTrips>(() => RefreshTrips(sl()));
  }

  if (!sl.isRegistered<ClearTripsCache>()) {
    sl.registerLazySingleton<ClearTripsCache>(() => ClearTripsCache(sl()));
  }

  if (!sl.isRegistered<GetTripExpenses>()) {
    // depends on TripDetail's GetTripItems usecase which should be registered
    sl.registerLazySingleton<GetTripExpenses>(() => GetTripExpenses(sl()));
  }

  /// ===== Presentation Layer =====
  if (!sl.isRegistered<HomePageBloc>()) {
    sl.registerFactory<HomePageBloc>(
      () => HomePageBloc(
        getTrips: sl(),
        getTodayTrips: sl(),
        getTripExpenses: sl(),
        toggleSpdUsecase: sl(),
        getTotalInject: sl(),
        getSisaDana: sl(),
        getTotalTransaksi: sl(),
        refreshTrips: sl(),
        refreshPerjalanan: sl.isRegistered<RefreshPerjalananUseCase>()
            ? sl<RefreshPerjalananUseCase>()
            : null,
      ),
    );
  }

  // Register home refresh with central coordinator so other features can trigger it.
  RefreshCoordinator.instance.register(
    'home',
    () => sl<HomeRepository>().refreshTrips(),
  );
}
