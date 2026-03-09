import 'package:equatable/equatable.dart';
import 'dart:io';

abstract class TripDetailEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class WatchExpensesStarted extends TripDetailEvent {
  final String? tripId;
  WatchExpensesStarted(this.tripId);

  @override
  List<Object?> get props => [tripId];
}

class EndTripRequested extends TripDetailEvent {
  final String tripId;
  EndTripRequested(this.tripId);

  @override
  List<Object?> get props => [tripId];
}

class DeleteItemRequested extends TripDetailEvent {
  final String tripId;
  final String itemId;
  DeleteItemRequested(this.tripId, this.itemId);

  @override
  List<Object?> get props => [tripId, itemId];
}

class UpdateItemRequested extends TripDetailEvent {
  final String tripId;
  final String itemId;
  final Map<String, dynamic> patch;
  final bool replaceAttachments;
  final List<File>? newAttachments;
  final List<String> oldAttachmentPaths;
  UpdateItemRequested(
    this.tripId,
    this.itemId,
    this.patch, {
    this.replaceAttachments = false,
    this.newAttachments,
    this.oldAttachmentPaths = const <String>[],
  });

  @override
  List<Object?> get props => [
    tripId,
    itemId,
    patch,
    replaceAttachments,
    newAttachments?.map((f) => f.path).join(','),
    oldAttachmentPaths,
  ];
}
