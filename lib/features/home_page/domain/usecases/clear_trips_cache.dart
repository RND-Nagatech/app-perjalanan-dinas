import '../repositories/home_repository.dart';

class ClearTripsCache {
  final HomeRepository repository;

  ClearTripsCache(this.repository);

  Future<void> call() => repository.clearTripsCache();
}
