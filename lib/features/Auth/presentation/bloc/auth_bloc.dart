import 'package:bloc/bloc.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/usecases/get_current_user_usecase.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/logout_usecase.dart';
import '../../domain/usecases/register_usecase.dart';
import '../../domain/usecases/clear_saved_credentials_usecase.dart';
import '../../domain/failures/auth_failure.dart';
import 'auth_event.dart';
import 'auth_state.dart';
import 'package:perjalanan_dinas/features/home_page/domain/usecases/refresh_trips.dart';
import 'package:perjalanan_dinas/features/home_page/domain/usecases/clear_trips_cache.dart';
import 'package:perjalanan_dinas/core/services/refresh_coordinator.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final LoginUseCase loginUseCase;
  final RegisterUseCase registerUseCase;
  final LogoutUseCase logoutUseCase;
  final GetCurrentUserUseCase getCurrentUserUseCase;
  final RefreshTrips refreshTrips;
  final ClearTripsCache clearTripsCache;
  final ClearSavedCredentialsUseCase clearSavedCredentialsUseCase;
  final RefreshCoordinator refreshCoordinator;

  AuthBloc({
    required this.loginUseCase,
    required this.registerUseCase,
    required this.logoutUseCase,
    required this.getCurrentUserUseCase,
    required this.refreshTrips,
    required this.clearTripsCache,
    required this.clearSavedCredentialsUseCase,
    required this.refreshCoordinator,
  }) : super(AuthInitial()) {
    on<LoginRequested>(_onLoginRequested);
    on<RegisterRequested>(_onRegisterRequested);
    on<LogoutRequested>(_onLogoutRequested);
    on<AppStarted>(_onAppStarted);
  }

  Future<void> _onAppStarted(AppStarted event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final user = await getCurrentUserUseCase.call();
      if (user != null) {
        emit(Authenticated(user));
      } else {
        emit(Unauthenticated());
      }
    } on AuthFailure catch (e) {
      emit(AuthError(e.message));
    } catch (_) {
      emit(AuthError("Terjadi kesalahan"));
    }
  }

  Future<void> _onLoginRequested(
    LoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final UserEntity user = await loginUseCase(
        LoginParams(email: event.email, password: event.password),
      );

      emit(Authenticated(user));
      try {
        await refreshTrips.call();
        await refreshCoordinator.refreshAll().timeout(
          const Duration(seconds: 8),
          onTimeout: () async {},
        );
      } catch (_) {}
    } on AuthFailure catch (e) {
      emit(AuthError(e.message));
    } catch (_) {
      emit(AuthError("Login gagal"));
    }
  }

  Future<void> _onRegisterRequested(
    RegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      await registerUseCase.call(event.email, event.password, name: event.name);

      // Registration succeeded — instruct UI to navigate to Login.
      emit(AuthRegisterSuccess());
    } on AuthFailure catch (e) {
      emit(AuthError(e.message));
    } catch (_) {
      emit(AuthError("Register gagal"));
    }
  }

  Future<void> _onLogoutRequested(
    LogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      await logoutUseCase.call();
      try {
        await clearTripsCache.call();
      } catch (_) {}
      try {
        await clearSavedCredentialsUseCase.call();
      } catch (_) {}
      emit(Unauthenticated());
    } on AuthFailure catch (e) {
      emit(AuthError(e.message));
    } catch (_) {
      emit(AuthError("Logout gagal"));
    }
  }
}
