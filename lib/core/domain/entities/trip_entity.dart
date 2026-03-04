class TripEntity {
  final String id;
  final String name;
  final String destination;
  final int operational;
  final String? userName;
  final String? note;
  final String? status;
  final DateTime? dateFrom;
  final DateTime? dateTo;
  final DateTime? createdAt;
  final int? totalInject;
  final int? totalTransaksi;
  final int? sisaDana;

  const TripEntity({
    required this.id,
    required this.name,
    required this.destination,
    required this.operational,
    this.userName,
    this.note,
    this.status,
    this.dateFrom,
    this.dateTo,
    this.createdAt,
    this.totalInject,
    this.totalTransaksi,
    this.sisaDana,
  });
}
