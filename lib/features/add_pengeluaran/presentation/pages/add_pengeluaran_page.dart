import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:intl/intl.dart';
import '../../../../core/services/custom_notice_overlay.dart';
import '../../domain/entities/active_trip.dart';
import '../bloc/add_pengeluaran_bloc.dart';

class AddPengeluaranContent extends StatefulWidget {
  const AddPengeluaranContent({super.key});

  @override
  State<AddPengeluaranContent> createState() => _AddPengeluaranContentState();
}

class _AddPengeluaranContentState extends State<AddPengeluaranContent> {
  final TextEditingController _keterangan = TextEditingController();
  final TextEditingController _nominal = TextEditingController();
  final FocusNode _keteranganFocus = FocusNode();
  final FocusNode _nominalFocus = FocusNode();
  final FocusNode _tanggalFocus = FocusNode();
  DateTime? _tanggal;
  final List<File> _attachments = [];
  bool _isFormattingNominal = false;
  OverlayEntry? _activeNoticeEntry;

  @override
  void initState() {
    super.initState();
    _tanggal = DateTime.now();
    _keteranganFocus.addListener(_onFocusChanged);
    _nominalFocus.addListener(_onFocusChanged);
    _tanggalFocus.addListener(_onFocusChanged);
  }

  void _onFocusChanged() {
    if (mounted) setState(() {});
  }

  void _formatNominalInput() {
    if (_isFormattingNominal) return;
    _isFormattingNominal = true;
    final raw = _nominal.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (raw.isEmpty) {
      _nominal.value = const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
      _isFormattingNominal = false;
      return;
    }

    final formatted = NumberFormat.decimalPattern(
      'id_ID',
    ).format(int.parse(raw));
    _nominal.value = TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
    _isFormattingNominal = false;
  }

  InputDecoration _buildInputDecoration({
    required IconData icon,
    required String hintText,
    required bool isFocused,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      prefixIcon: Icon(icon, color: isFocused ? const Color(0xFF0E7C7B) : null),
      hintText: hintText,
      filled: true,
      fillColor: isFocused ? const Color(0xFFEAF9F8) : Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: isFocused ? const Color(0xFF0E7C7B) : const Color(0xFFD9DEE3),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF0E7C7B), width: 1.8),
      ),
      suffixIcon: suffixIcon,
    );
  }

  @override
  void dispose() {
    _activeNoticeEntry?.remove();
    _activeNoticeEntry = null;
    _keterangan.dispose();
    _nominal.dispose();
    _keteranganFocus.removeListener(_onFocusChanged);
    _nominalFocus.removeListener(_onFocusChanged);
    _tanggalFocus.removeListener(_onFocusChanged);
    _keteranganFocus.dispose();
    _nominalFocus.dispose();
    _tanggalFocus.dispose();
    super.dispose();
  }

  Future<bool> _ensurePermission(Permission perm) async {
    final status = await perm.status;
    if (status.isGranted) return true;
    final result = await perm.request();
    return result.isGranted;
  }

  Future<void> _pickImage(ImageSource source) async {
    if (source == ImageSource.camera) {
      final ok = await _ensurePermission(Permission.camera);
      if (!ok) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Izin kamera diperlukan')));
        return;
      }
    }
    final picker = ImagePicker();
    if (source == ImageSource.gallery) {
      final List<XFile> picked = await picker.pickMultiImage(
        maxWidth: 1920,
        maxHeight: 1080,
      );
      if (picked.isNotEmpty) {
        setState(() {
          _attachments.addAll(picked.map((file) => File(file.path)));
        });
      }
      return;
    }

    final XFile? picked = await picker.pickImage(
      source: source,
      maxWidth: 1920,
      maxHeight: 1080,
    );
    if (picked != null) {
      setState(() {
        _attachments.add(File(picked.path));
      });
    }
  }

  Future<void> _showAttachmentSourceSheet() async {
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Pilih 1 atau lebih dari Galeri'),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined),
                title: const Text('Ambil dari Kamera'),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _pickImage(ImageSource.camera);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAttachmentGridPreview() {
    if (_attachments.isEmpty) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.camera_alt, color: Color(0xFF0E7C7B), size: 28),
          SizedBox(height: 8),
          Text(
            'Ambil Foto atau Upload',
            style: TextStyle(color: Colors.black54),
          ),
        ],
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _attachments.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1,
      ),
      itemBuilder: (context, index) {
        return Stack(
          children: [
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.file(_attachments[index], fit: BoxFit.cover),
              ),
            ),
            Positioned(
              right: 4,
              top: 4,
              child: InkWell(
                onTap: () => setState(() => _attachments.removeAt(index)),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: const Icon(Icons.close, size: 14, color: Colors.white),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEmptyTripInfo() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE9EDF1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.info_outline, color: Color(0xFF0E7C7B), size: 20),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Belum ada perjalanan aktif untuk akun ini.',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Silahkan buat perjalanan aktif terlebih dahulu, lalu coba muat ulang.',
            style: TextStyle(color: Colors.black54),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed: () {
                context.read<AddPengeluaranBloc>().add(
                  const LoadActiveTripsEvent(),
                );
              },
              icon: const Icon(Icons.refresh, color: Color(0xFF0E7C7B)),
              label: const Text(
                'Muat Ulang',
                style: TextStyle(color: Color(0xFF0E7C7B)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showTripPickerSheet({
    required List<ActiveTrip> trips,
    required String? selectedId,
  }) async {
    if (!mounted) return;
    final selected = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: trips.length,
            separatorBuilder: (_, index) => const Divider(height: 1),
            itemBuilder: (ctx, i) {
              final trip = trips[i];
              final id = trip.id;
              final label = trip.label;
              final isActive = id == selectedId;
              return ListTile(
                title: Text(label),
                trailing: isActive
                    ? const Icon(Icons.check, color: Color(0xFF0E7C7B))
                    : null,
                onTap: () => Navigator.of(sheetContext).pop(id),
              );
            },
          ),
        );
      },
    );

    if (selected == null) return;
    final idx = trips.indexWhere((trip) => trip.id == selected);
    if (!mounted) return;
    if (idx >= 0) {
      context.read<AddPengeluaranBloc>().add(SelectTripEvent(trips[idx]));
    }
  }

  String _formatCurrency(num? value) {
    final nf = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    if (value == null) return '-';
    return nf.format(value);
  }

  void _showCustomNotice(String message, {bool isError = false}) {
    _activeNoticeEntry?.remove();
    final entry = CustomNoticeOverlay.show(context, message, isError: isError);
    _activeNoticeEntry = entry;

    Future<void>.delayed(const Duration(seconds: 3), () {
      if (!mounted) return;
      if (_activeNoticeEntry == entry) {
        _activeNoticeEntry?.remove();
        _activeNoticeEntry = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final pageState = context.watch<AddPengeluaranBloc>().state;
    final draftCount = pageState is AddPengeluaranLoaded
        ? (pageState.drafts?.length ?? 0)
        : 0;
    final selectedTrip = pageState is AddPengeluaranLoaded
        ? pageState.selectedTrip
        : null;
    final nominalValue = int.tryParse(
      _nominal.text.replaceAll(RegExp(r'[^0-9]'), ''),
    );
    final hasValidFormData =
        _keterangan.text.trim().isNotEmpty &&
        _tanggal != null &&
        (nominalValue ?? 0) > 0;
    final canAddDraft = selectedTrip != null && hasValidFormData;
    final canSaveAll =
        selectedTrip != null &&
        pageState is AddPengeluaranLoaded &&
        (pageState.drafts?.isNotEmpty ?? false);
    final isSaving = pageState is AddPengeluaranSaving;
    final nextItemNumber = draftCount + 1;

    return BlocListener<AddPengeluaranBloc, AddPengeluaranState>(
      listener: (context, state) {
        if (state is AddPengeluaranSaved) {
          _showCustomNotice('Transaksi berhasil disimpan');
        }
      },
      child: MediaQuery.removeViewInsets(
        removeBottom: true,
        context: context,
        child: Container(
          color: const Color(0xFF0E7C7B),
          child: Column(
            children: [
              SafeArea(
                bottom: false,
                child: SizedBox(
                  width: double.infinity,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 26),
                    child: const Center(
                      child: Text(
                        'Tambah Pengeluaran',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 36 / 2,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  clipBehavior: Clip.antiAlias,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF2F4F7),
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(34),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
                    child: SingleChildScrollView(
                      padding: EdgeInsets.only(
                        bottom: MediaQuery.of(context).padding.bottom + 16,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 6),
                          BlocBuilder<AddPengeluaranBloc, AddPengeluaranState>(
                            builder: (context, state) {
                              ActiveTrip? selected;
                              if (state is AddPengeluaranLoaded) {
                                selected = state.selectedTrip;
                              }
                              final sisa = selected?.sisaDana;
                              return Container(
                                padding: const EdgeInsets.all(14),
                                margin: const EdgeInsets.only(bottom: 12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: const Color(0xFFE9EDF1),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFECF8F7),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Icon(
                                        Icons.account_balance_wallet,
                                        color: Color(0xFF0E7C7B),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Sisa Anggaran',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.black54,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            _formatCurrency(sisa),
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Icon(
                                      Icons.lock_outline,
                                      color: Colors.grey,
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 8),
                          BlocBuilder<AddPengeluaranBloc, AddPengeluaranState>(
                            builder: (context, state) {
                              if (state is AddPengeluaranLoaded) {
                                final trips = state.trips;
                                final selected = state.selectedTrip;
                                final selectedId = selected?.id;
                                final hasTrips = trips.isNotEmpty;
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Pilih Perjalanan Aktif',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    if (!hasTrips)
                                      _buildEmptyTripInfo()
                                    else
                                      InkWell(
                                        borderRadius: BorderRadius.circular(16),
                                        onTap: () => _showTripPickerSheet(
                                          trips: trips,
                                          selectedId: selectedId,
                                        ),
                                        child: Container(
                                          width: double.infinity,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 16,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(
                                              16,
                                            ),
                                            border: Border.all(
                                              color: const Color(0xFF6B6B72),
                                              width: 1.1,
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              const Icon(
                                                Icons.work_outline,
                                                color: Color(0xFF4F4F59),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Text(
                                                  selectedId == null
                                                      ? 'Pilih perjalanan...'
                                                      : selected?.label ??
                                                            'Pilih perjalanan...',
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    color: selectedId == null
                                                        ? const Color(
                                                            0xFF5E5E66,
                                                          )
                                                        : Colors.black87,
                                                  ),
                                                ),
                                              ),
                                              const Icon(
                                                Icons.keyboard_arrow_down,
                                                color: Color(0xFF8C8C94),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                  ],
                                );
                              }
                              if (state is AddPengeluaranLoading) {
                                return const Center(
                                  child: CircularProgressIndicator(),
                                );
                              }
                              return const SizedBox.shrink();
                            },
                          ),
                          const SizedBox(height: 12),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(22),
                              border: Border.all(
                                color: const Color(0xFFE9EDF1),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color.fromRGBO(0, 0, 0, 0.02),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'DETAIL ITEM BARU',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF6F8F7),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        'ITEM #$nextItemNumber',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.black54,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                const Text(
                                  'Keterangan',
                                  style: TextStyle(color: Colors.black54),
                                ),
                                const SizedBox(height: 8),
                                TextField(
                                  controller: _keterangan,
                                  focusNode: _keteranganFocus,
                                  onChanged: (_) => setState(() {}),
                                  decoration: _buildInputDecoration(
                                    icon: Icons.description,
                                    hintText:
                                        'Contoh: Tiket Pesawat ke Jakarta',
                                    isFocused: _keteranganFocus.hasFocus,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                const Text(
                                  'Nominal',
                                  style: TextStyle(color: Colors.black54),
                                ),
                                const SizedBox(height: 8),
                                TextField(
                                  controller: _nominal,
                                  keyboardType: TextInputType.number,
                                  focusNode: _nominalFocus,
                                  onChanged: (_) {
                                    _formatNominalInput();
                                    setState(() {});
                                  },
                                  inputFormatters: [
                                    FilteringTextInputFormatter.allow(
                                      RegExp(r'[0-9.]'),
                                    ),
                                  ],
                                  decoration: _buildInputDecoration(
                                    icon: Icons.attach_money,
                                    hintText: '0',
                                    isFocused: _nominalFocus.hasFocus,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                const Text(
                                  'Tanggal',
                                  style: TextStyle(color: Colors.black54),
                                ),
                                const SizedBox(height: 8),
                                TextField(
                                  readOnly: true,
                                  focusNode: _tanggalFocus,
                                  onTap: () async {
                                    _tanggalFocus.requestFocus();
                                    final d = await showDatePicker(
                                      context: context,
                                      initialDate: DateTime.now(),
                                      firstDate: DateTime(2000),
                                      lastDate: DateTime(2100),
                                    );
                                    if (d != null) {
                                      setState(() => _tanggal = d);
                                    }
                                    if (!mounted) return;
                                    _tanggalFocus.unfocus();
                                  },
                                  controller: TextEditingController(
                                    text: _tanggal == null
                                        ? ''
                                        : DateFormat(
                                            'yyyy-MM-dd',
                                          ).format(_tanggal!),
                                  ),
                                  decoration: _buildInputDecoration(
                                    icon: Icons.calendar_today,
                                    hintText: 'mm/dd/yyyy',
                                    isFocused: _tanggalFocus.hasFocus,
                                    suffixIcon: IconButton(
                                      icon: const Icon(Icons.calendar_today),
                                      onPressed: () async {
                                        final d = await showDatePicker(
                                          context: context,
                                          initialDate: DateTime.now(),
                                          firstDate: DateTime(2000),
                                          lastDate: DateTime(2100),
                                        );
                                        if (d != null) {
                                          setState(() => _tanggal = d);
                                        }
                                      },
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                const Text(
                                  'Unggah Lampiran',
                                  style: TextStyle(color: Colors.black54),
                                ),
                                const SizedBox(height: 8),
                                GestureDetector(
                                  onTap: _showAttachmentSourceSheet,
                                  child: Container(
                                    width: double.infinity,
                                    constraints: const BoxConstraints(
                                      minHeight: 110,
                                    ),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: Colors.grey.shade300,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(8),
                                      child: _buildAttachmentGridPreview(),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 14),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF0E7C7B),
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 14,
                                      ),
                                      minimumSize: const Size.fromHeight(52),
                                    ),
                                    onPressed: canAddDraft
                                        ? () {
                                            final item = DraftItem(
                                              tanggal: _tanggal != null
                                                  ? DateFormat(
                                                      'yyyy-MM-dd',
                                                    ).format(_tanggal!)
                                                  : DateFormat(
                                                      'yyyy-MM-dd',
                                                    ).format(DateTime.now()),
                                              nominal:
                                                  int.tryParse(
                                                    _nominal.text.replaceAll(
                                                      RegExp(r'[^0-9]'),
                                                      '',
                                                    ),
                                                  ) ??
                                                  0,
                                              keterangan: _keterangan.text
                                                  .trim(),
                                              attachments: List<File>.from(
                                                _attachments,
                                              ),
                                            );
                                            context
                                                .read<AddPengeluaranBloc>()
                                                .add(AddDraftEvent(item));
                                            setState(() {
                                              _keterangan.clear();
                                              _nominal.clear();
                                              _tanggal = DateTime.now();
                                              _attachments.clear();
                                            });
                                          }
                                        : null,
                                    icon: const Icon(
                                      Icons.playlist_add_check_circle_outlined,
                                    ),
                                    label: const Text(
                                      'Tambahkan ke Draft',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Draft Pengeluaran($draftCount)',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 8),
                          BlocBuilder<AddPengeluaranBloc, AddPengeluaranState>(
                            builder: (context, state) {
                              if (state is AddPengeluaranLoaded) {
                                final drafts = state.drafts ?? [];
                                if (drafts.isEmpty) {
                                  return const Center(
                                    child: Text('Draft kosong'),
                                  );
                                }
                                return ListView.separated(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: drafts.length,
                                  separatorBuilder: (c, i) =>
                                      const SizedBox(height: 8),
                                  itemBuilder: (ctx, i) {
                                    final d = drafts[i];
                                    return Container(
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF8FCFC),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: const Color(0xFFD8EEED),
                                        ),
                                      ),
                                      child: ListTile(
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                              horizontal: 14,
                                              vertical: 6,
                                            ),
                                        leading: Container(
                                          width: 44,
                                          height: 44,
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFEAF9F8),
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                          child: const Icon(
                                            Icons.receipt_long,
                                            color: Color(0xFF0E7C7B),
                                          ),
                                        ),
                                        title: Text(
                                          d.keterangan,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF1F2937),
                                          ),
                                        ),
                                        subtitle: Text(
                                          d.tanggal,
                                          style: const TextStyle(
                                            color: Color(0xFF6B7280),
                                          ),
                                        ),
                                        trailing: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              _formatCurrency(d.nominal),
                                              style: const TextStyle(
                                                color: Color(0xFF0E7C7B),
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                            IconButton(
                                              icon: const Icon(
                                                Icons.delete_outline,
                                                color: Color(0xFF9CA3AF),
                                              ),
                                              onPressed: () => context
                                                  .read<AddPengeluaranBloc>()
                                                  .add(RemoveDraftEvent(d.id)),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                );
                              }
                              if (state is AddPengeluaranLoading) {
                                return const Center(
                                  child: CircularProgressIndicator(),
                                );
                              }
                              if (state is AddPengeluaranFailure) {
                                return Center(
                                  child: Text('Error: ${state.message}'),
                                );
                              }
                              return const SizedBox.shrink();
                            },
                          ),
                          const SizedBox(height: 12),
                          Builder(
                            builder: (context) {
                              final state = context
                                  .watch<AddPengeluaranBloc>()
                                  .state;
                              int total = 0;
                              if (state is AddPengeluaranLoaded) {
                                total = (state.drafts ?? []).fold<int>(
                                  0,
                                  (p, e) => p + e.nominal,
                                );
                              } else if (state is AddPengeluaranSaving) {
                                total = state.totalNominal;
                              }
                              return SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF0E7C7B),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    minimumSize: const Size.fromHeight(52),
                                  ),
                                  onPressed: (canSaveAll && !isSaving)
                                      ? () => context
                                            .read<AddPengeluaranBloc>()
                                            .add(SaveAllEvent())
                                      : null,
                                  child: isSaving
                                      ? Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            const SizedBox(
                                              width: 18,
                                              height: 18,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: Colors.white,
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            Text(
                                              'Menyimpan (${_formatCurrency(total)})',
                                            ),
                                          ],
                                        )
                                      : Text(
                                          'Simpan Semua (${_formatCurrency(total)})',
                                        ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DraftEditorPage extends StatefulWidget {
  const DraftEditorPage({super.key});

  @override
  State<DraftEditorPage> createState() => _DraftEditorPageState();
}

class _DraftEditorPageState extends State<DraftEditorPage> {
  final TextEditingController _keterangan = TextEditingController();
  final TextEditingController _nominal = TextEditingController();
  DateTime? _tanggal;
  final List<File> _attachments = [];

  @override
  void dispose() {
    _keterangan.dispose();
    _nominal.dispose();
    super.dispose();
  }

  Future<bool> _ensurePermission(Permission perm) async {
    final status = await perm.status;
    if (status.isGranted) return true;
    final result = await perm.request();
    return result.isGranted;
  }

  Future<void> _pickImage(ImageSource source) async {
    if (source == ImageSource.camera) {
      final ok = await _ensurePermission(Permission.camera);
      if (!ok) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Izin kamera diperlukan')));
        return;
      }
    }
    final picker = ImagePicker();
    if (source == ImageSource.gallery) {
      final List<XFile> picked = await picker.pickMultiImage(
        maxWidth: 1920,
        maxHeight: 1080,
      );
      if (picked.isNotEmpty) {
        setState(() {
          _attachments.addAll(picked.map((file) => File(file.path)));
        });
      }
      return;
    }

    final XFile? picked = await picker.pickImage(
      source: source,
      maxWidth: 1920,
      maxHeight: 1080,
    );
    if (picked != null) {
      setState(() {
        _attachments.add(File(picked.path));
      });
    }
  }

  Future<void> _showAttachmentSourceSheet() async {
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Pilih 1 atau lebih dari Galeri'),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined),
                title: const Text('Ambil dari Kamera'),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _pickImage(ImageSource.camera);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAttachmentGridPreview() {
    if (_attachments.isEmpty) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.camera_alt, color: Color(0xFF0E7C7B), size: 28),
          SizedBox(height: 8),
          Text(
            'Ambil Foto atau Upload',
            style: TextStyle(color: Colors.black54),
          ),
        ],
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _attachments.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1,
      ),
      itemBuilder: (context, index) {
        return Stack(
          children: [
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.file(_attachments[index], fit: BoxFit.cover),
              ),
            ),
            Positioned(
              right: 4,
              top: 4,
              child: InkWell(
                onTap: () => setState(() => _attachments.removeAt(index)),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: const Icon(Icons.close, size: 14, color: Colors.white),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Item Baru'),
        backgroundColor: const Color(0xFF0E7C7B),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Keterangan',
                  style: TextStyle(color: Colors.black54),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _keterangan,
                  decoration: const InputDecoration(
                    hintText: 'Contoh: Tiket Pesawat ke Jakarta',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                const Text('Nominal', style: TextStyle(color: Colors.black54)),
                const SizedBox(height: 8),
                TextField(
                  controller: _nominal,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    hintText: '0',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                const Text('Tanggal', style: TextStyle(color: Colors.black54)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _tanggal == null
                            ? 'Pilih tanggal'
                            : DateFormat('yyyy-MM-dd').format(_tanggal!),
                      ),
                    ),
                    TextButton(
                      onPressed: () async {
                        final d = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (d != null) setState(() => _tanggal = d);
                      },
                      child: const Text('Pilih'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'Unggah Lampiran',
                  style: TextStyle(color: Colors.black54),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: _showAttachmentSourceSheet,
                  child: Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(minHeight: 110),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: _buildAttachmentGridPreview(),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.photo),
                        label: const Text('Pilih Foto'),
                        onPressed: () => _pickImage(ImageSource.gallery),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('Ambil Foto'),
                      onPressed: () => _pickImage(ImageSource.camera),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0E7C7B),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    final item = DraftItem(
                      tanggal: _tanggal != null
                          ? DateFormat('yyyy-MM-dd').format(_tanggal!)
                          : DateFormat('yyyy-MM-dd').format(DateTime.now()),
                      nominal:
                          int.tryParse(
                            _nominal.text.replaceAll(RegExp(r'[^0-9]'), ''),
                          ) ??
                          0,
                      keterangan: _keterangan.text.trim(),
                      attachments: List<File>.from(_attachments),
                    );
                    context.read<AddPengeluaranBloc>().add(AddDraftEvent(item));
                    Navigator.of(context).pop();
                  },
                  child: const Text('Tambahkan ke Draft'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
