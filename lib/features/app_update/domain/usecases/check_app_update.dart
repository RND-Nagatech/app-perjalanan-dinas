import 'package:flutter/foundation.dart';

import '../entities/app_update_result.dart';
import '../repositories/app_update_repository.dart';

class CheckAppUpdate {
  final AppUpdateRepository repository;

  CheckAppUpdate(this.repository);

  void _log(String message) {
    if (kDebugMode) {
      debugPrint('[AppUpdate][UseCase] $message');
    }
  }

  Future<AppUpdateResult> call() async {
    final currentVersion = await repository.getCurrentVersion();
    final updateInfo = await repository.fetchUpdateInfo();

    if (updateInfo == null) {
      _log('Tidak ada update info. current=$currentVersion');
      return AppUpdateResult(
        currentVersion: currentVersion,
        updateInfo: null,
        shouldUpdate: false,
        forceUpdate: false,
      );
    }

    final shouldUpdate =
        _compareVersion(currentVersion, updateInfo.latestVersion) < 0;

    final isBelowMinimum =
        updateInfo.minSupportedVersion != null &&
        updateInfo.minSupportedVersion!.trim().isNotEmpty &&
        _compareVersion(
              currentVersion,
              updateInfo.minSupportedVersion!.trim(),
            ) <
            0;

    final forceUpdate = updateInfo.forceUpdate || isBelowMinimum;

    _log(
      'Decision current=$currentVersion latest=${updateInfo.latestVersion} shouldUpdate=$shouldUpdate forceUpdate=$forceUpdate minSupported=${updateInfo.minSupportedVersion}',
    );

    return AppUpdateResult(
      currentVersion: currentVersion,
      updateInfo: shouldUpdate ? updateInfo : null,
      shouldUpdate: shouldUpdate,
      forceUpdate: shouldUpdate && forceUpdate,
    );
  }

  int _compareVersion(String a, String b) {
    final aParts = a.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    final bParts = b.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    final maxLen = aParts.length > bParts.length
        ? aParts.length
        : bParts.length;

    for (var i = 0; i < maxLen; i++) {
      final av = i < aParts.length ? aParts[i] : 0;
      final bv = i < bParts.length ? bParts[i] : 0;
      if (av > bv) return 1;
      if (av < bv) return -1;
    }
    return 0;
  }
}
