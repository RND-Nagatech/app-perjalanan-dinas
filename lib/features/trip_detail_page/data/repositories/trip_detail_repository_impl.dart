import '../../domain/entities/expense_entity.dart';
import 'dart:io';
import 'package:trips_apps/core/domain/entities/trip_entity.dart';
import '../../domain/failures/trip_detail_failure.dart';
import '../../domain/repositories/trip_detail_repository.dart';
import '../datasources/trip_detail_remote_datasource.dart';
import '../exceptions.dart';
import '../models/trip_detail_model.dart';

class TripDetailRepositoryImpl implements TripDetailRepository {
  final TripDetailRemoteDataSource remote;

  TripDetailRepositoryImpl(this.remote);

  @override
  Future<List<ExpenseEntity>> getItemsForTrip(String tripId) async {
    try {
      return await remote.fetchItems(tripId);
    } on TripDetailRemoteException catch (e) {
      throw TripDetailFailure(e.message);
    } catch (_) {
      throw TripDetailFailure('Gagal memuat item perjalanan');
    }
  }

  @override
  Future<TripEntity?> getTripPreview(String tripId) async {
    try {
      final map = await remote.fetchTripPreview(tripId);
      if (map == null) return null;
      return TripDetailModel.fromJson(map);
    } on TripDetailRemoteException catch (e) {
      throw TripDetailFailure(e.message);
    } catch (_) {
      throw TripDetailFailure('Gagal memuat preview perjalanan');
    }
  }

  @override
  Future<bool> submitTripForAudit(String tripId) async {
    try {
      return await remote.submitTripForAudit(tripId);
    } on TripDetailRemoteException catch (e) {
      throw TripDetailFailure(e.message);
    } catch (_) {
      throw TripDetailFailure('Gagal mengirim perjalanan ke audit');
    }
  }

  @override
  Future<bool> deleteItem(String tripId, String itemId) async {
    try {
      return await remote.deleteItem(tripId, itemId);
    } on TripDetailRemoteException catch (e) {
      throw TripDetailFailure(e.message);
    } catch (_) {
      throw TripDetailFailure('Gagal menghapus item');
    }
  }

  @override
  Future<bool> updateItem(String tripId, String itemId, Map<String, dynamic> patch) async {
    try {
      return await remote.updateItem(tripId, itemId, patch);
    } on TripDetailRemoteException catch (e) {
      throw TripDetailFailure(e.message);
    } catch (_) {
      throw TripDetailFailure('Gagal memperbarui item');
    }
  }

  @override
  Future<bool> clearItemAttachments(
    String tripId,
    String itemId,
    List<String> attachmentPaths,
  ) async {
    try {
      return await remote.clearItemAttachments(tripId, itemId, attachmentPaths);
    } on TripDetailRemoteException catch (e) {
      throw TripDetailFailure(e.message);
    } catch (_) {
      throw TripDetailFailure('Gagal menghapus foto lama');
    }
  }

  @override
  Future<bool> uploadItemAttachment(String tripId, String itemId, File file) async {
    try {
      return await remote.uploadItemAttachment(tripId, itemId, file);
    } on TripDetailRemoteException catch (e) {
      throw TripDetailFailure(e.message);
    } catch (_) {
      throw TripDetailFailure('Gagal upload foto baru');
    }
  }
}
