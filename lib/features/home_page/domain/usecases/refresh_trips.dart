import '../repositories/home_repository.dart';

class RefreshTrips {
  final HomeRepository repository;
  RefreshTrips(this.repository);

  Future<void> call() => repository.refreshTrips();
}
