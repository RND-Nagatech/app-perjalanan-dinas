import 'package:perjalanan_dinas/core/domain/entities/trip_entity.dart';
import 'package:perjalanan_dinas/features/history/domain/failures/history_failure.dart';
import 'package:perjalanan_dinas/features/history/domain/repositories/history_repository.dart';
import '../datasources/history_remote_data_source.dart';
import '../exceptions.dart';

class HistoryRepositoryImpl implements HistoryRepository {
  final HistoryRemoteDataSource remote;

  HistoryRepositoryImpl(this.remote);

  @override
  Future<List<TripEntity>> fetchAll() async {
    try {
      final entities = await remote.fetchAll();
      return entities;
    } on HistoryRemoteException catch (e) {
      throw HistoryFailure(e.message);
    } catch (_) {
      throw HistoryFailure('Gagal memuat riwayat perjalanan');
    }
  }
}
