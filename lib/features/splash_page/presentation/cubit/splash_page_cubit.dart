import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../../../features/Auth/domain/usecases/get_current_user_usecase.dart';
import '../../../../../features/Auth/presentation/bloc/auth_bloc.dart';
import '../../../../../features/Auth/presentation/bloc/auth_state.dart';

part 'splash_page_state.dart';

class SplashPageCubit extends Cubit<SplashPageState> {
  final GetCurrentUserUseCase _getCurrentUser;
  final AuthBloc? _authBloc;

  SplashPageCubit({
    required GetCurrentUserUseCase getCurrentUser,
    AuthBloc? authBloc,
  }) : _getCurrentUser = getCurrentUser,
       _authBloc = authBloc,
       super(SplashPageInitial());

  /// Start the splash flow: wait, check auth, then emit authenticated/unauthenticated.
  Future<void> start() async {
    emit(SplashLoading());

    // initial splash delay before revealing sheet / navigating
    await Future.delayed(const Duration(milliseconds: 1400));

    try {
      // Prefer to consult AuthBloc if available to avoid race conditions
      try {
        final authBloc = _authBloc;
        if (authBloc == null) {
          throw Exception('AuthBloc not provided');
        }
        // If authBloc already resolved user, use it. Otherwise wait briefly for its initial check.
        var authState = authBloc.state;
        if (authState is AuthLoading || authState is AuthInitial) {
          // wait for first non-loading state or timeout
          authState = await authBloc.stream.firstWhere((s) => s is! AuthLoading, orElse: () => authBloc.state).timeout(const Duration(seconds: 3), onTimeout: () => authBloc.state);
        }
        if (authState is Authenticated) {
          emit(SplashAuthenticated());
          return;
        }
        if (authState is Unauthenticated) {
          emit(SplashUnauthenticated());
          return;
        }
        // fallback to direct check
      } catch (_) {}

      final user = await _getCurrentUser.call();
      if (user != null) {
        emit(SplashAuthenticated());
      } else {
        emit(SplashUnauthenticated());
      }
    } catch (_) {
      // on error, treat as unauthenticated
      emit(SplashUnauthenticated());
    }
  }
}
