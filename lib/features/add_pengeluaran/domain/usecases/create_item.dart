import '../entities/created_item.dart';
import '../repositories/add_pengeluaran_repository.dart';

class CreateItem {
  final AddPengeluaranRepository repository;
  CreateItem(this.repository);

  Future<CreatedItem> call(
    String tripId,
    Map<String, dynamic> payload,
  ) async {
    return await repository.createItem(tripId, payload);
  }
}
