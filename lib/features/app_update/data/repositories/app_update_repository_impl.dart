import 'package:package_info_plus/package_info_plus.dart';

import '../../domain/entities/app_update_info.dart';
import '../../domain/repositories/app_update_repository.dart';
import '../datasources/app_update_remote_data_source.dart';

class AppUpdateRepositoryImpl implements AppUpdateRepository {
  final AppUpdateRemoteDataSource remote;

  AppUpdateRepositoryImpl(this.remote);

  @override
  Future<String> getCurrentVersion() async {
    final info = await PackageInfo.fromPlatform();
    return info.version;
  }

  @override
  Future<AppUpdateInfo?> fetchUpdateInfo() async {
    final remoteInfo = await remote.fetchUpdateInfo();
    if (remoteInfo == null) return null;

    return AppUpdateInfo(
      latestVersion: remoteInfo.latestVersion,
      minSupportedVersion: remoteInfo.minSupportedVersion,
      forceUpdate: remoteInfo.forceUpdate,
      title: remoteInfo.title,
      message: remoteInfo.message,
      changelog: remoteInfo.changelog,
      storeUrl: remoteInfo.storeUrl,
    );
  }
}
