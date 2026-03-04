import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../presentation/bloc/home_page_bloc.dart';
import '../../../Auth/presentation/bloc/auth_event.dart';
import '../../../Auth/presentation/bloc/auth_bloc.dart';
import '../../../Auth/presentation/bloc/auth_state.dart';
// trip detail navigation now uses GoRouter via '/trip' route; no direct import required.
import 'package:go_router/go_router.dart';
import '../widgets/bottom_navigation.dart';
import '../../../perjalanan/presentation/pages/perjalanan_page.dart';
import '../../../perjalanan/injection/injection.dart' as perjalanan_inject;
import '../../../add_pengeluaran/injection/injection.dart'
    as add_pengeluaran_inject;
import '../../../add_pengeluaran/presentation/pages/add_pengeluaran_page.dart';
import '../../../add_pengeluaran/presentation/bloc/add_pengeluaran_bloc.dart'
    as add_pengeluaran_bloc;
// trip_detail injection initialized at app startup in main.dart
import '../../../trip_detail_page/domain/entities/expense_entity.dart';
import '../../../perjalanan/presentation/bloc/perjalanan_bloc.dart';
import 'package:trips_apps/core/domain/entities/trip_entity.dart';
import 'package:trips_apps/features/app_update/domain/entities/app_update_info.dart';
import 'package:trips_apps/features/app_update/presentation/cubit/app_update_cubit.dart';
import 'package:trips_apps/features/app_update/presentation/cubit/app_update_state.dart';
import 'package:trips_apps/features/history/presentation/pages/history_page.dart';

class FeatureHomePage extends StatelessWidget {
  final int initialIndex;
  final HomePageBloc homeBloc;
  final AuthBloc authBloc;
  final AppUpdateCubit appUpdateCubit;
  final PerjalananBloc Function() createPerjalananBloc;
  final add_pengeluaran_bloc.AddPengeluaranBloc Function()
  createAddPengeluaranBloc;

  const FeatureHomePage({
    super.key,
    this.initialIndex = 0,
    required this.homeBloc,
    required this.authBloc,
    required this.appUpdateCubit,
    required this.createPerjalananBloc,
    required this.createAddPengeluaranBloc,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider<HomePageBloc>(
      create: (_) => homeBloc,
      child: _FeatureHomeView(
        initialIndex: initialIndex,
        authBloc: authBloc,
        appUpdateCubit: appUpdateCubit,
        createPerjalananBloc: createPerjalananBloc,
        createAddPengeluaranBloc: createAddPengeluaranBloc,
      ),
    );
  }

  static String _formatCurrency(int value) {
    final s = value.toString();
    final reg = RegExp(r'\B(?=(\d{3})+(?!\d))');
    return s.replaceAllMapped(reg, (m) => '.');
  }
}

class _FeatureHomeView extends StatefulWidget {
  final int initialIndex;
  final AuthBloc authBloc;
  final AppUpdateCubit appUpdateCubit;
  final PerjalananBloc Function() createPerjalananBloc;
  final add_pengeluaran_bloc.AddPengeluaranBloc Function()
  createAddPengeluaranBloc;

  const _FeatureHomeView({
    this.initialIndex = 0,
    required this.authBloc,
    required this.appUpdateCubit,
    required this.createPerjalananBloc,
    required this.createAddPengeluaranBloc,
  });

  @override
  State<_FeatureHomeView> createState() => _FeatureHomeViewState();
}

class _FeatureHomeViewState extends State<_FeatureHomeView> {
  static const String _activeTripsEmptyAsset = 'assets/png/empty.png';
  static const String _latestExpensesEmptyAsset = 'assets/png/empty.png';

  late int _selectedIndex;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  String? _animatingTambahTripId;
  bool _animatePengeluaranFromBottom = false;
  late final add_pengeluaran_bloc.AddPengeluaranBloc _addPengeluaranBloc;
  late final AppUpdateCubit _appUpdateCubit;
  String? _lastPengeluaranPreferredTripId;
  bool _hasLoadedPengeluaran = false;
  bool _hasShownUpdatePrompt = false;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
    _addPengeluaranBloc = widget.createAddPengeluaranBloc();
    _appUpdateCubit = widget.appUpdateCubit;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _appUpdateCubit.check();
    });
  }

  @override
  void dispose() {
    _addPengeluaranBloc.close();
    super.dispose();
  }

  void _ensurePengeluaranLoaded(String? preferredTripId) {
    if (!_hasLoadedPengeluaran ||
        _lastPengeluaranPreferredTripId != preferredTripId) {
      _addPengeluaranBloc.add(
        add_pengeluaran_bloc.LoadActiveTripsEvent(
          preferredTripId: preferredTripId,
        ),
      );
      _hasLoadedPengeluaran = true;
      _lastPengeluaranPreferredTripId = preferredTripId;
    }
  }

  int _getTotalInject(TripEntity? doc, int fallback) {
    try {
      if (doc == null) return fallback;
      return doc.totalInject ?? doc.operational;
    } catch (_) {
      return fallback;
    }
  }

  int _getTotalTransaksi(TripEntity? doc, int fallback) {
    try {
      if (doc == null) return fallback;
      return doc.totalTransaksi ?? fallback;
    } catch (_) {
      return fallback;
    }
  }

  int _getSisaDana(TripEntity? doc, int fallback) {
    try {
      if (doc == null) return fallback;
      return doc.sisaDana ?? fallback;
    } catch (_) {
      return fallback;
    }
  }

  Future<void> _onTambahPengeluaranPressed(TripEntity trip) async {
    if (_animatingTambahTripId != null) return;
    setState(() => _animatingTambahTripId = trip.id);
    await Future<void>.delayed(const Duration(milliseconds: 140));
    if (!mounted) return;
    context.read<HomePageBloc>().add(SelectTripEvent(trip));
    setState(() {
      _animatingTambahTripId = null;
      _animatePengeluaranFromBottom = true;
    });
    _selectPage(2);
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AppUpdateCubit, AppUpdateState>(
      bloc: _appUpdateCubit,
      listenWhen: (previous, current) =>
          previous.updateInfo != current.updateInfo &&
          current.updateInfo != null,
      listener: (context, state) async {
        if (_hasShownUpdatePrompt) return;
        final info = state.updateInfo;
        if (info == null) return;
        _hasShownUpdatePrompt = true;
        await _showAppUpdateSheet(info, state.forceUpdate);
      },
      child: BlocBuilder<HomePageBloc, HomePageState>(
        builder: (context, state) {
          final trips = state is HomeLoaded ? state.trips : <TripEntity>[];
          final todayTrips = state is HomeLoaded
              ? state.todayTrips
              : <TripEntity>[];
          final subscribed = state is HomeLoaded
              ? state.subscribedToSpd
              : false;
          final activeTrips = state is HomeLoaded
              ? state.activeTrips
              : <TripEntity>[];
          final totalOperational = state is HomeLoaded
              ? state.totalOperational
              : 0;
          final totalTransaksiVal = state is HomeLoaded
              ? state.totalTransaksi ?? 0
              : 0;
          final sisaDanaVal = state is HomeLoaded
              ? state.sisaDana ?? totalOperational
              : totalOperational;
          final TripEntity? selectedTrip = state is HomeLoaded
              ? state.selectedTrip
              : null;
          final latestExpenses = state is HomeLoaded
              ? state.latestExpenses
              : <ExpenseEntity>[];

          final authState = widget.authBloc.state;
          final String userName = authState is Authenticated
              ? authState.user.name
              : '';

          dynamic displayTrip = selectedTrip;
          try {
            if (displayTrip == null && activeTrips.isNotEmpty) {
              displayTrip = activeTrips.first;
            }
          } catch (_) {}

          return PopScope(
            canPop: false,
            onPopInvokedWithResult: (didPop, result) {
              if (didPop) return;
              if (_selectedIndex != 0) {
                setState(() => _selectedIndex = 0);
                return;
              }
              try {
                SystemNavigator.pop();
              } catch (_) {}
            },
            child: Scaffold(
              key: _scaffoldKey,
              extendBody: true,
              backgroundColor: const Color(0xFFFFFFFF),
              body: SafeArea(
                top: true,
                bottom: false,
                child: _getSelectedPage(
                  context,
                  _selectedIndex,
                  trips,
                  todayTrips,
                  subscribed,
                  totalOperational,
                  totalTransaksiVal,
                  sisaDanaVal,
                  activeTrips,
                  displayTrip is TripEntity ? displayTrip : null,
                  latestExpenses,
                  userName,
                ),
              ),
              bottomNavigationBar: BottomNavigationWidget(
                currentIndex: _selectedIndex,
                onHomeTap: () => _selectPage(0),
                onPerjalananTap: () => _selectPage(1),
                onPengeluaranTap: () {
                  // Ensure local UI shows the pengeluaran tab immediately,
                  // then navigate to the pengeluaran route so deep-linking
                  // / state restoration use the route when appropriate.
                  _selectPage(2);
                  try {
                    context.go('/pengeluaran');
                  } catch (_) {}
                },
                onRiwayatTap: () => _selectPage(3),
              ),
            ),
          );
        },
      ),
    );
  }

  void _selectPage(int idx) {
    setState(() => _selectedIndex = idx);
  }

  Future<void> _showAppUpdateSheet(AppUpdateInfo info, bool forceUpdate) async {
    await showModalBottomSheet<void>(
      context: context,
      isDismissible: !forceUpdate,
      enableDrag: !forceUpdate,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.asset(
                      'assets/png/empty.png',
                      width: 130,
                      height: 130,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  info.title,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  info.message,
                  style: const TextStyle(color: Colors.black87, fontSize: 16),
                ),
                if ((info.changelog ?? '').trim().isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    info.changelog!,
                    style: const TextStyle(color: Colors.black54),
                  ),
                ],
                const SizedBox(height: 18),
                Row(
                  children: [
                    if (!forceUpdate)
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(sheetContext).pop(),
                          child: const Text('Nanti'),
                        ),
                      ),
                    if (!forceUpdate) const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          final raw = info.storeUrl?.trim() ?? '';
                          if (raw.isEmpty) {
                            if (!sheetContext.mounted) return;
                            ScaffoldMessenger.of(sheetContext).showSnackBar(
                              const SnackBar(
                                content: Text('Link update belum tersedia'),
                              ),
                            );
                            return;
                          }

                          final uri = Uri.tryParse(raw);
                          if (uri == null) return;
                          await launchUrl(
                            uri,
                            mode: LaunchMode.externalApplication,
                          );
                        },
                        child: const Text('Perbarui'),
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
  }

  Widget _buildEmptyStateCard({
    required String message,
    required IconData icon,
    String? assetPath,
  }) {
    final hasAsset = assetPath != null && assetPath.trim().isNotEmpty;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEAECEF)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (hasAsset)
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.asset(
                assetPath,
                width: 200,
                height: 200,
                fit: BoxFit.cover,
              ),
            )
          else
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFE8F7F6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: const Color(0xFF0E7C7B), size: 24),
            ),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.black54),
          ),
        ],
      ),
    );
  }

  Widget _getSelectedPage(
    BuildContext context,
    int selectedIndex,
    List<TripEntity> trips,
    List<TripEntity> todayTrips,
    bool subscribed,
    int totalOperational,
    int totalTransaksi,
    int sisaDana,
    List<TripEntity> activeTrips,
    TripEntity? selectedTrip,
    List<ExpenseEntity> latestExpenses,
    String userName,
  ) {
    switch (selectedIndex) {
      case 0:
        return _buildHomePage(
          context,
          trips,
          todayTrips,
          subscribed,
          totalOperational,
          totalTransaksi,
          sisaDana,
          activeTrips,
          selectedTrip,
          latestExpenses,
          userName,
        );
      case 1:
        // Provide PerjalananBloc when embedding PerjalananContent in Home
        perjalanan_inject.initPerjalananModule();
        return BlocProvider<PerjalananBloc>(
          create: (_) => widget.createPerjalananBloc()..add(LoadPerjalanan()),
          child: const PerjalananContent(),
        );
      case 2:
        // Embed the Add Pengeluaran content inside Home so BottomNavigation
        // remains persistent. Ensure feature is initialized first.
        try {
          add_pengeluaran_inject.initAddPengeluaranModule();
        } catch (_) {}
        _ensurePengeluaranLoaded(selectedTrip?.id);
        final pengeluaranContent =
            BlocProvider<add_pengeluaran_bloc.AddPengeluaranBloc>.value(
              value: _addPengeluaranBloc,
              child: const AddPengeluaranContent(),
            );
        if (!_animatePengeluaranFromBottom) return pengeluaranContent;

        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 1, end: 0),
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeOutCubic,
          onEnd: () {
            if (!mounted) return;
            if (_animatePengeluaranFromBottom) {
              setState(() => _animatePengeluaranFromBottom = false);
            }
          },
          child: pengeluaranContent,
          builder: (context, value, child) {
            final h = MediaQuery.of(context).size.height;
            return Transform.translate(
              offset: Offset(0, value * h * 0.55),
              child: Opacity(opacity: 1 - (value * 0.15), child: child),
            );
          },
        );
      case 3:
        return const HistoryPage();
      default:
        return _buildHomePage(
          context,
          trips,
          todayTrips,
          subscribed,
          totalOperational,
          totalTransaksi,
          sisaDana,
          activeTrips,
          selectedTrip,
          latestExpenses,
          userName,
        );
    }
  }

  Widget _buildHomePage(
    BuildContext context,
    List<TripEntity> trips,
    List<TripEntity> todayTrips,
    bool subscribed,
    int totalOperational,
    int totalTransaksi,
    int sisaDana,
    List<TripEntity> activeTrips,
    TripEntity? selectedTrip,
    List<ExpenseEntity> latestExpenses,
    String userName,
  ) {
    final displayTotalOperational = selectedTrip != null
        ? _getTotalInject(selectedTrip, totalOperational)
        : totalOperational;
    final displayTotalTransaksi = selectedTrip != null
        ? _getTotalTransaksi(selectedTrip, totalTransaksi)
        : totalTransaksi;
    final displaySisaDana = selectedTrip != null
        ? _getSisaDana(selectedTrip, sisaDana)
        : sisaDana;

    return RefreshIndicator(
      color: const Color(0xFF0E7C7B),
      onRefresh: () async {
        await context.read<HomePageBloc>().refreshTripsFromUi();
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF0E7C7B), Color(0xFF0AA7A5)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(28),
                  bottomRight: Radius.circular(28),
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Selamat Datang,',
                                style: TextStyle(color: Colors.white70),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                "Halo, ${userName.isNotEmpty ? userName : 'User'}! 👋",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              BlocBuilder<AppUpdateCubit, AppUpdateState>(
                                bloc: _appUpdateCubit,
                                builder: (context, updateState) {
                                  return Text(
                                    'Versi ${updateState.appVersion}',
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () => context.read<HomePageBloc>().add(
                                ToggleSpdRequested(),
                              ),
                              child: SizedBox(
                                width: 40,
                                height: 40,
                                child: Center(
                                  child: Icon(
                                    subscribed
                                        ? Icons.notifications_active
                                        : Icons.notifications,
                                    color: Colors.white,
                                    size: 22,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () async {
                                try {
                                  widget.authBloc.add(LogoutRequested());
                                } catch (_) {}
                                if (!mounted) return;
                                context.go('/login');
                              },
                              child: SizedBox(
                                width: 40,
                                height: 40,
                                child: const Center(
                                  child: Icon(
                                    Icons.logout,
                                    color: Colors.white,
                                    size: 22,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Dana Operasional',
                                style: TextStyle(color: Colors.black54),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE8F7F6),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Text(
                                  'AKTIF',
                                  style: TextStyle(
                                    color: Color(0xFF0E7C7B),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'TOTAL SALDO',
                            style: TextStyle(
                              color: Colors.black45,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Rp ${FeatureHomePage._formatCurrency(displayTotalOperational)}',
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Divider(),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Terpakai',
                                      style: TextStyle(color: Colors.black54),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'Rp ${FeatureHomePage._formatCurrency(displayTotalTransaksi)}',
                                      style: const TextStyle(
                                        color: Colors.red,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    const Text(
                                      'Sisa',
                                      style: TextStyle(color: Colors.black54),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'Rp ${FeatureHomePage._formatCurrency(displaySisaDana)}',
                                      style: const TextStyle(
                                        color: Color(0xFF0E7C7B),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // content
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Perjalanan Aktif',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  if (activeTrips.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: _buildEmptyStateCard(
                        message: 'Tidak ada perjalanan aktif',
                        icon: Icons.card_travel,
                        assetPath: _activeTripsEmptyAsset,
                      ),
                    )
                  else
                    Column(
                      children: activeTrips.map((d) {
                        final TripEntity doc = d;
                        final kode = doc.name;
                        final user = doc.userName ?? '-';
                        final dest = doc.destination;
                        final note = doc.note ?? '-';
                        final DateTime? df = doc.dateFrom;
                        final dateFrom = df == null
                            ? '-'
                            : df.toLocal().toString().split(' ').first;
                        final DateTime? dt = doc.dateTo;
                        final dateTo = dt == null
                            ? '-'
                            : dt.toLocal().toString().split(' ').first;
                        final status = doc.status ?? '-';

                        final bool isSelected =
                            selectedTrip != null && doc.id == selectedTrip.id;
                        final isAnimatingTambah =
                            _animatingTambahTripId == doc.id;

                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFFEAF9F8)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                // ignore: deprecated_member_use
                                color: Colors.black.withOpacity(
                                  isSelected ? 0.12 : 0.04,
                                ),
                                blurRadius: isSelected ? 10 : 2,
                                offset: Offset(0, isSelected ? 6 : 1),
                              ),
                            ],
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFF0E7C7B)
                                  : const Color(0xFFEEEEEE),
                              width: 1.0,
                            ),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () => context.read<HomePageBloc>().add(
                                SelectTripEvent(doc),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFE8F7F6),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: const Icon(
                                                Icons.flight_takeoff,
                                                color: Color(0xFF0E7C7B),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  kode,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  '$user • $dateFrom - $dateTo',
                                                  style: const TextStyle(
                                                    color: Colors.black54,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFE8F7F6),
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                          ),
                                          child: Text(
                                            status,
                                            style: const TextStyle(
                                              color: Color(0xFF0E7C7B),
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    const Text(
                                      'Tujuan',
                                      style: TextStyle(color: Colors.black54),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      dest,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    if (note.isNotEmpty && note != '-') ...[
                                      const SizedBox(height: 8),
                                      const Text(
                                        'Catatan',
                                        style: TextStyle(color: Colors.black54),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(note),
                                    ],
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        AnimatedScale(
                                          duration: const Duration(
                                            milliseconds: 140,
                                          ),
                                          curve: Curves.easeOut,
                                          scale: isAnimatingTambah ? 0.94 : 1,
                                          child: AnimatedOpacity(
                                            duration: const Duration(
                                              milliseconds: 140,
                                            ),
                                            opacity: isAnimatingTambah
                                                ? 0.82
                                                : 1,
                                            child: ElevatedButton.icon(
                                              icon: const Icon(
                                                Icons.add,
                                                size: 18,
                                                color: Colors.white,
                                              ),
                                              label: const Text(
                                                'Tambah Pengeluaran',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.white,
                                                ),
                                              ),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: const Color(
                                                  0xFF0E7C7B,
                                                ),
                                              ),
                                              onPressed: () =>
                                                  _onTambahPengeluaranPressed(
                                                    doc,
                                                  ),
                                            ),
                                          ),
                                        ),
                                        OutlinedButton(
                                          child: const Text(
                                            'Detail',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Color(0xFF0E7C7B),
                                            ),
                                          ),
                                          onPressed: () =>
                                              context.push('/trip', extra: doc),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                  const SizedBox(height: 20),
                  const Text(
                    'Pengeluaran Terbaru',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  // Show latest expense items across active trips (provided by bloc)
                  Builder(
                    builder: (context) {
                      final latest = latestExpenses;
                      if (latest.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: _buildEmptyStateCard(
                            message: 'Tidak ada pengeluaran terbaru hari ini',
                            icon: Icons.receipt_long,
                            assetPath: _latestExpensesEmptyAsset,
                          ),
                        );
                      }
                      return Column(
                        children: latest.take(3).map((it) {
                          final keterangan = it.keterangan ?? 'Pengeluaran';
                          final tanggal = it.tanggal ?? '';
                          final nominal = (it.nominal ?? 0).toInt();
                          return Card(
                            child: ListTile(
                              leading: Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF2F2F2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.receipt_long,
                                  color: Color(0xFF0E7C7B),
                                ),
                              ),
                              title: Text(keterangan),
                              subtitle: Text(tanggal),
                              trailing: Text(
                                '-Rp ${FeatureHomePage._formatCurrency(nominal)}',
                                style: const TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              // intentionally non-clickable (preview only)
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
