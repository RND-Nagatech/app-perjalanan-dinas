import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

import '../../../features/Auth/presentation/bloc/auth_bloc.dart';
import '../../../features/Auth/presentation/bloc/auth_state.dart';
import '../../../features/Auth/presentation/pages/login_page.dart';
import '../../../features/Auth/presentation/pages/signup.dart';

import '../../../features/splash_page/presentation/pages/splash_page.dart';
import '../../../features/splash_page/presentation/cubit/splash_page_cubit.dart';

import '../../../features/home_page/presentation/pages/home_page.dart'
    show FeatureHomePage;
import '../../../features/app_update/presentation/cubit/app_update_cubit.dart';

import '../../../features/trip_detail_page/presentation/pages/trip_detail_page.dart';
import '../../../features/trip_detail_page/presentation/bloc/trip_detail_page_bloc.dart';
import '../../../features/trip_detail_page/presentation/bloc/trip_detail_page_event.dart';
import '../../../features/trip_detail_page/injection/injection.dart'
    as trip_detail_inject;
import '../../../features/perjalanan/injection/injection.dart'
    as perjalanan_inject;
import '../../../features/add_pengeluaran/injection/injection.dart'
    as add_pengeluaran_inject;
import '../../../features/add_pengeluaran/presentation/pages/add_pengeluaran_page.dart';
import '../../../features/add_pengeluaran/presentation/bloc/add_pengeluaran_bloc.dart'
    as add_pengeluaran_bloc;
import '../../../features/home_page/presentation/bloc/home_page_bloc.dart';
import '../../../features/perjalanan/presentation/bloc/perjalanan_bloc.dart';
import '../../../features/perjalanan/presentation/pages/perjalanan_page.dart';

final sl = GetIt.instance;

/// ===========================================================
/// Slide + Fade Transition
/// ===========================================================
CustomTransitionPage<T> slideFadePage<T>({required Widget child}) {
  return CustomTransitionPage<T>(
    child: child,
    transitionDuration: const Duration(milliseconds: 300),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final offsetTween = Tween<Offset>(
        begin: const Offset(1, 0),
        end: Offset.zero,
      );

      return SlideTransition(
        position: animation.drive(offsetTween),
        child: FadeTransition(opacity: animation, child: child),
      );
    },
  );
}

/// ===========================================================
/// Refresh helper for GoRouter
/// ===========================================================
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

/// ===========================================================
/// CREATE ROUTER
/// ===========================================================
GoRouter createRouter() {
  final authBloc = sl<AuthBloc>();

  return GoRouter(
    initialLocation: '/login',
    refreshListenable: GoRouterRefreshStream(authBloc.stream),

    /// ================= ROUTES =================
    routes: [
      /// SPLASH
      GoRoute(
        path: '/',
        pageBuilder: (context, state) => MaterialPage(
          child: BlocProvider(
            create: (_) => sl<SplashPageCubit>(),
            child: const SplashPage(),
          ),
        ),
      ),

      /// LOGIN
      GoRoute(
        path: '/login',
        pageBuilder: (context, state) =>
            slideFadePage(child: LoginPage(authBloc: authBloc)),
      ),

      /// SIGNUP
      GoRoute(
        path: '/signup',
        pageBuilder: (context, state) =>
            slideFadePage(child: SignupPage(authBloc: authBloc)),
      ),

      /// HOME
      GoRoute(
        path: '/home',
        pageBuilder: (context, state) => MaterialPage(
          child: FeatureHomePage(
            homeBloc: sl<HomePageBloc>(),
            authBloc: authBloc,
            appUpdateCubit: sl<AppUpdateCubit>(),
            createPerjalananBloc: () => sl<PerjalananBloc>(),
            createAddPengeluaranBloc: () =>
                sl<add_pengeluaran_bloc.AddPengeluaranBloc>(),
          ),
        ),
      ),

      /// TRIP DETAIL
      GoRoute(
        path: '/trip',
        pageBuilder: (context, state) {
          // ensure trip-detail feature registered
          trip_detail_inject.initTripDetailModule();
          final extra = state.extra;

          if (extra == null) {
            return slideFadePage(
              child: const Scaffold(
                body: Center(child: Text('No trip specified')),
              ),
            );
          }

          // Do not construct domain entities in the router. Extract the trip id
          // from the provided `extra` and forward the raw `extra` as preview data
          // to the feature. The TripDetail feature should map preview -> entity.
          String? id;
          try {
            final dyn = extra as dynamic;
            try {
              id = dyn.id?.toString();
            } catch (_) {
              try {
                id = (extra as Map)['id']?.toString();
              } catch (_) {}
            }
          } catch (_) {
            id = null;
          }

          if (id == null) {
            return slideFadePage(
              child: const Scaffold(
                body: Center(child: Text('No trip specified')),
              ),
            );
          }

          return slideFadePage(
            child: BlocProvider(
              create: (_) =>
                  sl<TripDetailPageBloc>()..add(WatchExpensesStarted(id!)),
              child: TripDetailPage(tripId: id),
            ),
          );
        },
      ),

      /// PERJALANAN
      GoRoute(
        path: '/perjalanan',
        pageBuilder: (context, state) {
          // ensure feature dependencies are registered
          perjalanan_inject.initPerjalananModule();
          return slideFadePage(
            child: BlocProvider(
              create: (_) => sl<PerjalananBloc>()..add(LoadPerjalanan()),
              child: const PerjalananPage(),
            ),
          );
        },
      ),

      /// PENGELUARAN (as a tab inside Home)
      GoRoute(
        path: '/pengeluaran',
        pageBuilder: (context, state) {
          // ensure add_pengeluaran feature registered
          add_pengeluaran_inject.initAddPengeluaranModule();
          // reuse FeatureHomePage but start with Pengeluaran tab selected
          return MaterialPage(
            child: FeatureHomePage(
              initialIndex: 2,
              homeBloc: sl<HomePageBloc>(),
              authBloc: authBloc,
              appUpdateCubit: sl<AppUpdateCubit>(),
              createPerjalananBloc: () => sl<PerjalananBloc>(),
              createAddPengeluaranBloc: () =>
                  sl<add_pengeluaran_bloc.AddPengeluaranBloc>(),
            ),
          );
        },
      ),

      /// DRAFT EDITOR (navigable page instead of bottom sheet)
      GoRoute(
        path: '/pengeluaran/draft',
        pageBuilder: (context, state) {
          // ensure feature registered
          add_pengeluaran_inject.initAddPengeluaranModule();
          return slideFadePage(child: const DraftEditorPage());
        },
      ),
    ],

    /// ================= REDIRECT =================
    redirect: (context, state) {
      final authState = authBloc.state;
      final loggedIn = authState is Authenticated;

      final location = state.uri.toString();
      final goingToAuth = location == '/login' || location == '/signup';

      if (!loggedIn && !goingToAuth && location != '/') {
        return '/login';
      }

      return null;
    },
  );
}
