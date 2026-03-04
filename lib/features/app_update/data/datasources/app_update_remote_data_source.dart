import 'package:dio/dio.dart';

class AppUpdateRemoteModel {
  final String latestVersion;
  final String? minSupportedVersion;
  final bool forceUpdate;
  final String title;
  final String message;
  final String? changelog;
  final String? storeUrl;

  const AppUpdateRemoteModel({
    required this.latestVersion,
    this.minSupportedVersion,
    required this.forceUpdate,
    required this.title,
    required this.message,
    this.changelog,
    this.storeUrl,
  });
}

abstract class AppUpdateRemoteDataSource {
  Future<AppUpdateRemoteModel?> fetchUpdateInfo();
}

class AppUpdateRemoteDataSourceImpl implements AppUpdateRemoteDataSource {
  final Dio dio;
  final String manifestUrl;

  AppUpdateRemoteDataSourceImpl({required this.dio, this.manifestUrl = ''});

  @override
  Future<AppUpdateRemoteModel?> fetchUpdateInfo() async {
    final url = manifestUrl.trim();
    if (url.isEmpty) return null;

    final resp = await dio.get(
      url,
      options: Options(validateStatus: (_) => true),
    );

    if (resp.statusCode == null ||
        resp.statusCode! < 200 ||
        resp.statusCode! >= 300) {
      return null;
    }

    final data = resp.data;
    if (data is! Map) return null;
    final map = Map<String, dynamic>.from(data);

    final latestVersion = (map['latest_version'] ?? map['latestVersion'] ?? '')
        .toString()
        .trim();
    if (latestVersion.isEmpty) return null;

    final forceRaw = map['force_update'] ?? map['forceUpdate'];
    final forceUpdate =
        forceRaw == true || forceRaw?.toString().toLowerCase() == 'true';

    final downloadUrl =
        (map['apk_url'] ??
                map['download_url'] ??
                map['store_url'] ??
                map['storeUrl'])
            ?.toString();

    return AppUpdateRemoteModel(
      latestVersion: latestVersion,
      minSupportedVersion:
          (map['min_supported_version'] ?? map['minSupportedVersion'])
              ?.toString(),
      forceUpdate: forceUpdate,
      title: (map['title'] ?? 'Pembaruan Tersedia').toString(),
      message:
          (map['message'] ??
                  'Versi $latestVersion tersedia. Silakan unduh APK terbaru.')
              .toString(),
      changelog: map['changelog']?.toString(),
      storeUrl: downloadUrl,
    );
  }
}
