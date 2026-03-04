import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:trips_apps/core/domain/entities/trip_entity.dart';
import '../../domain/failures/history_failure.dart';
import '../../domain/usecases/get_history.dart';
import '../models/history_section.dart';

part 'history_event.dart';
part 'history_state.dart';

class HistoryBloc extends Bloc<HistoryEvent, HistoryState> {
  final GetHistory _getHistory;
  List<TripEntity> _allItems = [];
  // helper month names in Indonesian
  static const _monthNames = [
    'Januari',
    'Februari',
    'Maret',
    'April',
    'Mei',
    'Juni',
    'Juli',
    'Agustus',
    'September',
    'Oktober',
    'November',
    'Desember',
  ];

  HistoryBloc(this._getHistory) : super(HistoryInitial()) {
    on<LoadHistory>(_onLoad);
    on<RefreshHistory>(_onRefresh);
    on<ChangeFilter>(_onChangeFilter);
    on<ChangeQuery>(_onChangeQuery);
  }

  Future<void> _onLoad(LoadHistory event, Emitter<HistoryState> emit) async {
    emit(HistoryLoadInProgress());
    try {
      final items = await _getHistory.call();
      _allItems = items;
      final sections = _applyFilterQuery(_allItems, 'Semua', '');
      emit(HistoryLoadSuccess(items: sections, filter: 'Semua', query: ''));
    } on HistoryFailure catch (e) {
      emit(HistoryLoadFailure(e.message));
    } catch (e) {
      emit(HistoryLoadFailure(e.toString()));
    }
  }

  Future<void> _onRefresh(
    RefreshHistory event,
    Emitter<HistoryState> emit,
  ) async {
    try {
      final items = await _getHistory.call();
      _allItems = items;
      final currentFilter = (state is HistoryLoadSuccess)
          ? (state as HistoryLoadSuccess).filter
          : 'Semua';
      final currentQuery = (state is HistoryLoadSuccess)
          ? (state as HistoryLoadSuccess).query
          : '';
      final sections = _applyFilterQuery(
        _allItems,
        currentFilter,
        currentQuery,
      );
      emit(
        HistoryLoadSuccess(
          items: sections,
          filter: currentFilter,
          query: currentQuery,
        ),
      );
    } on HistoryFailure catch (e) {
      emit(HistoryLoadFailure(e.message));
    } catch (e) {
      emit(HistoryLoadFailure(e.toString()));
    }
  }

  void _onChangeFilter(ChangeFilter event, Emitter<HistoryState> emit) {
    if (state is HistoryLoadSuccess) {
      final s = state as HistoryLoadSuccess;
      final sections = _applyFilterQuery(_allItems, event.filter, s.query);
      emit(
        HistoryLoadSuccess(
          items: sections,
          filter: event.filter,
          query: s.query,
        ),
      );
    }
  }

  void _onChangeQuery(ChangeQuery event, Emitter<HistoryState> emit) {
    if (state is HistoryLoadSuccess) {
      final s = state as HistoryLoadSuccess;
      final sections = _applyFilterQuery(_allItems, s.filter, event.query);
      emit(
        HistoryLoadSuccess(
          items: sections,
          filter: s.filter,
          query: event.query,
        ),
      );
    }
  }

  List<HistorySection> _applyFilterQuery(
    List<TripEntity> source,
    String filter,
    String query,
  ) {
    final q = query.trim().toLowerCase();
    final filtered = source.where((t) {
      try {
        final status = (t.status ?? '').toLowerCase();
        if (filter == 'Berjalan' && !status.contains('berjalan')) return false;
        if (filter == 'Selesai' && !status.contains('selesai')) return false;
        if (filter == 'Audit' && !status.contains('audit')) return false;
        if (q.isEmpty) return true;
        final name = t.name.toLowerCase();
        final dest = t.destination.toLowerCase();
        return name.contains(q) || dest.contains(q);
      } catch (_) {
        return true;
      }
    }).toList();

    // Group by year-month from `dateFrom`. Use 'Bulan Ini' for current month.
    final now = DateTime.now();
    final Map<String, List<TripEntity>> groups = {};
    for (final t in filtered) {
      final DateTime? df = t.dateFrom;
      String key;
      if (df == null) {
        key = 'Lainnya';
      } else {
        final y = df.year;
        final m = df.month; // 1..12
        key = '$y-${m.toString().padLeft(2, '0')}';
      }
      groups.putIfAbsent(key, () => []).add(t);
    }

    final List<String> keys = groups.keys.toList()
      ..sort((a, b) => b.compareTo(a));
    final List<HistorySection> resultSections = [];
    for (final key in keys) {
      if (key == 'Lainnya') {
        resultSections.add(
          HistorySection(title: 'Lainnya', items: groups[key]!),
        );
        continue;
      }
      final parts = key.split('-');
      final y = int.tryParse(parts[0]) ?? now.year;
      final m = int.tryParse(parts[1]) ?? 1;
      String title;
      if (y == now.year && m == now.month) {
        title = 'Bulan Ini';
      } else {
        final monthName = _monthNames[m - 1];
        title = monthName + (y == now.year ? '' : ' $y');
      }
      resultSections.add(HistorySection(title: title, items: groups[key]!));
    }

    return resultSections;
  }
}
