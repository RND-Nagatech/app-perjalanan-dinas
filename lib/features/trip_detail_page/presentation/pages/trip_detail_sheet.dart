import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:trips_apps/core/constan/constan.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import '../../domain/entities/expense_entity.dart';
import '../bloc/trip_detail_page_bloc.dart';
import '../bloc/trip_detail_page_event.dart';

class TripDetailSheet extends StatefulWidget {
  final String tripId;
  final String? status;
  final double sisaDana;
  final double totalInject;
  final double totalTransaksi;
  final List<ExpenseEntity> items;

  const TripDetailSheet({
    super.key,
    required this.tripId,
    required this.status,
    required this.sisaDana,
    required this.totalInject,
    required this.totalTransaksi,
    required this.items,
  });

  @override
  State<TripDetailSheet> createState() => _TripDetailSheetState();
}

class _TripDetailSheetState extends State<TripDetailSheet> {
  bool _isSubmitting = false;

  bool get _isAudited => (widget.status ?? '').toLowerCase().contains('audit');
  bool get _isFinished =>
      (widget.status ?? '').toLowerCase().contains('selesai');
  bool get _isRunning =>
      (widget.status ?? '').toLowerCase().contains('berjalan');

  String _attachmentUrl(String path) {
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return path;
    }
    final base = Uri.parse(ApiConfig.current.baseUrl);
    final origin =
        '${base.scheme}://${base.host}${base.hasPort ? ':${base.port}' : ''}';
    if (path.startsWith('/')) return '$origin$path';
    return '$origin/$path';
  }

  Future<bool> _showDeleteConfirmDialog(ExpenseEntity item) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF1F1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.delete_outline,
                        color: Color(0xFFE53935),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Hapus transaksi?',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  'Anda yakin ingin menghapus data "${item.keterangan ?? 'Pengeluaran'}"?',
                  style: const TextStyle(color: Colors.black87, height: 1.35),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(ctx).pop(false),
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Tidak'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(ctx).pop(true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE53935),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Ya',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
    return result == true;
  }

  Future<bool> _showEndTripConfirmDialog() async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEAF9F8),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.flag_outlined,
                        color: Color(0xFF0E7C7B),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Akhiri perjalanan?',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const Text(
                  'Apakah anda yakin ingin mengakhiri perjalanan ini? Setelah dikirim ke audit, data pengeluaran tidak dapat diubah.',
                  style: TextStyle(color: Colors.black87, height: 1.35),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(ctx).pop(false),
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Tidak'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(ctx).pop(true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0E7C7B),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Ya, Akhiri',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
    return result == true;
  }

  Future<void> _showEditDialog(ExpenseEntity item) async {
    final keteranganController = TextEditingController(
      text: item.keterangan ?? '',
    );
    final nominalController = TextEditingController(
      text: NumberFormat.decimalPattern(
        'id_ID',
      ).format((item.nominal ?? 0).toInt()),
    );
    DateTime? selectedDate;
    bool replaceAttachments = false;
    File? newAttachmentFile;
    try {
      if ((item.tanggal ?? '').isNotEmpty) {
        selectedDate = DateTime.tryParse(item.tanggal!);
      }
    } catch (_) {}

    String formatYmd(DateTime date) => DateFormat('yyyy-MM-dd').format(date);

    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setLocalState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              backgroundColor: const Color(0xFFF8FCFC),
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 24,
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Edit Transaksi',
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'Keterangan',
                        style: TextStyle(color: Colors.black54),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: keteranganController,
                        decoration: InputDecoration(
                          hintText: 'Masukkan keterangan',
                          filled: true,
                          fillColor: const Color(0xFFF7F9FB),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFFE1E6EB),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFF0E7C7B),
                              width: 1.6,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Nominal',
                        style: TextStyle(color: Colors.black54),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: nominalController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                        ],
                        onChanged: (value) {
                          final raw = value.replaceAll(RegExp(r'[^0-9]'), '');
                          if (raw.isEmpty) return;
                          final formatted = NumberFormat.decimalPattern(
                            'id_ID',
                          ).format(int.parse(raw));
                          nominalController.value = TextEditingValue(
                            text: formatted,
                            selection: TextSelection.collapsed(
                              offset: formatted.length,
                            ),
                          );
                        },
                        decoration: InputDecoration(
                          hintText: '0',
                          filled: true,
                          fillColor: const Color(0xFFF7F9FB),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFFE1E6EB),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFF0E7C7B),
                              width: 1.6,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Tanggal',
                        style: TextStyle(color: Colors.black54),
                      ),
                      const SizedBox(height: 6),
                      InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: ctx,
                            initialDate: selectedDate ?? DateTime.now(),
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
                          );
                          if (picked != null) {
                            setLocalState(() => selectedDate = picked);
                          }
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF7F9FB),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE1E6EB)),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.calendar_today,
                                size: 18,
                                color: Color(0xFF0E7C7B),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                selectedDate == null
                                    ? (item.tanggal ?? 'Pilih tanggal')
                                    : formatYmd(selectedDate!),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Foto Bukti',
                        style: TextStyle(color: Colors.black54),
                      ),
                      const SizedBox(height: 6),
                      if (item.attachments.isEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF7F9FB),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE1E6EB)),
                          ),
                          child: const Text('Belum ada foto lampiran'),
                        )
                      else
                        SizedBox(
                          height: 84,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: item.attachments.length,
                            separatorBuilder: (context, index) =>
                                const SizedBox(width: 8),
                            itemBuilder: (_, i) {
                              final att = item.attachments[i];
                              return Opacity(
                                opacity: replaceAttachments ? 0.35 : 1,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Image.network(
                                    _attachmentUrl(att.path),
                                    width: 84,
                                    height: 84,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, error, stackTrace) =>
                                        Container(
                                          width: 84,
                                          height: 84,
                                          color: const Color(0xFFF1F4F7),
                                          child: const Icon(
                                            Icons.broken_image_outlined,
                                          ),
                                        ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                setLocalState(() {
                                  replaceAttachments = !replaceAttachments;
                                  if (!replaceAttachments) {
                                    newAttachmentFile = null;
                                  }
                                });
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: replaceAttachments
                                    ? const Color(0xFFE53935)
                                    : const Color(0xFF0E7C7B),
                                side: BorderSide(
                                  color: replaceAttachments
                                      ? const Color(0xFFE53935)
                                      : const Color(0xFF0E7C7B),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              icon: Icon(
                                replaceAttachments
                                    ? Icons.delete_forever_outlined
                                    : Icons.delete_outline,
                              ),
                              label: Text(
                                replaceAttachments
                                    ? 'Batalkan Hapus Foto Lama'
                                    : 'Hapus Foto Lama',
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (replaceAttachments) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () async {
                                  final picker = ImagePicker();
                                  final picked = await picker.pickImage(
                                    source: ImageSource.gallery,
                                    maxWidth: 1920,
                                    maxHeight: 1080,
                                  );
                                  if (picked == null) return;
                                  setLocalState(() {
                                    newAttachmentFile = File(picked.path);
                                  });
                                },
                                style: OutlinedButton.styleFrom(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                icon: const Icon(Icons.photo_library_outlined),
                                label: const Text('Upload Foto Baru'),
                              ),
                            ),
                          ],
                        ),
                        if (newAttachmentFile != null) ...[
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.file(
                              newAttachmentFile!,
                              height: 110,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ],
                      ],
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.of(ctx).pop(),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF0E7C7B),
                                side: const BorderSide(
                                  color: Color(0xFF0E7C7B),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                'Batal',
                                style: TextStyle(color: Color(0xFF0E7C7B)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                final id = item.id ?? '';
                                if (id.isEmpty) {
                                  Navigator.of(ctx).pop();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('ID item tidak valid'),
                                    ),
                                  );
                                  return;
                                }
                                final nominal =
                                    int.tryParse(
                                      nominalController.text.replaceAll(
                                        RegExp(r'[^0-9]'),
                                        '',
                                      ),
                                    ) ??
                                    0;
                                final patch = <String, dynamic>{
                                  'keterangan': keteranganController.text
                                      .trim(),
                                  'nominal': nominal,
                                  'tanggal_transaksi': selectedDate == null
                                      ? (item.tanggal ??
                                            DateFormat(
                                              'yyyy-MM-dd',
                                            ).format(DateTime.now()))
                                      : formatYmd(selectedDate!),
                                };
                                context.read<TripDetailPageBloc>().add(
                                  UpdateItemRequested(
                                    widget.tripId,
                                    id,
                                    patch,
                                    replaceAttachments: replaceAttachments,
                                    newAttachment: newAttachmentFile,
                                    oldAttachmentPaths: item.attachments
                                        .map((e) => e.path)
                                        .toList(),
                                  ),
                                );
                                Navigator.of(ctx).pop();
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0E7C7B),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                'Simpan',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showDetailDialog(ExpenseEntity item, NumberFormat nf) async {
    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          backgroundColor: const Color(0xFFF8FCFC),
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 24,
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEAF9F8),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.receipt_long,
                          color: Color(0xFF0E7C7B),
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'Detail Transaksi',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _infoTile('Keterangan', item.keterangan ?? '-'),
                  _infoTile('Tanggal', item.tanggal ?? '-'),
                  _infoTile('Nominal', nf.format(item.nominal ?? 0)),
                  const SizedBox(height: 12),
                  const Text(
                    'Foto Bukti',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  if (item.attachments.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        vertical: 14,
                        horizontal: 12,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF7F9FB),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE1E6EB)),
                      ),
                      child: const Text('Tidak ada lampiran foto'),
                    )
                  else
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: () =>
                            _showZoomablePhotoDialog(item.attachments),
                        icon: const Icon(
                          Icons.remove_red_eye_outlined,
                          color: Color(0xFF0E7C7B),
                        ),
                        label: const Text(
                          'Lihat foto',
                          style: TextStyle(
                            color: Color(0xFF0E7C7B),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF0E7C7B),
                            side: const BorderSide(color: Color(0xFF0E7C7B)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Tutup',
                            style: TextStyle(color: Color(0xFF0E7C7B)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            Navigator.of(ctx).pop();
                            await _showEditDialog(item);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0E7C7B),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: const Icon(
                            Icons.edit_outlined,
                            color: Colors.white,
                          ),
                          label: const Text(
                            'Edit',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _showZoomablePhotoDialog(
    List<ExpenseAttachment> attachments,
  ) async {
    if (attachments.isEmpty) return;
    final pageController = PageController();
    int currentIndex = 0;

    await showDialog<void>(
      context: context,
      barrierColor: Colors.black45,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setLocalState) {
            return Dialog(
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 38,
              ),
              backgroundColor: Colors.transparent,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(34),
                child: Container(
                  color: const Color(0xFFF1F1F1),
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 42,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.black26,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Lihat Foto',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => Navigator.of(ctx).pop(),
                              borderRadius: BorderRadius.circular(18),
                              child: Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                child: const Icon(
                                  Icons.close,
                                  color: Colors.black87,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE7E7E7),
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(color: const Color(0xFFD1D1D1)),
                        ),
                        child: SizedBox(
                          height: 430,
                          child: PageView.builder(
                            controller: pageController,
                            itemCount: attachments.length,
                            onPageChanged: (index) {
                              setLocalState(() => currentIndex = index);
                            },
                            itemBuilder: (context, index) {
                              final url = _attachmentUrl(
                                attachments[index].path,
                              );
                              return InteractiveViewer(
                                minScale: 1,
                                maxScale: 4,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(18),
                                  child: Image.network(
                                    url,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            Container(
                                              color: const Color(0xFFECECEC),
                                              alignment: Alignment.center,
                                              child: const Text(
                                                'Foto gagal dimuat',
                                                style: TextStyle(
                                                  color: Colors.black54,
                                                ),
                                              ),
                                            ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE7E7E7),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${currentIndex + 1}/${attachments.length}',
                          style: const TextStyle(
                            color: Colors.black87,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    pageController.dispose();
  }

  Widget _infoTile(String label, String value) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F9FB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE1E6EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.black54, fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final nf = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    final totalUsed = widget.items.fold<double>(
      0.0,
      (sum, e) => sum + (e.nominal ?? 0),
    );

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              // ignore: deprecated_member_use
              color: Colors.black.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 48,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),

            // Header row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Rincian Pengeluaran',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Total Digunakan: ${nf.format(totalUsed)}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        'Uang Operasional',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        nf.format(widget.totalInject),
                        style: const TextStyle(
                          color: Color(0xFF0E7C7B),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Expense list
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                ),
                child: ListView.separated(
                  itemCount: widget.items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final it = widget.items[index];
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            // ignore: deprecated_member_use
                            color: Colors.black.withOpacity(0.02),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              color: Colors.teal[50],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.receipt_long,
                              color: Color(0xFF0E7C7B),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  it.keterangan ?? 'Pengeluaran',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  it.tanggal ?? '',
                                  style: const TextStyle(
                                    color: Colors.black54,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            nf.format(it.nominal ?? 0),
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(width: 6),
                          IconButton(
                            onPressed: () => _showDetailDialog(it, nf),
                            icon: const Icon(Icons.remove_red_eye_outlined),
                            tooltip: 'Lihat',
                          ),
                          IconButton(
                            onPressed: () async {
                              final itemId = it.id ?? '';
                              if (itemId.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('ID item tidak ditemukan'),
                                  ),
                                );
                                return;
                              }
                              final confirmed = await _showDeleteConfirmDialog(
                                it,
                              );
                              if (!context.mounted) return;
                              if (confirmed) {
                                context.read<TripDetailPageBloc>().add(
                                  DeleteItemRequested(widget.tripId, itemId),
                                );
                              }
                            },
                            icon: const Icon(Icons.delete_outline),
                            tooltip: 'Hapus',
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Information box and End trip button (button placed below info)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_isAudited || _isFinished)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F9F8),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE0F0EE)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Informasi Tambahan',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0E7C7B),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _isAudited
                                ? 'Perjalanan dinas ini sedang dalam proses audit oleh tim keuangan. Semua bukti transaksi telah diunggah dan sedang dalam proses verifikasi.'
                                : 'Perjalanan dinas ini telah selesai. Data pengeluaran sudah ditutup dan siap dijadikan arsip/laporan akhir.',
                            style: const TextStyle(color: Colors.black87),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              const Icon(
                                Icons.info_outline,
                                color: Color(0xFF0E7C7B),
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Status: ${widget.status ?? (_isAudited ? 'Sedang di audit' : 'Selesai')}',
                                  style: const TextStyle(
                                    color: Color(0xFF0E7C7B),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 12),

                  ElevatedButton(
                    onPressed: (_isSubmitting || _isAudited || !_isRunning)
                        ? null
                        : () async {
                            final confirmed = await _showEndTripConfirmDialog();
                            if (!context.mounted || !confirmed) return;
                            setState(() => _isSubmitting = true);
                            try {
                              context.read<TripDetailPageBloc>().add(
                                EndTripRequested(widget.tripId),
                              );
                            } catch (_) {}
                            // keep button disabled until bloc updates status
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0E7C7B),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            'Akhiri Perjalanan',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
