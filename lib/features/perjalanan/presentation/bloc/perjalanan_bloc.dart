import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/usecases/get_perjalanan.dart';
import '../../domain/usecases/refresh_perjalanan.dart';
import 'package:trips_apps/core/domain/entities/trip_entity.dart';

part 'perjalanan_event.dart';
part 'perjalanan_state.dart';

class PerjalananBloc extends Bloc<PerjalananEvent, PerjalananState> {
  final GetPerjalanan _getPerjalanan;
  final RefreshPerjalananUseCase _refreshPerjalanan;
  StreamSubscription<List<TripEntity>>? _subscription;

  PerjalananBloc(this._getPerjalanan, this._refreshPerjalanan)
    : super(PerjalananInitial()) {
    on<LoadPerjalanan>(_onLoad);
    on<_PerjalananUpdated>(_onUpdated);
    on<_PerjalananError>(_onError);
    on<RefreshPerjalanan>(_onRefresh);
  }

  Future<void> _onLoad(
    LoadPerjalanan event,
    Emitter<PerjalananState> emit,
  ) async {
    emit(PerjalananLoading());
    await _subscription?.cancel();
    _subscription = _getPerjalanan().listen(
      (trips) => add(_PerjalananUpdated(trips)),
      onError: (err) => add(_PerjalananError(err.toString())),
    );
  }

  void _onUpdated(_PerjalananUpdated event, Emitter<PerjalananState> emit) {
    final berjalan = event.trips
        .where((t) => ((t.status ?? '').toLowerCase().contains('berjalan')))
        .toList(growable: false);
    if (berjalan.isEmpty) {
      emit(PerjalananEmpty());
    } else {
      emit(PerjalananLoaded(berjalan));
    }
  }

  void _onError(_PerjalananError event, Emitter<PerjalananState> emit) {
    emit(PerjalananError(event.message));
  }

  Future<void> _onRefresh(
    RefreshPerjalanan event,
    Emitter<PerjalananState> emit,
  ) async {
    try {
      await _refreshPerjalanan();
    } catch (e) {
      add(_PerjalananError(e.toString()));
    }
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
