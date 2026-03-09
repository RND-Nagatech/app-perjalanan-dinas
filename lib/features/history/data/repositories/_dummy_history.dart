import 'package:perjalanan_dinas/core/domain/entities/trip_entity.dart';
import '../../domain/repositories/history_repository.dart';

class DummyHistoryRepository implements HistoryRepository {
  @override
  Future<List<TripEntity>> fetchAll() async => <TripEntity>[];
}
