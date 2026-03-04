import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// A reusable bottom navigation bar with a centered FAB.
///
/// By default routes are:
/// - home: `/home`
/// - perjalanan: `/perjalanan`
/// - pengeluaran: `/pengeluaran`
/// - riwayat: `/riwayat`
/// - create (FAB): `/create`
class BottomNavigationWidget extends StatelessWidget {
  final String homeRoute;
  final String perjalananRoute;
  final String pengeluaranRoute;
  final String riwayatRoute;
  final String createRoute;
  final int currentIndex;
  final VoidCallback? onHomeTap;
  final VoidCallback? onPerjalananTap;
  final VoidCallback? onPengeluaranTap;
  final VoidCallback? onRiwayatTap;
  final VoidCallback? onCreateTap;

  const BottomNavigationWidget({
    super.key,
    this.homeRoute = '/home',
    this.perjalananRoute = '/perjalanan',
    this.pengeluaranRoute = '/pengeluaran',
    this.riwayatRoute = '/riwayat',
    this.createRoute = '/create',
    this.currentIndex = 0,
    this.onHomeTap,
    this.onPerjalananTap,
    this.onPengeluaranTap,
    this.onRiwayatTap,
    this.onCreateTap,
  });

  void _go(BuildContext context, String route) {
    if (route.isEmpty) return;
    try {
      context.go(route);
    } catch (_) {
      // fallback: try Navigator if GoRouter not configured
      try {
        Navigator.of(context).pushNamed(route);
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    // use app green color
    final primary = const Color(0xFF0E7C7B);
    final inactive = Colors.grey[600];

    Widget item(
      IconData icon,
      String label,
      String route,
      int idx, {
      VoidCallback? onTap,
    }) {
      final active = idx == currentIndex;
      return Expanded(
        child: InkWell(
          onTap: onTap ?? () => _go(context, route),
          borderRadius: BorderRadius.circular(20),
          splashColor: active
              ? const Color.fromRGBO(14, 124, 123, 0.16)
              : Colors.transparent,
          highlightColor: Colors.transparent,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: active ? primary : inactive),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: active ? primary : inactive,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Stack(
          alignment: Alignment.topCenter,
          children: [
            // background bar: keep the rounded Material visible but remove
            // the outer rectangular white fill so only the rounded shape shows.
            Container(
              height: 64,
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(32),
                // keep a subtle shadow so the bar still looks elevated
                boxShadow: [
                  BoxShadow(
                    color: const Color.fromRGBO(0, 0, 0, 0.06),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              // Clip and render the actual white surface as a rounded Material
              // so the surrounding area remains transparent.
              child: ClipRRect(
                borderRadius: BorderRadius.circular(32),
                child: Material(
                  color: Colors.white,
                  child: Row(
                    children: [
                      item(
                        Icons.home,
                        'Beranda',
                        homeRoute,
                        0,
                        onTap: onHomeTap,
                      ),
                      item(
                        Icons.explore,
                        'Perjalanan',
                        perjalananRoute,
                        1,
                        onTap: onPerjalananTap,
                      ),
                      // reduced gap to make icon groups closer
                      const SizedBox(width: 20),
                      item(
                        Icons.payment,
                        'Pengeluaran',
                        pengeluaranRoute,
                        2,
                        onTap: onPengeluaranTap,
                      ),
                      item(
                        Icons.history,
                        'Riwayat',
                        riwayatRoute,
                        3,
                        onTap: onRiwayatTap,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // FAB removed per request
          ],
        ),
      ),
    );
  }
}
