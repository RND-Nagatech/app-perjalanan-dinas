import 'package:bloc/bloc.dart';

import '../../domain/usecases/check_app_update.dart';
import 'app_update_state.dart';

class AppUpdateCubit extends Cubit<AppUpdateState> {
  final CheckAppUpdate checkAppUpdate;

  AppUpdateCubit({required this.checkAppUpdate})
    : super(const AppUpdateState.initial());

  Future<void> check() async {
    if (state.isChecking) return;
    emit(state.copyWith(isChecking: true));

    try {
      final result = await checkAppUpdate.call();
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
    } catch (_) {
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
