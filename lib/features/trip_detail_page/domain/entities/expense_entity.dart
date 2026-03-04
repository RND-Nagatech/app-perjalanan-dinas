class ExpenseEntity {
  final String? id;
  final String? tanggal;
  final double? nominal;
  final String? keterangan;
  final String? category;
  final List<ExpenseAttachment> attachments;

  ExpenseEntity({
    this.id,
    this.tanggal,
    this.nominal,
    this.keterangan,
    this.category,
    this.attachments = const <ExpenseAttachment>[],
  });

  factory ExpenseEntity.fromJson(Map<String, dynamic> json) {
    double? parseNominal(dynamic v) {
      if (v == null) return null;
      if (v is num) return v.toDouble();
      if (v is String) return double.tryParse(v.replaceAll(',', ''));
      return null;
    }

    return ExpenseEntity(
      id: (json['id'] ?? json['_id'])?.toString(),
      tanggal:
          json['tanggal'] as String? ??
          json['date'] as String? ??
          json['tanggal_transaksi'] as String?,
      nominal: parseNominal(json['nominal'] ?? json['amount']),
      keterangan: json['keterangan'] as String? ?? json['title'] as String?,
      category: json['category'] as String?,
      attachments: _parseAttachments(json['attachments']),
    );
  }

  static List<ExpenseAttachment> _parseAttachments(dynamic raw) {
    if (raw is! List) return const <ExpenseAttachment>[];
    return raw
        .whereType<Map>()
        .map((m) => ExpenseAttachment.fromJson(Map<String, dynamic>.from(m)))
        .toList();
  }
}

class ExpenseAttachment {
  final String path;
  final String? originalName;
  final String? mimeType;
  final int? size;

  const ExpenseAttachment({
    required this.path,
    this.originalName,
    this.mimeType,
    this.size,
  });

  factory ExpenseAttachment.fromJson(Map<String, dynamic> json) {
    return ExpenseAttachment(
      path: (json['path'] ?? '').toString(),
      originalName: json['original_name']?.toString(),
      mimeType: json['mime_type']?.toString(),
      size: (json['size'] is num) ? (json['size'] as num).toInt() : null,
    );
  }
}
