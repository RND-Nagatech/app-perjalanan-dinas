import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import 'core/router/app_router.dart';

import 'features/Auth/injection/injection.dart' as auth_inject;
import 'features/trip_detail_page/injection/injection.dart'
    as trip_detail_inject;
import 'features/perjalanan/injection/injection.dart' as perjalanan_inject;
import 'features/history/injection/injection.dart' as history_inject;
import 'features/add_pengeluaran/injection/injection.dart'
    as add_pengeluaran_inject;
import 'features/app_update/injection/injection.dart' as app_update_inject;
import 'core/injection/injection.dart' as core_inject;

import 'features/Auth/presentation/bloc/auth_bloc.dart';
import 'features/Auth/presentation/bloc/auth_event.dart';
import 'features/splash_page/presentation/cubit/splash_page_cubit.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize core external dependencies (Dio, SharedPreferences, etc.)
  await core_inject.initCoreModule();

  /// ===============================
  /// INIT FEATURE MODULES (ONLY ONCE)
  /// ===============================
  trip_detail_inject.initTripDetailModule();

  // Perjalanan feature (Bloc factory registration)
  perjalanan_inject.initPerjalananModule();

  // Add Pengeluaran
  add_pengeluaran_inject.initAddPengeluaranModule();

  // History feature
  history_inject.initHistoryModule();

  // App update feature
  app_update_inject.initAppUpdateModule();

  auth_inject.initAuthModule();

  /// ===============================
  /// REGISTER GLOBAL CUBITS
  /// ===============================
  if (!GetIt.I.isRegistered<SplashPageCubit>()) {
    GetIt.I.registerFactory(
      () => SplashPageCubit(
        getCurrentUser: GetIt.I(),
        authBloc: GetIt.I<AuthBloc>(),
      ),
    );
  }

  /// ===============================
  /// TRIGGER INITIAL AUTH CHECK
  /// ===============================
  try {
    GetIt.I<AuthBloc>().add(AppStarted());
  } catch (_) {}

  final router = createRouter();

  runApp(MyApp(router: router));
}

class MyApp extends StatelessWidget {
  final GoRouter router;
  const MyApp({super.key, required this.router});

  static const double _webPortraitWidth = 430;
  static const double _webDesktopBreakpoint = 700;

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Perjalanan dinas',
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.teal),
      builder: (context, child) {
        if (!kIsWeb || child == null) return child ?? const SizedBox.shrink();

        return LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < _webDesktopBreakpoint) {
              return child;
            }

            return ColoredBox(
              color: const Color(0xFFD3D8E1),
              child: Center(
                child: SizedBox(
                  width: _webPortraitWidth,
                  height: constraints.maxHeight,
                  child: DecoratedBox(
                    decoration: const BoxDecoration(color: Colors.white),
                    child: child,
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
