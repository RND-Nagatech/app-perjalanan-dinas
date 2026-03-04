import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart'; // Keep this import

import 'package:trips_apps/core/domain/entities/trip_entity.dart';
import '../bloc/perjalanan_bloc.dart';
// Trip detail navigation handled by app router at /trip
// import '../../../trip_detail_page/injection/injection.dart' as trip_detail_inject;
// import '../../../trip_detail_page/presentation/bloc/trip_detail_page_bloc.dart';
// import '../../../trip_detail_page/presentation/bloc/trip_detail_page_event.dart';
// import '../../../trip_detail_page/presentation/bloc/trip_detail_page_state.dart';
// import '../../../trip_detail_page/presentation/pages/trip_detail_sheet.dart';

/// Perjalanan page: shows only trips whose `status` contains 'BERJALAN'.
class PerjalananPage extends StatefulWidget {
  const PerjalananPage({super.key});

  @override
  State<PerjalananPage> createState() => _PerjalananPageState();
}

class _PerjalananPageState extends State<PerjalananPage> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    // Use PerjalananContent so the page looks consistent whether embedded
    // inside home (content only) or used as a standalone route (scaffold).
    // Note: this page expects a `PerjalananBloc` to be provided by the
    // caller (e.g. HomePage or the app router). UI code must not call
    // dependency injection directly — the Bloc should be injected at a
    // higher level.
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daftar Perjalanan'),
        automaticallyImplyLeading: false,
      ),
      body: const PerjalananContent(),
    );
  }
}

/// A content-only widget that renders the perjalanan list. Use this when
/// embedding the feature inside another page (e.g. home) so the bottom
/// navigation remains visible.
class PerjalananContent extends StatelessWidget {
  const PerjalananContent({super.key});

  static const String _emptyAsset = 'assets/png/empty.png';

  String _formatCurrency(int amount) {
    final fmt = NumberFormat('#,##0', 'id_ID');
    return 'Rp ${fmt.format(amount)}';
  }

  String _formatDateRange(DateTime? from, DateTime? to) {
    if (from == null) return '';
    final df = DateFormat('dd MMM yyyy');
    if (to == null ||
        (from.year == to.year &&
            from.month == to.month &&
            from.day == to.day)) {
      return df.format(from);
    }
    return '${df.format(from)} - ${df.format(to)}';
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFEAECEF)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.asset(
                  _emptyAsset,
                  width: 200,
                  height: 200,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Tidak ada perjalanan yang sedang berjalan',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black54),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PerjalananBloc, PerjalananState>(
      builder: (context, state) {
        Widget body;
        if (state is PerjalananLoading || state is PerjalananInitial) {
          body = const Center(child: CircularProgressIndicator());
        } else if (state is PerjalananEmpty) {
          body = _buildEmptyState();
        } else if (state is PerjalananError) {
          body = Center(child: Text('Error: ${state.message}'));
        } else if (state is PerjalananLoaded) {
          final berjalan = state.trips;
          body = ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            itemCount: berjalan.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final t = berjalan[index];
              return _TripCard(
                trip: t,
                onDetail: () => context.push('/trip', extra: t),
                formatCurrency: _formatCurrency,
                formatDateRange: _formatDateRange,
              );
            },
          );
        } else {
          body = const SizedBox.shrink();
        }

        // Build header + body so UI stays below status bar
        return Column(
          children: [
            Container(
              width: double.infinity,
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
              child: SafeArea(
                bottom: false,
                child: Center(
                  child: Text(
                    'Daftar Perjalanan',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Colors.grey[900],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            // body occupies remaining space
            Expanded(child: body),
          ],
        );
      },
    );
  }
}

class _TripCard extends StatelessWidget {
  final TripEntity trip;
  final VoidCallback onDetail;
  final String Function(int) formatCurrency;
  final String Function(DateTime?, DateTime?) formatDateRange;

  const _TripCard({
    required this.trip,
    required this.onDetail,
    required this.formatCurrency,
    required this.formatDateRange,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      borderRadius: BorderRadius.circular(16),
      elevation: 0.8,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'TUJUAN',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        trip.destination,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'TANGGAL',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      formatDateRange(trip.dateFrom, (trip as dynamic).dateTo),
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'ANGGARAN OPERASIONAL',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        formatCurrency(trip.operational),
                        style: const TextStyle(
                          fontSize: 16,
                          color: Color(0xFF0E7C7B),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: onDetail,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0E7C7B),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    elevation: 4,
                  ),
                  child: const Text(
                    'Detail',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Trip detail modal removed — navigation handled by `/trip` route
