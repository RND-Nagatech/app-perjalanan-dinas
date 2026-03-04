class AppUpdateInfo {
  final String latestVersion;
  final String? minSupportedVersion;
  final bool forceUpdate;
  final String title;
  final String message;
  final String? changelog;
  final String? storeUrl;

  const AppUpdateInfo({
    required this.latestVersion,
    this.minSupportedVersion,
    required this.forceUpdate,
    required this.title,
    required this.message,
    this.changelog,
    this.storeUrl,
  });
}
