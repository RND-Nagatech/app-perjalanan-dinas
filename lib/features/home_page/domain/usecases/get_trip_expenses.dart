import 'package:trips_apps/core/domain/entities/trip_entity.dart';
import 'package:trips_apps/features/trip_detail_page/domain/usecases/get_trip_items.dart';
import 'package:trips_apps/features/trip_detail_page/domain/entities/expense_entity.dart';

/// Aggregates recent expenses for a list of trips by calling into the
/// TripDetail feature's `GetTripItems` usecase.
class GetTripExpenses {
  final GetTripItems getTripItems;
  final int limit;

  GetTripExpenses(this.getTripItems, {this.limit = 6});

  Future<List<ExpenseEntity>> call(List<TripEntity> trips) async {
    final all = <ExpenseEntity>[];
    final toQuery = trips.take(limit).toList();
    for (final t in toQuery) {
      try {
        final items = await getTripItems.call(t.id.toString());
        all.addAll(items);
      } catch (_) {
        // ignore individual trip failures
      }
    }

    all.sort((a, b) {
      final da =
          DateTime.tryParse(a.tanggal ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0);
      final db =
          DateTime.tryParse(b.tanggal ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0);
      return db.compareTo(da);
    });

    return all;
  }
}
