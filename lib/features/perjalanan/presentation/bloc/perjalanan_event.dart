part of 'perjalanan_bloc.dart';

abstract class PerjalananEvent extends Equatable {
  const PerjalananEvent();

  @override
  List<Object?> get props => [];
}

class LoadPerjalanan extends PerjalananEvent {}

class RefreshPerjalanan extends PerjalananEvent {}

class _PerjalananUpdated extends PerjalananEvent {
  final List<TripEntity> trips;
  const _PerjalananUpdated(this.trips);

  @override
  List<Object?> get props => [trips];
}

class _PerjalananError extends PerjalananEvent {
  final String message;
  const _PerjalananError(this.message);

  @override
  List<Object?> get props => [message];
}
