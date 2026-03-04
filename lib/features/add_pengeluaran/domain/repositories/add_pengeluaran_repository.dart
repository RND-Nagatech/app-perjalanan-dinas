import 'dart:io';

import '../entities/active_trip.dart';
import '../entities/created_item.dart';

abstract class AddPengeluaranRepository {
  Future<List<ActiveTrip>> getActiveTrips();
  Future<int?> getSisaForTrip(String tripId);
  Future<CreatedItem> createItem(
    String tripId,
    Map<String, dynamic> payload,
  );
  Future<void> uploadAttachment(String tripId, String itemId, File file);
}
