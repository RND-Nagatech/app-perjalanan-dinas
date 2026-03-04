import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../domain/entities/active_trip.dart';
import '../../domain/failures/add_pengeluaran_failure.dart' as domain_failure;
import '../../domain/usecases/get_active_trips.dart';
import '../../domain/usecases/create_item.dart';
import '../../domain/usecases/upload_attachment.dart';

part 'add_pengeluaran_event.dart';
part 'add_pengeluaran_state.dart';

class DraftItem {
  final String id;
  String tanggal;
  int nominal;
  String keterangan;
  List<File> attachments;

  DraftItem({
    String? id,
    required this.tanggal,
    required this.nominal,
    required this.keterangan,
    List<File>? attachments,
  }) : attachments = attachments ?? [],
       id = id ?? DateTime.now().microsecondsSinceEpoch.toString();
}

class AddPengeluaranBloc
    extends Bloc<AddPengeluaranEvent, AddPengeluaranState> {
  final GetActiveTrips getActiveTrips;
  final CreateItem createItem;
  final UploadAttachment uploadAttachment;

  AddPengeluaranBloc({
    required this.getActiveTrips,
    required this.createItem,
    required this.uploadAttachment,
  }) : super(AddPengeluaranInitial()) {
    on<LoadActiveTripsEvent>(_onLoadActive);
    on<SelectTripEvent>(_onSelectTrip);
    on<AddDraftEvent>(_onAddDraft);
    on<RemoveDraftEvent>(_onRemoveDraft);
    on<SaveAllEvent>(_onSaveAll);
  }

  Future<void> _onLoadActive(
    LoadActiveTripsEvent event,
    Emitter<AddPengeluaranState> emit,
  ) async {
    final previous = state is AddPengeluaranLoaded
        ? state as AddPengeluaranLoaded
        : null;
    if (previous == null) {
      emit(AddPengeluaranLoading());
    }
    try {
      final trips = await getActiveTrips.call();
      final preferredId = event.preferredTripId ?? previous?.selectedTrip?.id;
      ActiveTrip? selectedTrip = previous?.selectedTrip;
      if (preferredId != null && preferredId.isNotEmpty) {
        for (final trip in trips) {
          final tripId = trip.id;
          if (tripId == preferredId) {
            selectedTrip = trip;
            break;
          }
        }
      }
      emit(
        AddPengeluaranLoaded(
          trips: trips,
          selectedTrip: selectedTrip,
          drafts: previous?.drafts,
        ),
      );
    } on domain_failure.AddPengeluaranFailure catch (e) {
      emit(AddPengeluaranFailure(message: e.message));
    } catch (e) {
      emit(AddPengeluaranFailure(message: e.toString()));
    }
  }

  Future<void> _onSelectTrip(
    SelectTripEvent event,
    Emitter<AddPengeluaranState> emit,
  ) async {
    final s = state;
    if (s is AddPengeluaranLoaded) {
      emit(s.copyWith(selectedTrip: event.trip));
    }
  }

  Future<void> _onAddDraft(
    AddDraftEvent event,
    Emitter<AddPengeluaranState> emit,
  ) async {
    final s = state;
    if (s is AddPengeluaranLoaded) {
      final newDrafts = List<DraftItem>.from(s.drafts ?? []);
      newDrafts.add(event.item);
      emit(s.copyWith(drafts: newDrafts));
    }
  }

  Future<void> _onRemoveDraft(
    RemoveDraftEvent event,
    Emitter<AddPengeluaranState> emit,
  ) async {
    final s = state;
    if (s is AddPengeluaranLoaded) {
      final newDrafts = List<DraftItem>.from(s.drafts ?? [])
        ..removeWhere((d) => d.id == event.id);
      emit(s.copyWith(drafts: newDrafts));
    }
  }

  Future<void> _onSaveAll(
    SaveAllEvent event,
    Emitter<AddPengeluaranState> emit,
  ) async {
    final s = state;
    if (s is! AddPengeluaranLoaded) return;
    if (s.selectedTrip == null) return;
    final totalNominal = (s.drafts ?? []).fold<int>(
      0,
      (previousValue, draft) => previousValue + draft.nominal,
    );
    emit(AddPengeluaranSaving(totalNominal: totalNominal));
    try {
      final tripId = s.selectedTrip!.id;
      for (final d in s.drafts ?? []) {
        final payload = {
          'tanggal_transaksi': d.tanggal,
          'nominal': d.nominal,
          'keterangan': d.keterangan,
        };
        final created = await createItem.call(tripId, payload);
        final itemId = created.id;
        if (d.attachments.isNotEmpty) {
          for (final file in d.attachments) {
            await uploadAttachment.call(
              tripId,
              itemId,
              file,
            );
          }
        }
      }
      // clear drafts after success
      emit(AddPengeluaranSaved());
      // reload trips to refresh sisa
      add(LoadActiveTripsEvent());
    } on domain_failure.AddPengeluaranFailure catch (e) {
      emit(AddPengeluaranFailure(message: e.message));
    } catch (e) {
      emit(AddPengeluaranFailure(message: e.toString()));
    }
  }
}
