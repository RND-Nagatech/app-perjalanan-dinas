import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter/foundation.dart';

import '../../domain/entities/app_update_info.dart';
import '../../domain/repositories/app_update_repository.dart';
import '../datasources/app_update_remote_data_source.dart';

class AppUpdateRepositoryImpl implements AppUpdateRepository {
  final AppUpdateRemoteDataSource remote;

  AppUpdateRepositoryImpl(this.remote);

  void _log(String message) {
    if (kDebugMode) {
      debugPrint('[AppUpdate][Repo] $message');
    }
  }

  @override
  Future<String> getCurrentVersion() async {
    final info = await PackageInfo.fromPlatform();
    _log('Current app version: ${info.version} (${info.buildNumber})');
    return info.version;
  }

  @override
  Future<AppUpdateInfo?> fetchUpdateInfo() async {
    final remoteInfo = await remote.fetchUpdateInfo();
    if (remoteInfo == null) {
      _log('Remote update info tidak tersedia.');
      return null;
    }

    _log('Remote latest version: ${remoteInfo.latestVersion}');

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
