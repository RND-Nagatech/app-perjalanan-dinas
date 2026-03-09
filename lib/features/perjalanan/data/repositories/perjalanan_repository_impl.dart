import 'package:shared_preferences/shared_preferences.dart';

import 'package:perjalanan_dinas/core/domain/entities/trip_entity.dart';
import '../../domain/repositories/perjalanan_repository.dart';
import '../datasources/perjalanan_remote_data_source.dart';

class PerjalananRepositoryImpl implements PerjalananRepository {
  final PerjalananRemoteDataSource remote;
  final SharedPreferences prefs;

  PerjalananRepositoryImpl(this.remote, this.prefs);

  @override
  Stream<List<TripEntity>> getPerjalananForCurrentUser() => remote
      .getPerjalananForCurrentUser()
      .map((list) => list.map((m) => m.toEntity()).toList());

  @override
  Future<void> refreshPerjalanan() async => remote.refresh();
}
