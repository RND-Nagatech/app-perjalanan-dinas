import 'package:get_it/get_it.dart';

import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/datasources/trip_detail_remote_datasource.dart';
import '../data/repositories/trip_detail_repository_impl.dart';
import '../domain/usecases/get_trip_items.dart';
import '../domain/usecases/get_trip_preview.dart';
import '../domain/usecases/submit_trip_for_audit.dart';
import '../domain/usecases/delete_trip_item.dart';
import '../domain/usecases/update_trip_item.dart';
import '../domain/usecases/clear_trip_item_attachments.dart';
import '../domain/usecases/upload_trip_item_attachment.dart';
import '../presentation/bloc/trip_detail_page_bloc.dart';
import 'package:trips_apps/core/services/refresh_coordinator.dart';

final sl = GetIt.instance;

void initTripDetailModule() {
  if (!sl.isRegistered<TripDetailRemoteDataSource>()) {
    sl.registerLazySingleton<TripDetailRemoteDataSource>(
      () => TripDetailRemoteDataSourceImpl(sl<Dio>(), sl<SharedPreferences>()),
    );
  }

  if (!sl.isRegistered<TripDetailRepositoryImpl>()) {
    sl.registerLazySingleton<TripDetailRepositoryImpl>(
      () => TripDetailRepositoryImpl(sl<TripDetailRemoteDataSource>()),
    );
  }

  if (!sl.isRegistered<GetTripItems>()) {
    sl.registerLazySingleton<GetTripItems>(
      () => GetTripItems(sl<TripDetailRepositoryImpl>()),
    );
  }

  if (!sl.isRegistered<GetTripPreview>()) {
    sl.registerLazySingleton<GetTripPreview>(
      () => GetTripPreview(sl<TripDetailRepositoryImpl>()),
    );
  }

  if (!sl.isRegistered<SubmitTripForAudit>()) {
    sl.registerLazySingleton<SubmitTripForAudit>(
      () => SubmitTripForAudit(sl<TripDetailRepositoryImpl>()),
    );
  }

  if (!sl.isRegistered<DeleteTripItem>()) {
    sl.registerLazySingleton<DeleteTripItem>(
      () => DeleteTripItem(sl<TripDetailRepositoryImpl>()),
    );
  }

  if (!sl.isRegistered<UpdateTripItem>()) {
    sl.registerLazySingleton<UpdateTripItem>(
      () => UpdateTripItem(sl<TripDetailRepositoryImpl>()),
    );
  }

  if (!sl.isRegistered<ClearTripItemAttachments>()) {
    sl.registerLazySingleton<ClearTripItemAttachments>(
      () => ClearTripItemAttachments(sl<TripDetailRepositoryImpl>()),
    );
  }

  if (!sl.isRegistered<UploadTripItemAttachment>()) {
    sl.registerLazySingleton<UploadTripItemAttachment>(
      () => UploadTripItemAttachment(sl<TripDetailRepositoryImpl>()),
    );
  }

  if (!sl.isRegistered<TripDetailPageBloc>()) {
    sl.registerFactory<TripDetailPageBloc>(
      () => TripDetailPageBloc(
        sl<GetTripItems>(),
        sl<GetTripPreview>(),
        sl<SubmitTripForAudit>(),
        sl<DeleteTripItem>(),
        sl<UpdateTripItem>(),
        sl<ClearTripItemAttachments>(),
        sl<UploadTripItemAttachment>(),
        RefreshCoordinator.instance,
      ),
    );
  }

  // Register trip_detail with RefreshCoordinator as a no-op placeholder.
  // Replace with a real refresh callback if the repository exposes a refresh method later.
  RefreshCoordinator.instance.register('trip_detail', () async {});
}
