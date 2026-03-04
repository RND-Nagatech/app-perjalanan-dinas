import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/constan/constan.dart';
import '../../../home_page/data/models/trip_model.dart';

abstract class PerjalananRemoteDataSource {
  Stream<List<TripModel>> getPerjalananForCurrentUser();
  Future<void> refresh();
  Future<void> clearCache();
}

class PerjalananRemoteDataSourceImpl implements PerjalananRemoteDataSource {
  final Dio dio;
  final SharedPreferences prefs;

  List<TripModel>? _cache;
  String? _cacheUserId;
  bool _loading = false;
  StreamController<List<TripModel>>? _controller;

  PerjalananRemoteDataSourceImpl(this.dio, this.prefs);

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

  Future<List<TripModel>> _fetch() async {
    final userId = _getUserId();
    final url = ApiConfig.current.endpoint(ApiConfig.current.perjalananURL);
    final resp = await dio.get(
      url,
      queryParameters: {'user_id': userId, 'limit': 100},
    );
    if (resp.statusCode == 200) {
      final data = resp.data;
      final list = <TripModel>[];
      if (data is List) {
        for (final item in data) {
          try {
            list.add(TripModel.fromJson(Map<String, dynamic>.from(item)));
          } catch (_) {}
        }
      } else if (data is Map && data.containsKey('data')) {
        final arr = data['data'];
        if (arr is List) {
          for (final item in arr) {
            try {
              list.add(TripModel.fromJson(Map<String, dynamic>.from(item)));
            } catch (_) {}
          }
        }
      }
      _cacheUserId = userId;
      return list;
    }
    throw Exception('Failed to fetch perjalanan');
  }

  void _ensureController() {
    if (_controller != null) return;
    _controller = StreamController<List<TripModel>>.broadcast(
      onListen: () {
        if (_cache != null) {
          final current = _getUserId();
          if (_cacheUserId != null && _cacheUserId != current) {
            _loadAndAdd();
            return;
          }
          _controller?.add(_cache!);
          return;
        }
        _loadAndAdd();
      },
    );
  }

  Future<void> _loadAndAdd() async {
    if (_loading) return;
    _loading = true;
    try {
      final list = await _fetch();
      _cache = list;
      if (!(_controller?.isClosed ?? true)) _controller?.add(list);
    } catch (e) {
      if (!(_controller?.isClosed ?? true)) _controller?.addError(e);
    } finally {
      _loading = false;
    }
  }

  @override
  Stream<List<TripModel>> getPerjalananForCurrentUser() {
    _ensureController();
    return _controller!.stream;
  }

  @override
  Future<void> refresh() async {
    await _loadAndAdd();
  }

  @override
  Future<void> clearCache() async {
    _cache = null;
    _cacheUserId = null;
    if (!(_controller?.isClosed ?? true)) _controller?.add(<TripModel>[]);
  }
}
