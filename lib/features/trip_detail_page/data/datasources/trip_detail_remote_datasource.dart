// ignore_for_file: curly_braces_in_flow_control_structures

import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:trips_apps/core/constan/constan.dart';
import '../../domain/entities/expense_entity.dart';
import '../exceptions.dart';

abstract class TripDetailRemoteDataSource {
  Future<List<ExpenseEntity>> fetchItems(String tripId);
  Future<Map<String, dynamic>?> fetchTripPreview(String tripId);
  Future<bool> submitTripForAudit(String tripId);
  Future<bool> deleteItem(String tripId, String itemId);
  Future<bool> updateItem(
    String tripId,
    String itemId,
    Map<String, dynamic> patch,
  );
  Future<bool> clearItemAttachments(
    String tripId,
    String itemId,
    List<String> attachmentPaths,
  );
  Future<bool> uploadItemAttachment(String tripId, String itemId, File file);
}

class TripDetailRemoteDataSourceImpl implements TripDetailRemoteDataSource {
  final Dio dio;
  final SharedPreferences prefs;

  TripDetailRemoteDataSourceImpl(this.dio, this.prefs);

  String _getUserId() {
    final raw = prefs.getString('auth_user');
    var id = prefs.getString('auth_user_id') ?? '';
    if (id.isEmpty && raw != null && raw.isNotEmpty) {
      try {
        final Map<String, dynamic> m = jsonDecode(raw);
        id = (m['uid'] ?? m['id'] ?? '').toString();
      } catch (_) {}
    }
    return id;
  }

  String _extractDioMessage(DioException e, {required String fallback}) {
    final data = e.response?.data;
    if (data is Map && data['message'] != null) {
      final message = data['message'].toString().trim();
      if (message.isNotEmpty) return message;
    }
    return fallback;
  }

  @override
  Future<List<ExpenseEntity>> fetchItems(String tripId) async {
    try {
      final url = ApiConfig.current.endpoint(
        ApiConfig.current.perjalananItemsPath(tripId),
      );
      final resp = await dio.get(url);
      if (resp.statusCode == 200) {
        final data = resp.data;
        if (data is List) {
          return data.map((e) => ExpenseEntity.fromJson(e)).toList();
        }
        final items = data['data'] ?? data['items'] ?? [];
        return (items as List).map((e) => ExpenseEntity.fromJson(e)).toList();
      }
      throw TripDetailRemoteException('Gagal memuat item perjalanan');
    } on DioException catch (e) {
      throw TripDetailRemoteException(
        _extractDioMessage(e, fallback: 'Gagal memuat item perjalanan'),
      );
    }
  }

  @override
  Future<Map<String, dynamic>?> fetchTripPreview(String tripId) async {
    try {
      final userId = _getUserId();
      final url = ApiConfig.current.endpoint(ApiConfig.current.perjalananURL);
      final resp = await dio.get(
        url,
        queryParameters: {'user_id': userId, 'limit': 200},
      );
      if (resp.statusCode == 200) {
        final data = resp.data;
        List<dynamic> list = [];
        if (data is List) {
          list = data;
        } else if (data is Map && data.containsKey('data')) {
          list = data['data'];
        }
        for (final item in list) {
          try {
            final m = Map<String, dynamic>.from(item);
            final id1 = m['id']?.toString();
            final id2 = m['_id']?.toString();
            if ((id1 != null && id1 == tripId) ||
                (id2 != null && id2 == tripId)) {
              return m;
            }
          } catch (_) {}
        }
        return null;
      }
      throw TripDetailRemoteException('Gagal memuat preview perjalanan');
    } on DioException catch (e) {
      throw TripDetailRemoteException(
        _extractDioMessage(e, fallback: 'Gagal memuat preview perjalanan'),
      );
    }
  }

  @override
  Future<bool> submitTripForAudit(String tripId) async {
    try {
      final path = '${ApiConfig.current.perjalananURL}/$tripId/submit-audit';
      final url = ApiConfig.current.endpoint(path);
      final resp = await dio.post(
        url,
        options: Options(validateStatus: (_) => true),
      );
      if (resp.statusCode != null &&
          (resp.statusCode! >= 200 && resp.statusCode! < 300)) {
        return true;
      }

      final patchUrl = ApiConfig.current.endpoint(
        '${ApiConfig.current.perjalananURL}/$tripId',
      );
      final patchResp = await dio.patch(
        patchUrl,
        data: {'status': 'Sedang di audit'},
        options: Options(validateStatus: (_) => true),
      );
      if (patchResp.statusCode != null &&
          (patchResp.statusCode! >= 200 && patchResp.statusCode! < 300)) {
        return true;
      }

      throw TripDetailRemoteException(
        _extractMessage(patchResp.data) ?? 'Gagal mengirim perjalanan ke audit',
      );
    } on DioException catch (e) {
      throw TripDetailRemoteException(
        _extractDioMessage(e, fallback: 'Gagal mengirim perjalanan ke audit'),
      );
    }
  }

  @override
  Future<bool> deleteItem(String tripId, String itemId) async {
    try {
      final path = '${ApiConfig.current.perjalananURL}/$tripId/items/$itemId';
      final url = ApiConfig.current.endpoint(path);
      final resp = await dio.delete(
        url,
        options: Options(validateStatus: (_) => true),
      );
      if (resp.statusCode != null &&
          resp.statusCode! >= 200 &&
          resp.statusCode! < 300) {
        return true;
      }
      throw TripDetailRemoteException(
        _extractMessage(resp.data) ?? 'Gagal menghapus item',
      );
    } on DioException catch (e) {
      throw TripDetailRemoteException(
        _extractDioMessage(e, fallback: 'Gagal menghapus item'),
      );
    }
  }

  @override
  Future<bool> updateItem(
    String tripId,
    String itemId,
    Map<String, dynamic> patch,
  ) async {
    final path = '${ApiConfig.current.perjalananURL}/$tripId/items/$itemId';
    final url = ApiConfig.current.endpoint(path);

    final cleanPatch = <String, dynamic>{};
    patch.forEach((key, value) {
      if (value != null) cleanPatch[key] = value;
    });

    final payloadCandidates = <Map<String, dynamic>>[
      cleanPatch,
      {
        ...cleanPatch,
        if (cleanPatch['tanggal_transaksi'] != null)
          'tanggal': cleanPatch['tanggal_transaksi'],
      },
    ];

    String? lastMessage;

    for (final payload in payloadCandidates) {
      final patchResp = await dio.patch(
        url,
        data: payload,
        options: Options(validateStatus: (_) => true),
      );

      if (patchResp.statusCode != null &&
          patchResp.statusCode! >= 200 &&
          patchResp.statusCode! < 300) {
        return true;
      }

      lastMessage = _extractMessage(patchResp.data) ??
          'Gagal memperbarui item (PATCH ${patchResp.statusCode ?? '-'})';

      if (patchResp.statusCode == 404 || patchResp.statusCode == 405) {
        final putResp = await dio.put(
          url,
          data: payload,
          options: Options(validateStatus: (_) => true),
        );
        if (putResp.statusCode != null &&
            putResp.statusCode! >= 200 &&
            putResp.statusCode! < 300) {
          return true;
        }
        lastMessage = _extractMessage(putResp.data) ??
            'Gagal memperbarui item (PUT ${putResp.statusCode ?? '-'})';
      }
    }

    throw TripDetailRemoteException(lastMessage ?? 'Gagal memperbarui item');
  }

  String? _extractMessage(dynamic data) {
    if (data is Map && data['message'] != null) {
      return data['message'].toString();
    }
    return null;
  }

  String? _extractFilename(String rawPath) {
    final cleaned = rawPath.trim();
    if (cleaned.isEmpty) return null;
    final segments = cleaned.split('/').where((e) => e.isNotEmpty).toList();
    if (segments.isEmpty) return null;
    return segments.last;
  }

  @override
  Future<bool> clearItemAttachments(
    String tripId,
    String itemId,
    List<String> attachmentPaths,
  ) async {
    if (attachmentPaths.isEmpty) return true;

    try {
      for (final rawPath in attachmentPaths) {
        final filename = _extractFilename(rawPath);
        if (filename == null || filename.isEmpty) continue;

        final deletePath =
            '${ApiConfig.current.perjalananURL}/$tripId/items/$itemId/attachments/${Uri.encodeComponent(filename)}';
        final deleteUrl = ApiConfig.current.endpoint(deletePath);
        final resp = await dio.delete(
          deleteUrl,
          options: Options(validateStatus: (_) => true),
        );
        if (resp.statusCode == null ||
            resp.statusCode! < 200 ||
            resp.statusCode! >= 300) {
          throw TripDetailRemoteException(
            _extractMessage(resp.data) ?? 'Gagal menghapus foto lama',
          );
        }
      }
      return true;
    } on DioException catch (e) {
      throw TripDetailRemoteException(
        _extractDioMessage(e, fallback: 'Gagal menghapus foto lama'),
      );
    }
  }

  @override
  Future<bool> uploadItemAttachment(String tripId, String itemId, File file) async {
    try {
      final path =
          '${ApiConfig.current.perjalananURL}/$tripId/items/$itemId/attachments';
      final url = ApiConfig.current.endpoint(path);
      final filename = file.path.split(Platform.pathSeparator).last;
      final fieldCandidates = ['attachments', 'attachments[]', 'file'];

      for (final field in fieldCandidates) {
        final form = FormData.fromMap({
          field: await MultipartFile.fromFile(file.path, filename: filename),
        });

        final resp = await dio.post(
          url,
          data: form,
          options: Options(
            contentType: 'multipart/form-data',
            validateStatus: (_) => true,
          ),
        );

        if (resp.statusCode != null &&
            resp.statusCode! >= 200 &&
            resp.statusCode! < 300) {
          return true;
        }

        final msg = _extractMessage(resp.data)?.toLowerCase() ?? '';
        if (!msg.contains('unexpected field')) {
          throw TripDetailRemoteException(
            _extractMessage(resp.data) ?? 'Gagal upload foto baru',
          );
        }
      }

      throw TripDetailRemoteException('Gagal upload foto baru');
    } on DioException catch (e) {
      throw TripDetailRemoteException(
        _extractDioMessage(e, fallback: 'Gagal upload foto baru'),
      );
    }
  }
}
