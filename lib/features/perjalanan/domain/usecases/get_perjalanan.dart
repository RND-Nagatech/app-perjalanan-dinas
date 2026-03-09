import '../repositories/perjalanan_repository.dart';
import 'package:perjalanan_dinas/core/domain/entities/trip_entity.dart';

class GetPerjalanan {
  final PerjalananRepository repository;
  GetPerjalanan(this.repository);

  Stream<List<TripEntity>> call() => repository.getPerjalananForCurrentUser();
}
