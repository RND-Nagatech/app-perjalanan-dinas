part of 'add_pengeluaran_bloc.dart';

abstract class AddPengeluaranState extends Equatable {
  const AddPengeluaranState();

  @override
  List<Object> get props => [];
}

class AddPengeluaranInitial extends AddPengeluaranState {}

class AddPengeluaranLoading extends AddPengeluaranState {}

class AddPengeluaranLoaded extends AddPengeluaranState {
  final List<ActiveTrip> trips;
  final ActiveTrip? selectedTrip;
  final List<DraftItem>? drafts;
  const AddPengeluaranLoaded({
    this.trips = const [],
    this.selectedTrip,
    this.drafts,
  });

  AddPengeluaranLoaded copyWith({
    List<ActiveTrip>? trips,
    ActiveTrip? selectedTrip,
    List<DraftItem>? drafts,
  }) {
    return AddPengeluaranLoaded(
      trips: trips ?? this.trips,
      selectedTrip: selectedTrip ?? this.selectedTrip,
      drafts: drafts ?? this.drafts,
    );
  }

  @override
  List<Object> get props => [trips, selectedTrip ?? {}, drafts ?? []];
}

class AddPengeluaranSaving extends AddPengeluaranState {
  final int totalNominal;

  const AddPengeluaranSaving({required this.totalNominal});

  @override
  List<Object> get props => [totalNominal];
}

class AddPengeluaranSaved extends AddPengeluaranState {}

class AddPengeluaranFailure extends AddPengeluaranState {
  final String message;
  const AddPengeluaranFailure({required this.message});
  @override
  List<Object> get props => [message];
}
