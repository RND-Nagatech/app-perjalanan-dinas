import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;

import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/trip_model.dart';
import '../../../../core/constan/constan.dart';

abstract class HomeRemoteDataSource {
  Stream<List<TripModel>> getTrips();
  Stream<List<TripModel>> getTodayTrips();
  Future<void> refresh();

  /// Clear any cached results and notify listeners.
  Future<void> clearCache();
}

class HomeRemoteDataSourceImpl implements HomeRemoteDataSource {
  final Dio dio;
  final SharedPreferences prefs;

  // Single broadcast stream controller to share fetched trips across consumers.
  StreamController<List<TripModel>>? _controller;
  bool _loading = false;
  // Cache last fetched list so late subscribers get the most recent value.
  List<TripModel>? _last;
  // Track which user id this cached data belongs to so we can detect user switches.
  String? _lastUserId;

  HomeRemoteDataSourceImpl(this.dio, this.prefs);

  Future<List<TripModel>> _fetchTrips() async {
    // Try to read user id from prefs. AuthRepository saves user JSON under 'auth_user'.
    final userRaw = prefs.getString('auth_user');
    String id = prefs.getString('auth_user_id') ?? '';

    // If 'auth_user_id' not set, try parsing 'auth_user' JSON
    if (id.isEmpty && userRaw != null && userRaw.isNotEmpty) {
      try {
        final Map<String, dynamic> userMap = jsonDecode(userRaw);
        id = (userMap['uid'] ?? userMap['id'] ?? '').toString();
      } catch (e) {
        id = '';
      }
    }

    //Ambil data perjalanan by id
    final url = ApiConfig.current.endpoint(ApiConfig.current.perjalananURL);

    final resp = await dio.get(
      url,
      queryParameters: {'user_id': id, 'limit': 50},
    );
    if (resp.statusCode == 200) {
      final data = resp.data as dynamic;
      final list = <TripModel>[];
      // If backend returns meta like total_inject / sisa_dana / total_transaksi,
      // persist them into SharedPreferences for repository/usecase access.
      try {
        if (data is Map<String, dynamic>) {
          // top-level keys
          void tryPersist(String key, dynamic val) {
            if (val == null) {
              return;
            }
            try {
              if (val is int) {
                prefs.setInt(key, val);
              } else if (val is String) {
                final parsed = int.tryParse(
                  val.replaceAll(RegExp(r'[^0-9]'), ''),
                );
                if (parsed != null) {
                  prefs.setInt(key, parsed);
                }
              }
              // ignore: empty_catches
            } catch (e) {}
          }

          tryPersist('home_total_inject', data['total_inject']);
          tryPersist('home_sisa_dana', data['sisa_dana']);
          tryPersist('home_total_transaksi', data['total_transaksi']);

          // if response contains 'data' array, inspect first item for summary
          if (data.containsKey('data') && data['data'] is List) {
            final dataArr = data['data'] as List;
            if (dataArr.isEmpty) {
              // backend returned an empty list; clear any previously persisted
              // totals so UI doesn't show stale values from SharedPreferences.
              try {
                prefs.setInt('home_total_inject', 0);
                prefs.setInt('home_sisa_dana', 0);
                prefs.setInt('home_total_transaksi', 0);
              } catch (_) {}
            }
            if (dataArr.isNotEmpty) {
              final first = Map<String, dynamic>.from(dataArr.first);
              final summary = (first['summary'] is Map)
                  ? Map<String, dynamic>.from(first['summary'])
                  : <String, dynamic>{};
              tryPersist(
                'home_total_inject',
                first['total_inject'] ?? summary['total_inject'],
              );
              tryPersist(
                'home_sisa_dana',
                first['sisa_dana'] ?? summary['sisa_dana'],
              );
              tryPersist(
                'home_total_transaksi',
                first['total_transaksi'] ?? summary['total_transaksi'],
              );
            }
          }
        }
        // ignore: empty_catches
      } catch (e) {}
      if (data is List) {
        for (final item in data) {
          try {
            TripModel m;
            if (item is Map<String, dynamic>) {
              m = TripModel.fromJson(item);
            } else if (item is Map) {
              m = TripModel.fromJson(Map<String, dynamic>.from(item));
            } else {
              throw Exception('Unexpected item type');
            }
            developer.log(
              'HomeRemoteDataSource: parsed item kode=${m.name} status=${m.status}',
              name: 'HomeRemoteDataSource',
            );
            list.add(m);
          } catch (e) {
            // skip malformed item but continue
            developer.log(
              'HomeRemoteDataSource: skip item due parse error: $e',
              name: 'HomeRemoteDataSource',
              level: 900,
            );
          }
        }
      } else if (data is Map<String, dynamic> && data.containsKey('data')) {
        final arr = data['data'];
        if (arr is List) {
          for (final item in arr) {
            try {
              final m = TripModel.fromJson(Map<String, dynamic>.from(item));
              developer.log(
                'HomeRemoteDataSource: parsed data[] kode=${m.name} status=${m.status}',
                name: 'HomeRemoteDataSource',
              );
              list.add(m);
            } catch (e) {
              // skip malformed item
              developer.log(
                'HomeRemoteDataSource: skip data[] item due parse error: $e',
                name: 'HomeRemoteDataSource',
                level: 900,
              );
            }
          }
        }
      }
      // remember which user this result belongs to
      try {
        _lastUserId = id;
      } catch (_) {}
      return list;
    }

    throw Exception('Failed to load trips');
  }

  String _getCurrentUserIdFromPrefs() {
    final userRaw = prefs.getString('auth_user');
    var id = prefs.getString('auth_user_id') ?? '';
    if (id.isEmpty && userRaw != null && userRaw.isNotEmpty) {
      try {
        final Map<String, dynamic> userMap = jsonDecode(userRaw);
        id = (userMap['uid'] ?? userMap['id'] ?? '').toString();
      } catch (e) {
        id = '';
      }
    }
    return id;
  }

  @override
  Stream<List<TripModel>> getTrips() {
    _ensureController();
    return _controller!.stream;
  }

  @override
  Stream<List<TripModel>> getTodayTrips() {
    _ensureController();
    return _controller!.stream.map((list) {
      final now = DateTime.now();
      final start = DateTime(now.year, now.month, now.day);
      final end = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);
      return list.where((t) {
        final df = t.dateFrom;
        if (df == null) return false;
        return df.isAfter(start.subtract(const Duration(milliseconds: 1))) &&
            df.isBefore(end.add(const Duration(milliseconds: 1)));
      }).toList();
    });
  }

  void _ensureController() {
    if (_controller != null) return;
    _controller = StreamController<List<TripModel>>.broadcast(
      onListen: () {
        // If we already have a cached result, decide whether to replay it or reload
        if (_last != null && !(_controller?.isClosed ?? true)) {
          final currentId = _getCurrentUserIdFromPrefs();
          if (_lastUserId != null && _lastUserId != currentId) {
            // user changed — force reload instead of replaying old cache
            developer.log(
              'HomeRemoteDataSource: onListen - user changed (last=$_lastUserId current=$currentId), reloading',
              name: 'HomeRemoteDataSource',
            );
            _loadAndAdd();
            return;
          }
          // same user — replay cached list
          developer.log(
            'HomeRemoteDataSource: onListen - replaying ${_last!.length} items',
            name: 'HomeRemoteDataSource',
          );
          _controller?.add(_last!);
        }
      },
    );
    // load once and add to controller
    _loadAndAdd();
  }

  Future<void> _loadAndAdd() async {
    if (_loading) return;
    _loading = true;
    try {
      final list = await _fetchTrips();
      // cache result so future subscribers can get it
      _last = list;
      if (!(_controller?.isClosed ?? true)) {
        developer.log(
          'HomeRemoteDataSource: adding ${list.length} items to controller',
          name: 'HomeRemoteDataSource',
        );
        _controller?.add(list);
      }
    } catch (e) {
      if (!(_controller?.isClosed ?? true)) {
        _controller?.addError(e);
      }
    } finally {
      _loading = false;
    }
  }

  @override
  Future<void> refresh() async {
    // Force a reload from backend and push to controller
    try {
      developer.log(
        'HomeRemoteDataSource: refresh requested',
        name: 'HomeRemoteDataSource',
      );
      // allow concurrent refresh if not already loading
      if (_loading) return;
      await _loadAndAdd();
    } catch (e) {
      developer.log(
        'HomeRemoteDataSource: refresh error $e',
        name: 'HomeRemoteDataSource',
        level: 900,
      );
      rethrow;
    }
  }

  @override
  Future<void> clearCache() async {
    try {
      _last = null;
      _lastUserId = null;
      if (!(_controller?.isClosed ?? true)) {
        // push empty list so UI updates immediately after logout
        _controller?.add(<TripModel>[]);
      }
    } catch (_) {}
  }
}
