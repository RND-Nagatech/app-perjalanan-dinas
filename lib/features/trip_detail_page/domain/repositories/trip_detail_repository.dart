import '../entities/expense_entity.dart';
import 'dart:io';
import 'package:trips_apps/core/domain/entities/trip_entity.dart';

abstract class TripDetailRepository {
  /// Fetch expense items for a perjalanan id
  Future<List<ExpenseEntity>> getItemsForTrip(String tripId);

  /// Fetch trip preview/metadata for the current user and specified trip id
  Future<TripEntity?> getTripPreview(String tripId);

  /// Submit the trip for audit / change status to 'Sedang di audit'
  Future<bool> submitTripForAudit(String tripId);
  /// Delete an item from a perjalanan
  Future<bool> deleteItem(String tripId, String itemId);

  /// Update an item for a perjalanan. Returns true on success.
  Future<bool> updateItem(String tripId, String itemId, Map<String, dynamic> patch);

  /// Clear existing attachments for an item. Returns true on success.
  Future<bool> clearItemAttachments(
    String tripId,
    String itemId,
    List<String> attachmentPaths,
  );

  /// Upload new attachment to an item. Returns true on success.
  Future<bool> uploadItemAttachment(String tripId, String itemId, File file);
}
