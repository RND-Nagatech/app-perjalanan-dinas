import 'dart:async';

typedef RefreshCallback = Future<void> Function();

class RefreshCoordinator {
  RefreshCoordinator._();

  static final RefreshCoordinator instance = RefreshCoordinator._();

  final Map<String, RefreshCallback> _callbacks = {};

  void register(String key, RefreshCallback cb) {
    _callbacks[key] = cb;
  }

  void unregister(String key) {
    _callbacks.remove(key);
  }

  /// Call all registered refresh callbacks in parallel and return when all complete.
  Future<void> refreshAll({Duration? timeout}) async {
    final futures = <Future<void>>[];
    for (final cb in _callbacks.values) {
      try {
        futures.add(cb());
      } catch (_) {
        // ignore individual registration errors
      }
    }
    if (futures.isEmpty) return;
    if (timeout != null) {
      await Future.wait(futures).timeout(timeout, onTimeout: () => <void>[]);
    } else {
      await Future.wait(futures);
    }
  }
}
