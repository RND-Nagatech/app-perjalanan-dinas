import 'package:perjalanan_dinas/core/domain/entities/trip_entity.dart';

abstract class HistoryRepository {
  /// Return all trips (history) — could be filtered by status externally
  Future<List<TripEntity>> fetchAll();
}
