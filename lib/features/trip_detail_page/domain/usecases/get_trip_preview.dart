import 'package:perjalanan_dinas/core/domain/entities/trip_entity.dart';
import '../repositories/trip_detail_repository.dart';

class GetTripPreview {
  final TripDetailRepository repository;

  GetTripPreview(this.repository);

  Future<TripEntity?> call(String tripId) async {
    return await repository.getTripPreview(tripId);
  }
}
