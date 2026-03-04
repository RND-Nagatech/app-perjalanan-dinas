import 'package:trips_apps/core/domain/entities/trip_entity.dart';

class TripDetailModel extends TripEntity {
  @override
  // ignore: overridden_fields
  final DateTime? dateTo;

  const TripDetailModel({
    required super.id,
    required super.name,
    required super.destination,
    required super.operational,
    super.status,
    super.dateFrom,
    super.createdAt,
    super.userName,
    super.note,
    this.dateTo,
    super.totalInject,
    super.totalTransaksi,
    super.sisaDana,
  });

  factory TripDetailModel.fromJson(Map<String, dynamic> json) {
    final id = (json['_id'] ?? json['id'] ?? '') as String;

    dynamic op =
        json['total_inject'] ??
        json['total_approved'] ??
        json['total_transaksi'] ??
        json['sisa_dana'];
    if (op == null && json['summary'] is Map) {
      final summary = json['summary'] as Map;
      op =
          summary['total_inject'] ??
          summary['total_approved'] ??
          summary['total_transaksi'];
    }

    int operational = 0;
    if (op is int) {
      operational = op;
    }
    if (op is String) {
      operational = int.tryParse(op.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    }

    DateTime? dateFrom;
    final df =
        json['tanggal_berangkat'] ??
        json['dateFrom'] ??
        json['date_from'] ??
        json['tanggal'];
    if (df is String && df.isNotEmpty) {
      try {
        dateFrom = DateTime.parse(df).toLocal();
      } catch (_) {}
    }

    DateTime? createdAt;
    final ca = json['created_at'] ?? json['createdAt'];
    if (ca is String && ca.isNotEmpty) {
      try {
        createdAt = DateTime.parse(ca).toLocal();
      } catch (_) {}
    }

    final kode = json['kode_perjalanan'] as String?;
    final userName =
        json['user_name'] as String? ?? json['user_name'] as String?;
    final name =
        kode ?? json['user_name'] as String? ?? json['name'] as String? ?? '-';
    final destination =
        json['tujuan'] as String? ?? json['destination'] as String? ?? '-';

    final status =
        (json['status'] ?? json['status_perjalanan'] ?? json['state'])
            as String?;

    DateTime? dateTo;
    final dt =
        json['tanggal_pulang'] ?? json['dateTo'] ?? json['tanggal_pulang'];
    if (dt is String && dt.isNotEmpty) {
      try {
        dateTo = DateTime.parse(dt).toLocal();
      } catch (_) {}
    }

    final catatan = json['catatan'] as String? ?? json['note'] as String?;

    int? parsedTotalInject;
    int? parsedTotalTransaksi;
    int? parsedSisa;
    try {
      final t =
          json['total_inject'] ??
          json['totalInject'] ??
          (json['summary'] is Map
              ? (json['summary'] as Map)['total_inject']
              : null);
      if (t is int) parsedTotalInject = t;
      if (t is String) {
        parsedTotalInject = int.tryParse(t.replaceAll(RegExp(r'[^0-9]'), ''));
      }
    } catch (_) {}
    try {
      final t =
          json['total_transaksi'] ??
          json['totalTransaksi'] ??
          (json['summary'] is Map
              ? (json['summary'] as Map)['total_transaksi']
              : null);
      if (t is int) parsedTotalTransaksi = t;
      if (t is String) {
        parsedTotalTransaksi = int.tryParse(
          t.replaceAll(RegExp(r'[^0-9]'), ''),
        );
      }
    } catch (_) {}
    try {
      final t =
          json['sisa_dana'] ??
          json['sisaDana'] ??
          json['sisa'] ??
          (json['summary'] is Map
              ? (json['summary'] as Map)['sisa_dana']
              : null);
      if (t is int) parsedSisa = t;
      if (t is String) {
        parsedSisa = int.tryParse(t.replaceAll(RegExp(r'[^0-9]'), ''));
      }
    } catch (_) {}

    return TripDetailModel(
      id: id,
      name: name,
      destination: destination,
      operational: operational,
      status: status,
      dateFrom: dateFrom,
      createdAt: createdAt,
      userName: userName,
      note: catatan,
      dateTo: dateTo,
      totalInject: parsedTotalInject,
      totalTransaksi: parsedTotalTransaksi,
      sisaDana: parsedSisa,
    );
  }
}
