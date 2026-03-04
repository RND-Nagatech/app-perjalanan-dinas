import 'package:equatable/equatable.dart';

import '../../domain/entities/app_update_info.dart';

class AppUpdateState extends Equatable {
  final bool isChecking;
  final bool hasChecked;
  final String appVersion;
  final AppUpdateInfo? updateInfo;
  final bool forceUpdate;

  const AppUpdateState({
    required this.isChecking,
    required this.hasChecked,
    required this.appVersion,
    required this.updateInfo,
    required this.forceUpdate,
  });

  const AppUpdateState.initial()
    : isChecking = false,
      hasChecked = false,
      appVersion = '-',
      updateInfo = null,
      forceUpdate = false;

  AppUpdateState copyWith({
    bool? isChecking,
    bool? hasChecked,
    String? appVersion,
    AppUpdateInfo? updateInfo,
    bool? forceUpdate,
    bool clearUpdateInfo = false,
  }) {
    return AppUpdateState(
      isChecking: isChecking ?? this.isChecking,
      hasChecked: hasChecked ?? this.hasChecked,
      appVersion: appVersion ?? this.appVersion,
      updateInfo: clearUpdateInfo ? null : (updateInfo ?? this.updateInfo),
      forceUpdate: forceUpdate ?? this.forceUpdate,
    );
  }

  @override
  List<Object?> get props => [
    isChecking,
    hasChecked,
    appVersion,
    updateInfo,
    forceUpdate,
  ];
}
