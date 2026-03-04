import 'app_update_info.dart';

class AppUpdateResult {
  final String currentVersion;
  final AppUpdateInfo? updateInfo;
  final bool shouldUpdate;
  final bool forceUpdate;

  const AppUpdateResult({
    required this.currentVersion,
    required this.updateInfo,
    required this.shouldUpdate,
    required this.forceUpdate,
  });
}
