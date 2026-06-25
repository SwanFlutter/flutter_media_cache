// lib/src/storage/lru_memory_cache.dart

import 'dart:collection';
import 'dart:typed_data';

/// A thread-safe (single-isolate) LRU memory cache backed by [LinkedHashMap].
///
/// Access order is maintained: the most-recently-used item is always at the
/// tail. When capacity is exceeded the least-recently-used item is evicted.
class LruMemoryCache {
  LruMemoryCache({required this.maxItems});

  final int maxItems;

  // LinkedHashMap preserves insertion order; we treat it as access order by
  // removing and re-inserting on every get/put.
  final _store = <String, _MemoryEntry>{};

  int get length => _store.length;
  int get totalBytes => _store.values.fold(0, (s, e) => s + e.bytes.length);

  /// Returns cached bytes or null (cache miss).
  Uint8List? get(String key) {
    final entry = _store.remove(key);
    if (entry == null) return null;
    // Re-insert at tail = mark as most-recently-used.
    entry._touches++;
    _store[key] = entry;
    return entry.bytes;
  }

  /// Stores [bytes] under [key], evicting LRU entries if needed.
  void put(String key, Uint8List bytes) {
    _store.remove(key); // ensure tail insertion even on update
    _store[key] = _MemoryEntry(bytes);
    _evictIfNeeded();
  }

  /// Removes a specific key.
  void remove(String key) => _store.remove(key);

  /// Drops everything.
  void clear() => _store.clear();

  bool containsKey(String key) => _store.containsKey(key);

  void _evictIfNeeded() {
    while (_store.length > maxItems) {
      // First entry = least-recently-used.
      _store.remove(_store.keys.first);
    }
  }
}

class _MemoryEntry {
  _MemoryEntry(this.bytes);
  final Uint8List bytes;
  int _touches = 1;
  int get touches => _touches;
}
