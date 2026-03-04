import '../repositories/perjalanan_repository.dart';
import 'package:trips_apps/core/domain/entities/trip_entity.dart';

class GetPerjalanan {
  final PerjalananRepository repository;
  GetPerjalanan(this.repository);

  Stream<List<TripEntity>> call() => repository.getPerjalananForCurrentUser();
}
