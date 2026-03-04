import '../repositories/trip_detail_repository.dart';

class SubmitTripForAudit {
  final TripDetailRepository repository;

  SubmitTripForAudit(this.repository);

  Future<bool> call(String tripId) async {
    return await repository.submitTripForAudit(tripId);
  }
}
