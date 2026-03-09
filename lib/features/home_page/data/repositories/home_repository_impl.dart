import 'package:shared_preferences/shared_preferences.dart';
import 'package:perjalanan_dinas/core/domain/entities/trip_entity.dart';
import '../../domain/repositories/home_repository.dart';
import '../datasources/home_remote_data_source.dart';
// TripModel used inside remote datasource; repository maps models -> entities via toEntity

class HomeRepositoryImpl implements HomeRepository {
  final HomeRemoteDataSource remote;
  final SharedPreferences prefs;

  HomeRepositoryImpl(this.remote, this.prefs);

  @override
  Stream<List<TripEntity>> getTrips() =>
      remote.getTrips().map((list) => list.map((m) => m.toEntity()).toList());

  @override
  Stream<List<TripEntity>> getTodayTrips() => remote.getTodayTrips().map(
    (list) => list.map((m) => m.toEntity()).toList(),
  );

  @override
  Future<int?> getTotalInject() async {
    try {
      final v = prefs.getInt('home_total_inject');
      return v;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<int?> getSisaDana() async {
    try {
      final v = prefs.getInt('home_sisa_dana');
      return v;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<int?> getTotalTransaksi() async {
    try {
      final v = prefs.getInt('home_total_transaksi');
      return v;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> refreshTrips() async {
    try {
      // Clear any cached results first to ensure listeners receive fresh data
      try {
        await remote.clearCache();
      } catch (_) {}
      await remote.refresh();
    } catch (_) {
      rethrow;
    }
  }

  @override
  Future<void> clearTripsCache() async {
    await remote.clearCache();
  }

  @override
  Future<bool> getSpdSubscriptionStatus() async {
    return prefs.getBool('sub_spd_topic') ?? false;
  }

  @override
  Future<bool> toggleSpdSubscription(bool currentlySubscribed) async {
    try {
      if (currentlySubscribed) {
        await prefs.setBool('sub_spd_topic', false);
        return false;
      } else {
        await prefs.setBool('sub_spd_topic', true);
        return true;
      }
    } catch (_) {
      rethrow;
    }
  }
}
