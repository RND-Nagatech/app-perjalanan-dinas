import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:perjalanan_dinas/features/home_page/domain/usecases/get_total_inject.dart';
import 'package:perjalanan_dinas/features/home_page/domain/usecases/get_sisa_dana.dart';
import 'package:perjalanan_dinas/features/home_page/domain/usecases/get_total_transaksi.dart';
import 'package:perjalanan_dinas/features/home_page/domain/usecases/refresh_trips.dart';

import 'package:perjalanan_dinas/core/domain/entities/trip_entity.dart';
import '../../domain/usecases/get_trips.dart';
import '../../domain/usecases/get_today_trips.dart';
import '../../domain/usecases/toggle_spd_subscription.dart';
import '../../domain/usecases/get_trip_expenses.dart';
import 'package:perjalanan_dinas/features/trip_detail_page/domain/entities/expense_entity.dart';
import 'package:perjalanan_dinas/core/services/refresh_coordinator.dart';

part 'home_page_event.dart';
part 'home_page_state.dart';

class HomePageBloc extends Bloc<HomePageEvent, HomePageState> {
  final GetTrips getTrips;
  final GetTodayTrips getTodayTrips;
  final ToggleSpdSubscription toggleSpdUsecase;
  final GetTotalInject getTotalInject;
  final GetSisaDana getSisaDana;
  final GetTotalTransaksi getTotalTransaksi;
  final RefreshTrips refreshTrips;
  final GetTripExpenses getTripExpenses;
  final dynamic refreshPerjalanan;

  StreamSubscription<List<TripEntity>>? _allSub;
  StreamSubscription<List<TripEntity>>? _todaySub;
  bool _subscribed = false;

  HomePageBloc({
    required this.getTrips,
    required this.getTodayTrips,
    required this.getTripExpenses,
    required this.toggleSpdUsecase,
    required this.getTotalInject,
    required this.getSisaDana,
    required this.getTotalTransaksi,
    required this.refreshTrips,
    this.refreshPerjalanan,
  }) : super(HomePageInitial()) {
    on<HomeStarted>(_onStarted);
    on<_AllTripsUpdated>(_onAllUpdated);
    on<_TodayTripsUpdated>(_onTodayUpdated);
    on<ToggleSpdRequested>(_onToggleSpd);
    on<_ForceRecomputeAfterRefresh>((event, emit) async {
      final current = state;
      if (current is HomeLoaded) {
        await _emitLoadedFor(
          emit,
          all: current.trips,
          today: current.todayTrips,
        );
      }
    });
    on<SelectTripEvent>((event, emit) {
      final currentState = state;
      if (currentState is HomeLoaded) {
        emit(currentState.copyWith(selectedTrip: event.trip));
      }
    });

    on<FetchTripExpenses>(_onFetchTripExpenses);

    // start listening immediately
    add(HomeStarted());
  }

  /// Public API to trigger a manual refresh from UI (pull-to-refresh)
  Future<void> refreshTripsFromUi() async {
    try {
      await refreshTrips.call();
      // Trigger registered feature refresh callbacks (perjalanan, history, etc.)
      try {
        await RefreshCoordinator.instance.refreshAll().timeout(
          const Duration(seconds: 8),
        );
      } catch (_) {}
      // also refresh perjalanan feature if available so UI in that
      // feature shows newest backend data when home refreshes.
      try {
        if (refreshPerjalanan != null) {
          await refreshPerjalanan.call();
        }
      } catch (_) {}

      // ensure bloc re-computes totals and replaces selectedTrip with
      // updated instances from latest stream (in case stream replayed cache)
      try {
        add(_ForceRecomputeAfterRefresh());
      } catch (_) {}
    } catch (_) {
      rethrow;
    }
  }

  Future<void> _onStarted(
    HomeStarted event,
    Emitter<HomePageState> emit,
  ) async {
    emit(HomeLoading());
    await _allSub?.cancel();
    await _todaySub?.cancel();
    try {
      _allSub = getTrips().listen((all) {
        add(_AllTripsUpdated(all));
      });
      _todaySub = getTodayTrips().listen((today) {
        add(_TodayTripsUpdated(today));
      });
    } catch (e) {
      emit(HomeError(e.toString()));
    }
  }

  Future<void> _emitLoadedFor(
    Emitter<HomePageState> emit, {
    required List<TripEntity> all,
    required List<TripEntity> today,
  }) async {
    // Prefer backend-provided total_inject when available via usecase
    // compute active trips first and base totals on active only
    final activeTrips = _computeActiveTrips(all);
    // determine activeTrip (most recent 'BERJALAN' by createdAt)
    TripEntity? activeTrip;
    try {
      if (activeTrips.isNotEmpty) {
        activeTrips.sort((a, b) {
          final da = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          final db = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          return db.compareTo(da);
        });
        activeTrip = activeTrips.first;
      }
    } catch (_) {
      activeTrip = null;
    }

    final hasActiveTrips = activeTrips.isNotEmpty;
    var totalOperational = hasActiveTrips
        ? _computeTotalOperational(activeTrips)
        : 0;
    int? totalTrans = hasActiveTrips ? null : 0;
    int? sisa = hasActiveTrips ? null : 0;
    try {
      if (hasActiveTrips) {
        try {
          final val = await getTotalInject.call();
          if (val != null) {
            totalOperational = val;
          }
        } catch (_) {}

        try {
          totalTrans = await getTotalTransaksi.call();
        } catch (_) {
          totalTrans = null;
        }

        try {
          sisa = await getSisaDana.call();
        } catch (_) {
          sisa = null;
        }
      }

      try {
        // ignore: avoid_print
        // print(
        //   'HomePageBloc: emitting HomeLoaded all=${all.length} today=${today.length} active=${activeTrips.length} totalOperational=$totalOperational totalTransaksi=$totalTrans sisaDana=$sisa',
        // );
      } catch (_) {}
      final prevSelected = state is HomeLoaded
          ? (state as HomeLoaded).selectedTrip
          : null;
      TripEntity? selectedTrip;
      try {
        // if previous selection exists, try to find the updated instance
        if (prevSelected != null) {
          final selId = prevSelected.id;
          TripEntity? found;
          for (final t in activeTrips) {
            if (t.id == selId) {
              found = t;
              break;
            }
          }
          selectedTrip = found;
        } else {
          selectedTrip = null;
        }
      } catch (_) {
        selectedTrip = null;
      }

      // if no explicit selection, prefer activeTrip (most recent BERJALAN)
      selectedTrip ??= activeTrip;

      emit(
        HomeLoaded(
          trips: all,
          todayTrips: today,
          subscribedToSpd: _subscribed,
          totalOperational: totalOperational,
          totalTransaksi: totalTrans,
          sisaDana: sisa,
          activeTrips: activeTrips,
          activeTrip: activeTrip,
          selectedTrip: selectedTrip,
        ),
      );
      // asynchronously fetch recent expenses across active trips
      try {
        add(FetchTripExpenses(activeTrips));
      } catch (_) {}
    } catch (_) {
      final activeTrips = _computeActiveTrips(all);
      TripEntity? activeTrip;
      try {
        if (activeTrips.isNotEmpty) {
          activeTrips.sort((a, b) {
            final da = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
            final db = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
            return db.compareTo(da);
          });
          activeTrip = activeTrips.first;
        }
      } catch (_) {
        activeTrip = null;
      }
      try {
        // ignore: avoid_print
        // print(
        //   'HomePageBloc: emitting HomeLoaded (error path) all=${all.length} today=${today.length} active=${activeTrips.length} totalOperational=$totalOperational',
        // );
      } catch (_) {}
      final prevSelected = state is HomeLoaded
          ? (state as HomeLoaded).selectedTrip
          : null;
      TripEntity? selectedTrip;
      try {
        if (prevSelected != null) {
          final selId = prevSelected.id;
          TripEntity? found;
          for (final t in activeTrips) {
            if (t.id == selId) {
              found = t;
              break;
            }
          }
          selectedTrip = found;
        } else {
          selectedTrip = null;
        }
      } catch (_) {
        selectedTrip = null;
      }

      selectedTrip ??= activeTrip;

      final fallbackTotalOperational = activeTrips.isEmpty
          ? 0
          : totalOperational;
      final fallbackTotalTransaksi = activeTrips.isEmpty ? 0 : null;
      final fallbackSisaDana = activeTrips.isEmpty ? 0 : null;

      emit(
        HomeLoaded(
          trips: all,
          todayTrips: today,
          subscribedToSpd: _subscribed,
          totalOperational: fallbackTotalOperational,
          totalTransaksi: fallbackTotalTransaksi,
          sisaDana: fallbackSisaDana,
          activeTrips: activeTrips,
          activeTrip: activeTrip,
          selectedTrip: selectedTrip,
        ),
      );
      try {
        add(FetchTripExpenses(activeTrips));
      } catch (_) {}
    }
  }

  Future<void> _onFetchTripExpenses(
    FetchTripExpenses event,
    Emitter<HomePageState> emit,
  ) async {
    try {
      final items = await getTripExpenses.call(event.trips);
      final current = state;
      if (current is HomeLoaded) {
        emit(current.copyWith(latestExpenses: items));
      }
    } catch (_) {}
  }

  Future<void> _onAllUpdated(
    _AllTripsUpdated event,
    Emitter<HomePageState> emit,
  ) async {
    final today = state is HomeLoaded
        ? (state as HomeLoaded).todayTrips
        : <TripEntity>[];
    try {
      // ignore: avoid_print
      // print('HomePageBloc: _onAllUpdated received ${event.trips.length} trips');
      if (event.trips.isNotEmpty) {
        // ignore: avoid_print
        // print(
        //   'HomePageBloc: first trip sample name=${first.name} status=${first.status}',
        // );
      }
    } catch (_) {}
    await _emitLoadedFor(
      emit,
      all: event.trips.cast<TripEntity>(),
      today: today,
    );
  }

  Future<void> _onTodayUpdated(
    _TodayTripsUpdated event,
    Emitter<HomePageState> emit,
  ) async {
    if (state is! HomeLoaded) {
      try {
        // ignore: avoid_print
        // print(
        //   'HomePageBloc: _onTodayUpdated ignored because state not loaded yet',
        // );
      } catch (_) {}
      return;
    }
    final all = (state as HomeLoaded).trips;
    await _emitLoadedFor(emit, all: all, today: event.trips.cast<TripEntity>());
  }

  Future<void> _onToggleSpd(
    ToggleSpdRequested event,
    Emitter<HomePageState> emit,
  ) async {
    try {
      final newStatus = await toggleSpdUsecase.call(_subscribed);
      _subscribed = newStatus;
      final all = state is HomeLoaded
          ? (state as HomeLoaded).trips
          : <TripEntity>[];
      final today = state is HomeLoaded
          ? (state as HomeLoaded).todayTrips
          : <TripEntity>[];
      await _emitLoadedFor(emit, all: all, today: today);
    } catch (e) {
      emit(HomeError(e.toString()));
    }
  }

  int _computeTotalOperational(List<TripEntity> all) {
    var total = 0;
    for (var d in all) {
      try {
        total += d.operational;
      } catch (_) {}
    }
    return total;
  }

  List<TripEntity> _computeActiveTrips(List<TripEntity> all) {
    // Only include trips with status 'BERJALAN' (case-insensitive)
    return all.where((t) {
      try {
        final st = t.status;
        if (st == null || st.isEmpty) return false;
        return st.toLowerCase().contains('berjalan');
      } catch (_) {
        return false;
      }
    }).toList();
  }

  @override
  Future<void> close() async {
    await _allSub?.cancel();
    await _todaySub?.cancel();
    return super.close();
  }
}
