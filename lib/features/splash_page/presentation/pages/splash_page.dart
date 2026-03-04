import 'package:flutter/material.dart';
import 'dart:math';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
// Navigation handled by GoRouter; don't import pages directly here.
import '../cubit/splash_page_cubit.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  bool _showSheet = false;
  bool _headerAtTop = false;

  static const Color brandBlack = Colors.black;
  static const Color brandTeal = Color(0xFF0E7C7B);

  @override
  void initState() {
    super.initState();
    // Start the splash flow in the cubit
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final cubit = context.read<SplashPageCubit>();
      cubit.start();
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    // sheetHeight must match the maxHeight used in _welcomeSheet
    final sheetHeight = size.height * 0.48;
    // approximate header block height (Hello + subtitle)
    const headerBlockHeight = 140.0;
    // compute top padding so header sits just above the sheet with small gap
    final sheetTop = size.height - sheetHeight;
    final desiredTopPadding = (sheetTop - headerBlockHeight - 12)
        .clamp(24.0, max(24.0, size.height))
        .toDouble();

    return BlocListener<SplashPageCubit, SplashPageState>(
      listener: (context, state) {
        // Reveal the welcome sheet for both authenticated and unauthenticated states;
        // do not auto-navigate so the user must explicitly choose to proceed.
        if (state is SplashAuthenticated || state is SplashUnauthenticated) {
          if (mounted) setState(() => _showSheet = true);
          Future.delayed(const Duration(milliseconds: 250), () {
            if (mounted) setState(() => _headerAtTop = true);
          });
        }
      },
      child: Scaffold(
        backgroundColor: brandTeal,
        body: Stack(
          children: [
            // Header like the reference: text left, illustration right
            AnimatedAlign(
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOutCubic,
              alignment: _headerAtTop ? Alignment.topLeft : Alignment.center,
              child: AnimatedPadding(
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeOutCubic,
                padding: EdgeInsets.only(
                  top: _headerAtTop ? desiredTopPadding : 0,
                  left: 24,
                  right: 24,
                ),
                child: SizedBox(
                  width: _headerAtTop ? size.width - 48 : null,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Text(
                              'Hello!',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 44,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 3),
                            Text(
                              'Welcome to my app\nPlease login to continue.',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 18,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Flexible(
                        flex: 0,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: size.width * 0.45,
                            maxHeight:
                                size.height * (_headerAtTop ? 0.14 : 0.25),
                          ),
                          child: SvgPicture.asset(
                            'assets/svg/computer.svg',
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Bottom sheet with actions
            AnimatedPositioned(
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeOutCubic,
              left: 0,
              right: 0,
              bottom: _showSheet ? 0 : -size.height * 0.6,
              child: _welcomeSheet(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _welcomeSheet(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Container(
      constraints: BoxConstraints(maxHeight: size.height * 0.48),
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
      decoration: const BoxDecoration(
        color: Color(0xFFF6F8F7),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(32),
          topRight: Radius.circular(32),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Welcome',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: brandTeal,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Buat Laporan Perjalanan Dinas Anda Dengan Mudah.',
            style: TextStyle(fontSize: 18, color: Colors.black87),
          ),
          const Spacer(),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0E7C7B),
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                    elevation: 6,
                    shadowColor: Colors.black54,
                  ),
                  onPressed: () {
                    // push login page with GoRouter using slide transition
                    // include an extra flag so router redirect can allow navigation from splash
                    context.push('/login', extra: {'fromSplash': true});
                  },
                  child: const Text('Sign In'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      // ignore: deprecated_member_use
                      color: brandBlack.withOpacity(0.87),
                      width: 1.4,
                    ),
                    foregroundColor: brandBlack,
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                    backgroundColor: Colors.white,
                  ),
                  onPressed: () =>
                      context.push('/signup', extra: {'fromSplash': true}),
                  child: const Text('Sign Up'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Navigation now uses GoRouter + slideFadePage helper.
}
