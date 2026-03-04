import '../repositories/trip_detail_repository.dart';

class DeleteTripItem {
  final TripDetailRepository repository;

  DeleteTripItem(this.repository);

  Future<bool> call(String tripId, String itemId) async {
    return await repository.deleteItem(tripId, itemId);
  }
}
