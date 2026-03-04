part of 'home_page_bloc.dart';

abstract class HomePageEvent {}

class HomeStarted extends HomePageEvent {}

class _AllTripsUpdated extends HomePageEvent {
  final List<TripEntity> trips;
  _AllTripsUpdated(this.trips);
}

class _TodayTripsUpdated extends HomePageEvent {
  final List<TripEntity> trips;
  _TodayTripsUpdated(this.trips);
}

class ToggleSpdRequested extends HomePageEvent {}

class SelectTripEvent extends HomePageEvent {
  final TripEntity trip;
  SelectTripEvent(this.trip);
}

class FetchTripExpenses extends HomePageEvent {
  final List<TripEntity> trips;
  FetchTripExpenses(this.trips);
}

/// Internal event used to force recomputing totals and re-emitting
/// the current loaded state after an explicit refresh completes.
class _ForceRecomputeAfterRefresh extends HomePageEvent {}
