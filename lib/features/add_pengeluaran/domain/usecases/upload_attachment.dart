import 'dart:io';
import '../repositories/add_pengeluaran_repository.dart';

class UploadAttachment {
  final AddPengeluaranRepository repository;
  UploadAttachment(this.repository);

  Future<void> call(String tripId, String itemId, File file) async {
    return await repository.uploadAttachment(tripId, itemId, file);
  }
}
