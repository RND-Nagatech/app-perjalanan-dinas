import 'package:perjalanan_dinas/core/domain/entities/trip_entity.dart';

abstract class HomeRepository {
  /// Stream all trips
  Stream<List<TripEntity>> getTrips();

  /// Stream trips happening today
  Stream<List<TripEntity>> getTodayTrips();

  /// Toggle SPD topic subscription; returns new subscribed status
  Future<bool> toggleSpdSubscription(bool currentlySubscribed);

  /// Get current subscription status
  Future<bool> getSpdSubscriptionStatus();

  /// Optional: total injected operational fund provided by backend
  Future<int?> getTotalInject();

  /// Optional: sisa dana (remaining fund) provided by backend
  Future<int?> getSisaDana();

  /// Optional: total transaksi (used amount) provided by backend
  Future<int?> getTotalTransaksi();

  /// Force refresh trips from backend (push new values to streams)
  Future<void> refreshTrips();

  /// Clear local in-memory/home cache without network fetch.
  Future<void> clearTripsCache();
}
