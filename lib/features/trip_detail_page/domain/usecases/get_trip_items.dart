import '../entities/expense_entity.dart';
import '../repositories/trip_detail_repository.dart';

class GetTripItems {
  final TripDetailRepository repository;

  GetTripItems(this.repository);

  Future<List<ExpenseEntity>> call(String tripId) async {
    return await repository.getItemsForTrip(tripId);
  }
}
