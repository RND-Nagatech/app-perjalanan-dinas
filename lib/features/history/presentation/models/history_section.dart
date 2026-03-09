import 'package:perjalanan_dinas/core/domain/entities/trip_entity.dart';

class HistorySection {
  final String title;
  final List<TripEntity> items;

  HistorySection({required this.title, required this.items});
}
