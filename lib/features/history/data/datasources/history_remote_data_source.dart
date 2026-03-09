import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:perjalanan_dinas/features/history/data/models/history_trip_model.dart';
import 'package:perjalanan_dinas/core/constan/constan.dart';
import 'package:perjalanan_dinas/core/domain/entities/trip_entity.dart';
import '../exceptions.dart';

abstract class HistoryRemoteDataSource {
  /// Fetch all trips (history) for current user as domain entities.
  Future<List<TripEntity>> fetchAll();
}

class HistoryRemoteDataSourceImpl implements HistoryRemoteDataSource {
  final Dio dio;
  final SharedPreferences prefs;

  HistoryRemoteDataSourceImpl(this.dio, this.prefs);

  String _extractDioMessage(DioException e, {required String fallback}) {
    final data = e.response?.data;
    if (data is Map<String, dynamic>) {
      final message = data['message']?.toString();
      if (message != null && message.trim().isNotEmpty) return message;
    }
    return fallback;
  }

  Future<List<TripEntity>> _fetchFromBackend() async {
    final userRaw = prefs.getString('auth_user');
    String id = prefs.getString('auth_user_id') ?? '';
    if (id.isEmpty && userRaw != null && userRaw.isNotEmpty) {
      try {
        final Map<String, dynamic> userMap = jsonDecode(userRaw);
        id = (userMap['uid'] ?? userMap['id'] ?? '').toString();
      } catch (_) {}
    }

    final url = ApiConfig.current.endpoint(ApiConfig.current.perjalananURL);
    try {
      final resp = await dio.get(
        url,
        queryParameters: {'user_id': id, 'limit': 200},
      );
      if (resp.statusCode == 200) {
        final data = resp.data as dynamic;
        final list = <TripEntity>[];
        if (data is List) {
          for (final item in data) {
            try {
              final m = HistoryTripModel.fromJson(
                Map<String, dynamic>.from(item),
              );
              list.add(m.toEntity());
            } catch (_) {}
          }
        } else if (data is Map<String, dynamic> && data.containsKey('data')) {
          final arr = data['data'];
          if (arr is List) {
            for (final item in arr) {
              try {
                final m = HistoryTripModel.fromJson(
                  Map<String, dynamic>.from(item),
                );
                list.add(m.toEntity());
              } catch (_) {}
            }
          }
        }
        return list;
      }

      throw HistoryRemoteException('Gagal memuat riwayat perjalanan');
    } on DioException catch (e) {
      throw HistoryRemoteException(
        _extractDioMessage(e, fallback: 'Gagal memuat riwayat perjalanan'),
      );
    }
  }

  @override
  Future<List<TripEntity>> fetchAll() async {
    return _fetchFromBackend();
  }
}
