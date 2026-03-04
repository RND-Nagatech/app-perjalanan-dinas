import 'package:trips_apps/core/domain/entities/trip_entity.dart';
import '../repositories/history_repository.dart';

class GetHistory {
  final HistoryRepository repository;

  GetHistory(this.repository);

  /// Return all trips (history)
  Future<List<TripEntity>> call() async {
    return repository.fetchAll();
  }
}
