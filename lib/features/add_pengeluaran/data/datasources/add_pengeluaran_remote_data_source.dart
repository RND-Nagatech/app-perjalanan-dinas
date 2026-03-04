import 'dart:io';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/active_trip.dart';
import '../../domain/entities/created_item.dart';
import '../exceptions.dart';

abstract class AddPengeluaranRemoteDataSource {
  Future<List<ActiveTrip>> fetchActiveTrips();
  Future<int?> fetchSisaForTrip(String tripId);
  Future<CreatedItem> createItem(String tripId, Map<String, dynamic> payload);
  Future<void> uploadAttachment(String tripId, String itemId, File file);
}

class AddPengeluaranRemoteDataSourceImpl
    implements AddPengeluaranRemoteDataSource {
  final Dio dio;
  final SharedPreferences prefs;

  AddPengeluaranRemoteDataSourceImpl(this.dio, this.prefs);

  String _getUserId() {
    final raw = prefs.getString('auth_user');
    var id = prefs.getString('auth_user_id') ?? '';
    if (id.isEmpty && raw != null && raw.isNotEmpty) {
      try {
        final Map<String, dynamic> m = jsonDecode(raw) as Map<String, dynamic>;
        id = (m['uid'] ?? m['id'] ?? '').toString();
      } catch (_) {}
    }
    return id;
  }

  String _extractDioMessage(DioException e, {required String fallback}) {
    final data = e.response?.data;
    if (data is Map<String, dynamic>) {
      final message = data['message']?.toString();
      if (message != null && message.trim().isNotEmpty) return message;
    }
    return fallback;
  }

  String? _extractTripOwnerId(Map<String, dynamic> trip) {
    final directCandidates = [
      trip['user_id'],
      trip['uid'],
      trip['by'],
      trip['owner_id'],
      trip['created_by'],
      trip['requested_by'],
    ];
    for (final candidate in directCandidates) {
      final value = candidate?.toString().trim() ?? '';
      if (value.isNotEmpty) return value;
    }

    final nestedCandidates = [
      trip['user'],
      trip['owner'],
      trip['createdBy'],
      trip['requestedBy'],
    ];
    for (final nested in nestedCandidates) {
      if (nested is Map) {
        final map = Map<String, dynamic>.from(nested);
        final value =
            (map['id'] ?? map['_id'] ?? map['uid'])?.toString().trim() ?? '';
        if (value.isNotEmpty) return value;
      }
    }

    return null;
  }

  bool _isBerjalan(Map<String, dynamic> trip) {
    final status =
        (trip['status'] ?? trip['status_perjalanan'] ?? trip['state'])
            ?.toString()
            .toLowerCase() ??
        '';
    return status.contains('berjalan');
  }

  @override
  Future<List<ActiveTrip>> fetchActiveTrips() async {
    try {
      final userId = _getUserId();
      final url = '/perjalanan-dinas';
      final resp = await dio.get(
        url,
        queryParameters: {
          'user_id': userId,
          'by': userId,
          'status': 'BERJALAN',
        },
      );
      if (resp.statusCode == 200) {
        final data = resp.data;
        final List<Map<String, dynamic>> raw;
        if (data is List) {
          raw = List<Map<String, dynamic>>.from(data);
        } else if (data is Map && data.containsKey('data')) {
          raw = List<Map<String, dynamic>>.from(data['data']);
        } else {
          return [];
        }

        final filtered = raw.where((trip) {
          if (!_isBerjalan(trip)) return false;
          if (userId.trim().isEmpty) return true;

          final ownerId = _extractTripOwnerId(trip);
          if (ownerId == null || ownerId.isEmpty) return true;
          return ownerId == userId;
        }).toList();

        return filtered
            .map((trip) {
              final id = (trip['id'] ?? trip['_id'] ?? '').toString();
              final label = (trip['kode_perjalanan'] ?? trip['name'] ?? '-')
                  .toString();
              final sisaRaw =
                  trip['sisa'] ?? trip['sisa_dana'] ?? trip['remaining'];
              final sisa = sisaRaw is num
                  ? sisaRaw.toInt()
                  : int.tryParse(sisaRaw?.toString() ?? '');
              return ActiveTrip(id: id, label: label, sisaDana: sisa);
            })
            .where((trip) => trip.id.isNotEmpty)
            .toList();
      }
      throw AddPengeluaranRemoteException('Gagal memuat perjalanan aktif');
    } on DioException catch (e) {
      throw AddPengeluaranRemoteException(
        _extractDioMessage(e, fallback: 'Gagal memuat perjalanan aktif'),
      );
    }
  }

  @override
  Future<int?> fetchSisaForTrip(String tripId) async {
    try {
      final url = '/perjalanan-dinas';
      final resp = await dio.get(url, queryParameters: {'_id': tripId});
      if (resp.statusCode == 200) {
        final data = resp.data;
        if (data is List && data.isNotEmpty) {
          final m = data.first as Map<String, dynamic>;
          return m['sisa_dana'] as int? ?? (m['sisaDana'] as int?);
        }
        if (data is Map && data.containsKey('data')) {
          final list = data['data'] as List;
          if (list.isNotEmpty) {
            final m = Map<String, dynamic>.from(list.first);
            return m['sisa_dana'] as int? ?? (m['sisaDana'] as int?);
          }
        }
        return null;
      }
      throw AddPengeluaranRemoteException('Gagal memuat detail perjalanan');
    } on DioException catch (e) {
      throw AddPengeluaranRemoteException(
        _extractDioMessage(e, fallback: 'Gagal memuat detail perjalanan'),
      );
    }
  }

  @override
  Future<CreatedItem> createItem(
    String tripId,
    Map<String, dynamic> payload,
  ) async {
    try {
      final url = '/perjalanan-dinas/$tripId/items';
      final resp = await dio.post(url, data: payload);
      if (resp.statusCode != null &&
          resp.statusCode! >= 200 &&
          resp.statusCode! < 300) {
        final body = Map<String, dynamic>.from(resp.data ?? {});
        final id = (body['id'] ?? body['_id'])?.toString();
        if (id == null || id.isEmpty) {
          throw AddPengeluaranRemoteException('ID item tidak ditemukan');
        }
        return CreatedItem(id: id);
      }
      throw AddPengeluaranRemoteException('Gagal membuat item pengeluaran');
    } on DioException catch (e) {
      throw AddPengeluaranRemoteException(
        _extractDioMessage(e, fallback: 'Gagal membuat item pengeluaran'),
      );
    }
  }

  @override
  Future<void> uploadAttachment(String tripId, String itemId, File file) async {
    try {
      final url = '/perjalanan-dinas/$tripId/items/$itemId/attachments';
      final name = file.path.split(Platform.pathSeparator).last;
      final fieldCandidates = ['attachments', 'attachments[]', 'file'];

      for (final field in fieldCandidates) {
        final form = FormData.fromMap({
          field: await MultipartFile.fromFile(file.path, filename: name),
        });

        try {
          final resp = await dio.post(
            url,
            data: form,
            options: Options(contentType: 'multipart/form-data'),
          );
          if (resp.statusCode != null &&
              resp.statusCode! >= 200 &&
              resp.statusCode! < 300) {
            return;
          }
        } on DioException catch (e) {
          final message = (e.response?.data is Map<String, dynamic>)
              ? (e.response?.data['message']?.toString().toLowerCase() ?? '')
              : '';
          final isUnexpectedField = message.contains('unexpected field');
          if (!isUnexpectedField || field == fieldCandidates.last) {
            throw AddPengeluaranRemoteException(
              _extractDioMessage(e, fallback: 'Gagal upload lampiran'),
            );
          }
        }
      }

      throw AddPengeluaranRemoteException('Gagal upload lampiran');
    } on AddPengeluaranRemoteException {
      rethrow;
    } catch (_) {
      throw AddPengeluaranRemoteException('Gagal upload lampiran');
    }
  }
}
