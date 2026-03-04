part of 'home_page_bloc.dart';

abstract class HomePageState extends Equatable {
  const HomePageState();

  @override
  List<Object?> get props => [];
}

class HomePageInitial extends HomePageState {}

class HomeLoading extends HomePageState {}

class HomeLoaded extends HomePageState {
  final List<TripEntity> trips;
  final List<TripEntity> todayTrips;
  final bool subscribedToSpd;
  final int totalOperational;
  final int? totalTransaksi;
  final int? sisaDana;
  final List<TripEntity> activeTrips;
  final TripEntity? activeTrip;
  final TripEntity? selectedTrip;
  final List<ExpenseEntity> latestExpenses;

  const HomeLoaded({
    required this.trips,
    required this.todayTrips,
    required this.subscribedToSpd,
    required this.totalOperational,
    this.totalTransaksi,
    this.sisaDana,
    required this.activeTrips,
    this.activeTrip,
    this.selectedTrip,
    this.latestExpenses = const <ExpenseEntity>[],
  });

  @override
  List<Object?> get props => [
    trips,
    todayTrips,
    subscribedToSpd,
    totalOperational,
    totalTransaksi,
    sisaDana,
    activeTrips,
    activeTrip,
    selectedTrip,
    latestExpenses,
  ];

  HomeLoaded copyWith({
    TripEntity? selectedTrip,
    TripEntity? activeTrip,
    List<ExpenseEntity>? latestExpenses,
  }) {
    return HomeLoaded(
      trips: trips,
      todayTrips: todayTrips,
      subscribedToSpd: subscribedToSpd,
      totalOperational: totalOperational,
      totalTransaksi: totalTransaksi,
      sisaDana: sisaDana,
      activeTrips: activeTrips,
      activeTrip: activeTrip ?? this.activeTrip,
      selectedTrip: selectedTrip ?? this.selectedTrip,
      latestExpenses: latestExpenses ?? this.latestExpenses,
    );
  }
}

class HomeError extends HomePageState {
  final String message;
  const HomeError(this.message);

  @override
  List<Object?> get props => [message];
}
