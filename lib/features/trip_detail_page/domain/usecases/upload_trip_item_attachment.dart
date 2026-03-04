import 'dart:io';
import '../repositories/trip_detail_repository.dart';

class UploadTripItemAttachment {
  final TripDetailRepository repository;

  UploadTripItemAttachment(this.repository);

  Future<bool> call(String tripId, String itemId, File file) async {
    return await repository.uploadItemAttachment(tripId, itemId, file);
  }
}
