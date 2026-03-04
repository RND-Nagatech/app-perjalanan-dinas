import 'package:get_it/get_it.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/datasources/add_pengeluaran_remote_data_source.dart';
import '../data/repositories/add_pengeluaran_repository_impl.dart';
import '../domain/repositories/add_pengeluaran_repository.dart';
import '../domain/usecases/get_active_trips.dart';
import '../domain/usecases/create_item.dart';
import '../domain/usecases/upload_attachment.dart';
import '../presentation/bloc/add_pengeluaran_bloc.dart';

final sl = GetIt.instance;

void initAddPengeluaranModule() {
  if (!sl.isRegistered<AddPengeluaranRemoteDataSource>()) {
    sl.registerLazySingleton<AddPengeluaranRemoteDataSource>(
      () => AddPengeluaranRemoteDataSourceImpl(
        sl<Dio>(),
        sl<SharedPreferences>(),
      ),
    );
  }

  if (!sl.isRegistered<AddPengeluaranRepository>()) {
    sl.registerLazySingleton<AddPengeluaranRepository>(
      () => AddPengeluaranRepositoryImpl(sl<AddPengeluaranRemoteDataSource>()),
    );
  }

  if (!sl.isRegistered<GetActiveTrips>()) {
    sl.registerLazySingleton<GetActiveTrips>(
      () => GetActiveTrips(sl<AddPengeluaranRepository>()),
    );
  }

  if (!sl.isRegistered<CreateItem>()) {
    sl.registerLazySingleton<CreateItem>(
      () => CreateItem(sl<AddPengeluaranRepository>()),
    );
  }

  if (!sl.isRegistered<UploadAttachment>()) {
    sl.registerLazySingleton<UploadAttachment>(
      () => UploadAttachment(sl<AddPengeluaranRepository>()),
    );
  }

  if (!sl.isRegistered<AddPengeluaranBloc>()) {
    sl.registerFactory<AddPengeluaranBloc>(
      () => AddPengeluaranBloc(
        getActiveTrips: sl(),
        createItem: sl(),
        uploadAttachment: sl(),
      ),
    );
  }
}
