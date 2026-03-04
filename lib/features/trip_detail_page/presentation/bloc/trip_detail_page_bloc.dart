import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/failures/trip_detail_failure.dart';
import '../../domain/usecases/get_trip_items.dart';
import '../../domain/usecases/get_trip_preview.dart';
import '../../domain/usecases/submit_trip_for_audit.dart';
import '../../domain/usecases/delete_trip_item.dart';
import '../../domain/usecases/update_trip_item.dart';
import '../../domain/usecases/clear_trip_item_attachments.dart';
import '../../domain/usecases/upload_trip_item_attachment.dart';
import 'trip_detail_page_event.dart';
import 'trip_detail_page_state.dart';
import 'package:trips_apps/core/services/refresh_coordinator.dart';

class TripDetailPageBloc extends Bloc<TripDetailEvent, TripDetailState> {
  final GetTripItems getTripItems;
  final GetTripPreview getTripPreview;
  final SubmitTripForAudit submitTripForAudit;
  final DeleteTripItem deleteTripItem;
  final UpdateTripItem updateTripItem;
  final ClearTripItemAttachments clearTripItemAttachments;
  final UploadTripItemAttachment uploadTripItemAttachment;
  final RefreshCoordinator refreshCoordinator;

  TripDetailPageBloc(
    this.getTripItems,
    this.getTripPreview,
    this.submitTripForAudit,
    this.deleteTripItem,
    this.updateTripItem,
    this.clearTripItemAttachments,
    this.uploadTripItemAttachment,
    this.refreshCoordinator,
  ) : super(TripDetailInitial()) {
    on<WatchExpensesStarted>(_onWatchStarted);
    on<EndTripRequested>(_onEndTripRequested);
    on<DeleteItemRequested>(_onDeleteItemRequested);
    on<UpdateItemRequested>(_onUpdateItemRequested);
  }

  Future<void> _onWatchStarted(
    WatchExpensesStarted event,
    Emitter<TripDetailState> emit,
  ) async {
    final tripId = event.tripId;
    if (tripId == null) return;
    emit(TripDetailLoadInProgress());
    try {
      final preview = await getTripPreview(tripId);
      final items = await getTripItems(tripId);
      emit(TripDetailLoadSuccess(preview: preview, items: items));
    } on TripDetailFailure catch (e) {
      emit(TripDetailLoadFailure(e.message));
    } catch (e) {
      emit(TripDetailLoadFailure(e.toString()));
    }
  }

  Future<void> _onEndTripRequested(
    EndTripRequested event,
    Emitter<TripDetailState> emit,
  ) async {
    final tripId = event.tripId;
    if (tripId.isEmpty) return;
    // optimistic UI: emit loading indicator
    emit(TripDetailLoadInProgress());
    try {
      await submitTripForAudit(tripId);
      try {
        await refreshCoordinator.refreshAll().timeout(
          const Duration(seconds: 8),
          onTimeout: () async {},
        );
      } catch (_) {}
      final preview = await getTripPreview(tripId);
      final items = await getTripItems(tripId);
      emit(TripDetailLoadSuccess(preview: preview, items: items));
    } on TripDetailFailure catch (e) {
      emit(TripDetailLoadFailure(e.message));
    } catch (e) {
      emit(TripDetailLoadFailure(e.toString()));
    }
  }

  Future<void> _onDeleteItemRequested(
    DeleteItemRequested event,
    Emitter<TripDetailState> emit,
  ) async {
    final tripId = event.tripId;
    final itemId = event.itemId;
    if (tripId.isEmpty || itemId.isEmpty) return;
    emit(TripDetailLoadInProgress());
    try {
      final ok = await deleteTripItem(tripId, itemId);
      // refresh list
      final preview = await getTripPreview(tripId);
      final items = await getTripItems(tripId);
      if (ok) {
        emit(
          TripDetailActionSuccess(
            preview: preview,
            items: items,
            message: 'Data berhasil dihapus',
          ),
        );
      } else {
        emit(TripDetailLoadFailure('Gagal menghapus item'));
      }
    } on TripDetailFailure catch (e) {
      emit(TripDetailLoadFailure(e.message));
    } catch (e) {
      emit(TripDetailLoadFailure(e.toString()));
    }
  }

  Future<void> _onUpdateItemRequested(
    UpdateItemRequested event,
    Emitter<TripDetailState> emit,
  ) async {
    final tripId = event.tripId;
    final itemId = event.itemId;
    final patch = event.patch;
    if (tripId.isEmpty || itemId.isEmpty) return;
    emit(TripDetailLoadInProgress());
    try {
      final ok = await updateTripItem(tripId, itemId, patch);
      if (!ok) {
        emit(TripDetailLoadFailure('Gagal memperbarui item'));
        return;
      }

      if (event.replaceAttachments) {
        final cleared = await clearTripItemAttachments(
          tripId,
          itemId,
          event.oldAttachmentPaths,
        );
        if (!cleared) {
          emit(TripDetailLoadFailure('Gagal menghapus foto lama'));
          return;
        }
      }

      if (event.newAttachment != null) {
        final uploaded = await uploadTripItemAttachment(
          tripId,
          itemId,
          event.newAttachment!,
        );
        if (!uploaded) {
          emit(TripDetailLoadFailure('Gagal upload foto baru'));
          return;
        }
      }

      final preview = await getTripPreview(tripId);
      final items = await getTripItems(tripId);
      emit(
        TripDetailActionSuccess(
          preview: preview,
          items: items,
          message: 'Data berhasil di edit',
        ),
      );
    } on TripDetailFailure catch (e) {
      emit(TripDetailLoadFailure(e.message));
    } catch (e) {
      emit(TripDetailLoadFailure(e.toString()));
    }
  }
}
