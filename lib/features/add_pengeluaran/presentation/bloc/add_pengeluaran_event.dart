part of 'add_pengeluaran_bloc.dart';

abstract class AddPengeluaranEvent extends Equatable {
  const AddPengeluaranEvent();

  @override
  List<Object> get props => [];
}

class LoadActiveTripsEvent extends AddPengeluaranEvent {
  final String? preferredTripId;
  const LoadActiveTripsEvent({this.preferredTripId});

  @override
  List<Object> get props => [preferredTripId ?? ''];
}

class SelectTripEvent extends AddPengeluaranEvent {
  final ActiveTrip trip;
  const SelectTripEvent(this.trip);
  @override
  List<Object> get props => [trip];
}

class AddDraftEvent extends AddPengeluaranEvent {
  final DraftItem item;
  const AddDraftEvent(this.item);
  @override
  List<Object> get props => [item.id];
}

class RemoveDraftEvent extends AddPengeluaranEvent {
  final String id;
  const RemoveDraftEvent(this.id);
  @override
  List<Object> get props => [id];
}

class SaveAllEvent extends AddPengeluaranEvent {}
