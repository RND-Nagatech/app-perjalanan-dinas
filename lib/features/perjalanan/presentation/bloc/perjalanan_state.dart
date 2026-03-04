part of 'perjalanan_bloc.dart';

abstract class PerjalananState extends Equatable {
  const PerjalananState();

  @override
  List<Object?> get props => [];
}

class PerjalananInitial extends PerjalananState {}

class PerjalananLoading extends PerjalananState {}

class PerjalananLoaded extends PerjalananState {
  final List<TripEntity> trips;
  const PerjalananLoaded(this.trips);

  @override
  List<Object?> get props => [trips];
}

class PerjalananEmpty extends PerjalananState {}

class PerjalananError extends PerjalananState {
  final String message;
  const PerjalananError(this.message);

  @override
  List<Object?> get props => [message];
}
