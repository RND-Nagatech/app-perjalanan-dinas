import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';

import '../../domain/usecases/check_app_update.dart';
import 'app_update_state.dart';

class AppUpdateCubit extends Cubit<AppUpdateState> {
  final CheckAppUpdate checkAppUpdate;

  AppUpdateCubit({required this.checkAppUpdate})
    : super(const AppUpdateState.initial());

  void _log(String message) {
    if (kDebugMode) {
      debugPrint('[AppUpdate][Cubit] $message');
    }
  }

  Future<void> check() async {
    if (state.isChecking) {
      _log('Skip check karena masih berjalan.');
      return;
    }
    _log('Mulai check update...');
    emit(state.copyWith(isChecking: true));

    try {
      final result = await checkAppUpdate.call();
      _log(
        'Check selesai. current=${result.currentVersion} hasUpdate=${result.shouldUpdate} force=${result.forceUpdate}',
      );
      emit(
        state.copyWith(
          isChecking: false,
          hasChecked: true,
          appVersion: result.currentVersion,
          updateInfo: result.updateInfo,
          forceUpdate: result.forceUpdate,
          clearUpdateInfo: !result.shouldUpdate,
        ),
      );
    } catch (e) {
      _log('Check gagal: $e');
      emit(
        state.copyWith(
          isChecking: false,
          hasChecked: true,
          // fallback appVersion tetap apa adanya jika gagal
        ),
      );
    }
  }
}
