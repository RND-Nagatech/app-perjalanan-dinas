import 'package:perjalanan_dinas/core/domain/entities/trip_entity.dart';
import '../repositories/home_repository.dart';

class GetTodayTrips {
  final HomeRepository repository;
  GetTodayTrips(this.repository);

  Stream<List<TripEntity>> call() => repository.getTodayTrips();
}
