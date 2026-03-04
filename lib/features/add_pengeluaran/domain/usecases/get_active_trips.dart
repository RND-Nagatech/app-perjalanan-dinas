import '../entities/active_trip.dart';
import '../repositories/add_pengeluaran_repository.dart';

class GetActiveTrips {
  final AddPengeluaranRepository repository;
  GetActiveTrips(this.repository);

  Future<List<ActiveTrip>> call() async {
    return await repository.getActiveTrips();
  }
}
