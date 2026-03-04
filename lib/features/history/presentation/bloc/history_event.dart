part of 'history_bloc.dart';

abstract class HistoryEvent {}

class LoadHistory extends HistoryEvent {}

class RefreshHistory extends HistoryEvent {}

class ChangeFilter extends HistoryEvent {
  final String filter;
  ChangeFilter(this.filter);
}

class ChangeQuery extends HistoryEvent {
  final String query;
  ChangeQuery(this.query);
}
