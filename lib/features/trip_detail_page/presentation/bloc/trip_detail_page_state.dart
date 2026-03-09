import 'package:equatable/equatable.dart';
import '../../domain/entities/expense_entity.dart';
import 'package:perjalanan_dinas/core/domain/entities/trip_entity.dart';

abstract class TripDetailState extends Equatable {
  @override
  List<Object?> get props => [];
}

class TripDetailInitial extends TripDetailState {}

class TripDetailLoadInProgress extends TripDetailState {}

class TripDetailLoadSuccess extends TripDetailState {
  final TripEntity? preview;
  final List<ExpenseEntity> items;

  TripDetailLoadSuccess({required this.preview, required this.items});

  @override
  List<Object?> get props => [preview, items];
}

class TripDetailActionSuccess extends TripDetailLoadSuccess {
  final String message;

  TripDetailActionSuccess({
    required super.preview,
    required super.items,
    required this.message,
  });

  @override
  List<Object?> get props => [...super.props, message];
}

class TripDetailLoadFailure extends TripDetailState {
  final String message;
  TripDetailLoadFailure(this.message);

  @override
  List<Object?> get props => [message];
}
