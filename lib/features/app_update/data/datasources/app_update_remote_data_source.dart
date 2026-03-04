import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

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
  late final Dio _publicDio;

  AppUpdateRemoteDataSourceImpl({required this.dio, this.manifestUrl = ''}) {
    _publicDio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 12),
        receiveTimeout: const Duration(seconds: 12),
        sendTimeout: const Duration(seconds: 12),
        headers: const <String, dynamic>{},
      ),
    );
  }

  void _log(String message) {
    if (kDebugMode) {
      debugPrint('[AppUpdate][Remote] $message');
    }
  }

  @override
  Future<AppUpdateRemoteModel?> fetchUpdateInfo() async {
    final url = manifestUrl.trim();
    if (url.isEmpty) {
      _log('Manifest URL kosong. APP_UPDATE_MANIFEST_URL belum terpasang.');
      return null;
    }

    _log('Fetch manifest dari: $url');

    final Response<dynamic> resp;
    try {
      resp = await _publicDio.get(
        url,
        options: Options(
          validateStatus: (_) => true,
          responseType: ResponseType.plain,
          headers: const <String, dynamic>{},
        ),
      );
    } catch (e) {
      _log('Gagal request manifest: $e');
      rethrow;
    }

    _log('HTTP status manifest: ${resp.statusCode}');

    if (resp.statusCode == null ||
        resp.statusCode! < 200 ||
        resp.statusCode! >= 300) {
      _log('Manifest tidak valid karena status HTTP bukan 2xx.');
      return null;
    }

    final data = resp.data;
    Map<String, dynamic>? map;
    if (data is Map) {
      map = Map<String, dynamic>.from(data);
    } else if (data is String) {
      try {
        final decoded = jsonDecode(data);
        if (decoded is Map) {
          map = Map<String, dynamic>.from(decoded);
        }
      } catch (_) {
        _log('Gagal parse JSON string manifest.');
        return null;
      }
    }

    if (map == null) {
      _log('Body manifest bukan object JSON.');
      return null;
    }

    final latestVersion = (map['latest_version'] ?? map['latestVersion'] ?? '')
        .toString()
        .trim();
    if (latestVersion.isEmpty) {
      _log('latest_version kosong.');
      return null;
    }

    final forceRaw = map['force_update'] ?? map['forceUpdate'];
    final forceUpdate =
        forceRaw == true || forceRaw?.toString().toLowerCase() == 'true';

    final downloadUrl =
        (map['apk_url'] ??
                map['download_url'] ??
                map['store_url'] ??
                map['storeUrl'])
            ?.toString();

    _log(
      'Manifest terbaca. latest=$latestVersion force=$forceUpdate hasApkUrl=${(downloadUrl ?? '').trim().isNotEmpty}',
    );

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
