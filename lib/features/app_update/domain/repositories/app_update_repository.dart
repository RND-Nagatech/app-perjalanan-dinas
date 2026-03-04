import '../entities/app_update_info.dart';

abstract class AppUpdateRepository {
  Future<String> getCurrentVersion();
  Future<AppUpdateInfo?> fetchUpdateInfo();
}
