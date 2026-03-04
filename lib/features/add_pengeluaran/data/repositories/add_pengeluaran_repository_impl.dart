import 'dart:io';

import '../../domain/entities/active_trip.dart';
import '../../domain/entities/created_item.dart';
import '../../domain/failures/add_pengeluaran_failure.dart';
import '../../domain/repositories/add_pengeluaran_repository.dart';
import '../datasources/add_pengeluaran_remote_data_source.dart';
import '../exceptions.dart';

class AddPengeluaranRepositoryImpl implements AddPengeluaranRepository {
  final AddPengeluaranRemoteDataSource remote;

  AddPengeluaranRepositoryImpl(this.remote);

  @override
  Future<List<ActiveTrip>> getActiveTrips() async {
    try {
      return await remote.fetchActiveTrips();
    } on AddPengeluaranRemoteException catch (e) {
      throw AddPengeluaranFailure(e.message);
    } catch (_) {
      throw AddPengeluaranFailure('Gagal memuat perjalanan aktif');
    }
  }

  @override
  Future<int?> getSisaForTrip(String tripId) async {
    try {
      return await remote.fetchSisaForTrip(tripId);
    } on AddPengeluaranRemoteException catch (e) {
      throw AddPengeluaranFailure(e.message);
    } catch (_) {
      throw AddPengeluaranFailure('Gagal memuat detail perjalanan');
    }
  }

  @override
  Future<CreatedItem> createItem(
    String tripId,
    Map<String, dynamic> payload,
  ) async {
    try {
      return await remote.createItem(tripId, payload);
    } on AddPengeluaranRemoteException catch (e) {
      throw AddPengeluaranFailure(e.message);
    } catch (_) {
      throw AddPengeluaranFailure('Gagal membuat item pengeluaran');
    }
  }

  @override
  Future<void> uploadAttachment(
    String tripId,
    String itemId,
    File file,
  ) async {
    try {
      await remote.uploadAttachment(tripId, itemId, file);
    } on AddPengeluaranRemoteException catch (e) {
      throw AddPengeluaranFailure(e.message);
    } catch (_) {
      throw AddPengeluaranFailure('Gagal upload lampiran');
    }
  }
}
