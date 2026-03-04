import '../repositories/trip_detail_repository.dart';

class ClearTripItemAttachments {
  final TripDetailRepository repository;

  ClearTripItemAttachments(this.repository);

  Future<bool> call(
    String tripId,
    String itemId,
    List<String> attachmentPaths,
  ) async {
    return await repository.clearItemAttachments(
      tripId,
      itemId,
      attachmentPaths,
    );
  }
}
