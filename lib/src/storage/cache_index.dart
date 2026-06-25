// lib/src/storage/cache_index.dart

import 'dart:convert';
import 'dart:io';

import '../core/models.dart';
import '../core/exceptions.dart';

/// Persistent LRU index stored as a JSON file alongside cached media files.
///
/// Responsibilities:
///   - Map URL → [CacheEntry] (O(1) lookup).
///   - Enforce max-disk-bytes limit via LRU eviction.
///   - Persist to / restore from disk atomically.
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
  /// Returns the list of file paths that should be deleted.
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

  // ── Persistence ────────────────────────────────────────────────────────────

  Future<void> loadFrom(File indexFile) async {
    if (!await indexFile.exists()) return;
    try {
      final raw = await indexFile.readAsString();
      final List<dynamic> list = jsonDecode(raw) as List<dynamic>;
      for (final item in list) {
        final entry = CacheEntry.fromJson(item as Map<String, dynamic>);
        _entries[entry.key] = entry;
        _totalBytes += entry.sizeBytes;
      }
    } catch (e) {
      // Corrupt index — start fresh. Physical files remain until next eviction.
      _entries.clear();
      _totalBytes = 0;
    }
  }

  Future<void> saveTo(File indexFile) async {
    try {
      final json = jsonEncode(_entries.values.map((e) => e.toJson()).toList());
      // Atomic write via temp file + rename.
      final tmp = File('${indexFile.path}.tmp');
      await tmp.writeAsString(json, flush: true);
      await tmp.rename(indexFile.path);
    } catch (e) {
      throw StorageException('Failed to persist cache index', cause: e);
    }
  }
}
