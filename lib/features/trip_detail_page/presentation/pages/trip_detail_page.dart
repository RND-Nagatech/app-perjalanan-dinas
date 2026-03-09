import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:perjalanan_dinas/core/services/custom_notice_overlay.dart';
import 'trip_detail_sheet.dart';

// Router should not create domain entities; this page accepts a trip id
// and optional preview data passed from the caller.
import '../bloc/trip_detail_page_bloc.dart';
import '../bloc/trip_detail_page_state.dart';
import '../bloc/trip_detail_page_event.dart';

class TripDetailPage extends StatefulWidget {
  final String tripId;

  const TripDetailPage({super.key, required this.tripId});

  @override
  State<TripDetailPage> createState() => _TripDetailPageState();
}

class _TripDetailPageState extends State<TripDetailPage>
    with SingleTickerProviderStateMixin {
  OverlayEntry? _activeNoticeEntry;

  String _formatDateRange(DateTime? from, DateTime? to) {
    if (from == null) return '-';
    final f = DateFormat.yMMMd().format(from);
    if (to == null || to == from) return f;
    return '$f - ${DateFormat.yMMMd().format(to)}';
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: const Offset(0, 0),
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TripDetailPageBloc>().add(
        WatchExpensesStarted(widget.tripId),
      );
    });
  }

  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;

  @override
  void dispose() {
    _activeNoticeEntry?.remove();
    _activeNoticeEntry = null;
    _controller.dispose();
    super.dispose();
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
    final nf = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Full-screen gradient background so area below header stays green
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF0E7C7B), Color(0xFF0AA7A5)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),

          // Gradient header area (keeps same gradient but limited height)
          Container(
            height: 320,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0E7C7B), Color(0xFF0AA7A5)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            padding: const EdgeInsets.only(
              top: 24,
              left: 16,
              right: 16,
              bottom: 16,
            ),
            child: SafeArea(
              bottom: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.of(context).maybePop(),
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Detail Perjalanan',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'TUJUAN PERJALANAN',
                    style: TextStyle(
                      color: Color(0xFFBEECEB),
                      fontSize: 12,
                      letterSpacing: 0.6,
                    ),
                  ),
                  const SizedBox(height: 6),
                  // Show from bloc-fetched preview when available
                  BlocBuilder<TripDetailPageBloc, TripDetailState>(
                    builder: (context, state) {
                      String tujuan = '-';
                      String dateRange = '-';
                      double sisa = 0;
                      if (state is TripDetailLoadSuccess &&
                          state.preview != null) {
                        tujuan = state.preview!.destination;
                        dateRange = _formatDateRange(
                          state.preview!.dateFrom,
                          state.preview!.dateTo,
                        );
                        sisa = (state.preview!.sisaDana ?? 0).toDouble();
                      }
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tujuan,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(
                                Icons.calendar_today,
                                color: Colors.white70,
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                dateRange,
                                style: const TextStyle(color: Colors.white70),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              // ignore: deprecated_member_use
                              color: Colors.white.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'SISA UANG OPERASIONAL',
                                        style: TextStyle(
                                          color: Colors.white70,
                                          fontSize: 12,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        nf.format(sisa),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 20,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    // ignore: deprecated_member_use
                                    color: Colors.white.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(
                                    Icons.account_balance_wallet,
                                    color: Colors.white70,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          // Show loading / error feedback while fetching preview and items
          BlocBuilder<TripDetailPageBloc, TripDetailState>(
            builder: (context, state) {
              if (state is TripDetailLoadInProgress ||
                  state is TripDetailInitial) {
                return const Center(child: CircularProgressIndicator());
              } else if (state is TripDetailLoadFailure) {
                return Center(child: Text('Error: ${state.message}'));
              }
              return const SizedBox.shrink();
            },
          ),

          // Persistent bottom sheet area: render TripDetailSheet as part of layout
          BlocListener<TripDetailPageBloc, TripDetailState>(
            listener: (context, state) {
              if (state is TripDetailLoadFailure) {
                _showCustomNotice('Error: ${state.message}', isError: true);
              } else if (state is TripDetailActionSuccess) {
                _showCustomNotice(state.message);
              }
            },
            child: Align(
              alignment: Alignment.bottomCenter,
              child: BlocBuilder<TripDetailPageBloc, TripDetailState>(
                builder: (context, state) {
                  final screenHeight = MediaQuery.of(context).size.height;
                  if (state is TripDetailLoadSuccess) {
                    // ensure animation plays when data arrives
                    if (_controller.status != AnimationStatus.forward &&
                        _controller.status != AnimationStatus.completed) {
                      _controller.forward();
                    }
                    final preview = state.preview;
                    final sisa = (preview?.sisaDana ?? 0).toDouble();
                    final totalInject = (preview?.totalInject ?? 0).toDouble();
                    final totalTransaksi = (preview?.totalTransaksi ?? 0)
                        .toDouble();

                    return SlideTransition(
                      position: _offsetAnimation,
                      child: SizedBox(
                        height: screenHeight * 0.67,
                        child: ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(24),
                          ),
                          child: TripDetailSheet(
                            tripId: widget.tripId,
                            status: preview?.status,
                            sisaDana: sisa,
                            totalInject: totalInject,
                            totalTransaksi: totalTransaksi,
                            items: state.items,
                          ),
                        ),
                      ),
                    );
                  }

                  // if not success, hide sheet (reverse animation)
                  if (_controller.status == AnimationStatus.completed ||
                      _controller.status == AnimationStatus.forward) {
                    _controller.reverse();
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
