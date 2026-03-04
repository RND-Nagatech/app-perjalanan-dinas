import '../repositories/trip_detail_repository.dart';

class UpdateTripItem {
  final TripDetailRepository repository;

  UpdateTripItem(this.repository);

  Future<bool> call(
    String tripId,
    String itemId,
    Map<String, dynamic> patch,
  ) async {
    return await repository.updateItem(tripId, itemId, patch);
  }
}
