// lib/src/storage/cache_index.dart
//
// NOTE: This file intentionally avoids dart:io imports.
// Disk persistence is delegated to PlatformStorage (platform_file.dart).

import 'dart:convert';
import 'dart:typed_data';

import '../core/exceptions.dart';
import '../core/models.dart';

/// Persistent LRU index stored as a JSON file alongside cached media files.
///
/// Responsibilities:
///   - Map URL → [CacheEntry] (O(1) lookup).
///   - Enforce max-disk-bytes limit via LRU eviction.
///   - Persist to / restore from disk atomically (no-op on web).
class CacheIndex {
  CacheIndex({required this.maxDiskBytes});

  final int maxDiskBytes;

  // Access-ordered map: tail = MRU, head = LRU.
  final _entries = <String, CacheEntry>{};

  int _totalBytes = 0;
  int get totalBytes => _totalBytes;
  int get totalEntries => _entries.length;

  // ── Public API ─────────────────────────────────────────────────────────────

  CacheEntry? get(String key) {
    final entry = _entries.remove(key);
    if (entry == null) return null;
    final updated = entry.copyWithAccess();
    _entries[key] = updated; // re-insert at tail = MRU
    return updated;
  }

  void put(CacheEntry entry) {
    final existing = _entries.remove(entry.key);
    if (existing != null) _totalBytes -= existing.sizeBytes;

    _entries[entry.key] = entry;
    _totalBytes += entry.sizeBytes;
  }

  void remove(String key) {
    final entry = _entries.remove(key);
    if (entry != null) _totalBytes -= entry.sizeBytes;
  }

  bool containsKey(String key) => _entries.containsKey(key);

  List<CacheEntry> get allEntries => List.unmodifiable(_entries.values);

  /// Evicts LRU entries until total disk usage is below [maxDiskBytes].
  /// Returns the list of local paths that should be deleted.
  List<String> evictToLimit() {
    final evicted = <String>[];
    while (_totalBytes > maxDiskBytes && _entries.isNotEmpty) {
      final lruKey = _entries.keys.first;
      final entry = _entries.remove(lruKey)!;
      _totalBytes -= entry.sizeBytes;
      evicted.add(entry.localPath);
    }
    return evicted;
  }

  /// Removes all entries whose [CacheEntry.isExpired] returns true.
  List<String> removeExpired(Duration maxAge) {
    final expiredPaths = <String>[];
    final expiredKeys = _entries.entries
        .where((e) => e.value.isExpired(maxAge))
        .map((e) => e.key)
        .toList();

    for (final key in expiredKeys) {
      final entry = _entries.remove(key)!;
      _totalBytes -= entry.sizeBytes;
      expiredPaths.add(entry.localPath);
    }
    return expiredPaths;
  }

  void clear() {
    _entries.clear();
    _totalBytes = 0;
  }

  // ── Persistence (raw bytes, platform-agnostic) ─────────────────────────────

  /// Deserialises the index from a JSON [Uint8List].
  /// Pass the raw bytes that [PlatformStorage.read] returned.
  void loadFromBytes(Uint8List data) {
    try {
      final raw = utf8.decode(data);
      final List<dynamic> list = jsonDecode(raw) as List<dynamic>;
      for (final item in list) {
        final entry = CacheEntry.fromJson(item as Map<String, dynamic>);
        _entries[entry.key] = entry;
        _totalBytes += entry.sizeBytes;
      }
    } catch (_) {
      // Corrupt index — start fresh.
      _entries.clear();
      _totalBytes = 0;
    }
  }

  /// Serialises the index to a JSON [Uint8List] suitable for
  /// [PlatformStorage.write].
  Uint8List toBytes() {
    try {
      final json = jsonEncode(_entries.values.map((e) => e.toJson()).toList());
      return Uint8List.fromList(utf8.encode(json));
    } catch (e) {
      throw StorageException('Failed to serialise cache index', cause: e);
    }
  }
}
