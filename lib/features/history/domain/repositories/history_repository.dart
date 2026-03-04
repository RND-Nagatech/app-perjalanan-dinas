import 'package:trips_apps/core/domain/entities/trip_entity.dart';

abstract class HistoryRepository {
  /// Return all trips (history) — could be filtered by status externally
  Future<List<TripEntity>> fetchAll();
}
