import 'package:perjalanan_dinas/core/domain/entities/trip_entity.dart';
import '../repositories/home_repository.dart';

class GetTrips {
  final HomeRepository repository;
  GetTrips(this.repository);

  Stream<List<TripEntity>> call() => repository.getTrips();
}
