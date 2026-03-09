import 'package:perjalanan_dinas/core/domain/entities/trip_entity.dart';

abstract class PerjalananRepository {
  /// Stream perjalanan for the currently logged-in user
  Stream<List<TripEntity>> getPerjalananForCurrentUser();

  /// Force refresh
  Future<void> refreshPerjalanan();
}
