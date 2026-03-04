part of 'history_bloc.dart';

abstract class HistoryState extends Equatable {
  const HistoryState();

  @override
  List<Object?> get props => [];
}

class HistoryInitial extends HistoryState {
  const HistoryInitial();
}

class HistoryLoadInProgress extends HistoryState {
  const HistoryLoadInProgress();
}

class HistoryLoadSuccess extends HistoryState {
  final List<HistorySection> items;
  final String filter;
  final String query;

  const HistoryLoadSuccess({
    required this.items,
    required this.filter,
    required this.query,
  });

  HistoryLoadSuccess copyWith({
    List<HistorySection>? items,
    String? filter,
    String? query,
  }) {
    return HistoryLoadSuccess(
      items: items ?? this.items,
      filter: filter ?? this.filter,
      query: query ?? this.query,
    );
  }

  @override
  List<Object?> get props => [items, filter, query];
}

class HistoryLoadFailure extends HistoryState {
  final String message;
  const HistoryLoadFailure(this.message);

  @override
  List<Object?> get props => [message];
}
