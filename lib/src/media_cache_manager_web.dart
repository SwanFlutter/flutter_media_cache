import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'cache_config.dart';

/// Web-specific implementation of media cache manager
class MediaCacheManagerWeb {
  static MediaCacheManagerWeb? _instance;
  static CacheConfig _config = const CacheConfig();

  final Map<String, Uint8List> _memoryCache = {};
  final Map<String, _CacheEntry> _cacheMetadata = {};

  MediaCacheManagerWeb._();

  /// Get singleton instance
  static MediaCacheManagerWeb get instance {
    _instance ??= MediaCacheManagerWeb._();
    return _instance!;
  }

  /// Initialize cache manager with custom configuration
  static Future<void> initialize({CacheConfig? config}) async {
    _config = config ?? const CacheConfig();
    await instance._loadCacheMetadata();
  }

  /// Load cache metadata from localStorage
  Future<void> _loadCacheMetadata() async {
    try {
      debugPrint('Web cache initialized with memory-only storage');
    } catch (e) {
      debugPrint('Error loading cache metadata: $e');
    }
  }

  /// Generate cache key from URL
  String _generateCacheKey(String url) {
    final bytes = utf8.encode(url);
    final digest = md5.convert(bytes);
    return digest.toString();
  }

  /// Check if cache entry is expired
  bool _isExpired(_CacheEntry entry) {
    final now = DateTime.now();
    final difference = now.difference(entry.timestamp);
    return difference > _config.maxCacheDuration;
  }

  /// Download and cache media file
  Future<Uint8List?> _downloadAndCache(String url) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        return response.bodyBytes;
      }
    } catch (e) {
      debugPrint('Error downloading file: $e');
    }
    return null;
  }

  /// Get cached image
  Future<Uint8List?> getImage(String url) async {
    final key = _generateCacheKey(url);

    // Check memory cache first
    if (_memoryCache.containsKey(key)) {
      final entry = _cacheMetadata[key];
      if (entry != null && !_isExpired(entry)) {
        return _memoryCache[key];
      } else {
        _memoryCache.remove(key);
        _cacheMetadata.remove(key);
      }
    }

    // Download and cache
    final bytes = await _downloadAndCache(url);
    if (bytes != null) {
      _addToCache(key, bytes);
      return bytes;
    }

    return null;
  }

  /// Get cached video (returns bytes for web)
  Future<Uint8List?> getVideo(String url) async {
    return getImage(url);
  }

  /// Add to cache with size limit
  void _addToCache(String key, Uint8List bytes) {
    if (_memoryCache.length >= _config.maxMemoryCacheSize) {
      final oldestKey = _cacheMetadata.entries
          .reduce(
            (a, b) => a.value.timestamp.isBefore(b.value.timestamp) ? a : b,
          )
          .key;
      _memoryCache.remove(oldestKey);
      _cacheMetadata.remove(oldestKey);
    }

    _memoryCache[key] = bytes;
    _cacheMetadata[key] = _CacheEntry(
      key: key,
      timestamp: DateTime.now(),
      size: bytes.length,
    );
  }

  /// Clear all cache
  Future<void> clearCache() async {
    _memoryCache.clear();
    _cacheMetadata.clear();
    debugPrint('Web cache cleared');
  }

  /// Clear expired cache files
  Future<void> clearExpiredCache() async {
    final expiredKeys = <String>[];

    for (final entry in _cacheMetadata.entries) {
      if (_isExpired(entry.value)) {
        expiredKeys.add(entry.key);
      }
    }

    for (final key in expiredKeys) {
      _memoryCache.remove(key);
      _cacheMetadata.remove(key);
    }

    debugPrint('Cleared ${expiredKeys.length} expired entries');
  }

  /// Get cache size in bytes
  Future<int> getCacheSize() async {
    int totalSize = 0;
    for (final entry in _cacheMetadata.values) {
      totalSize += entry.size;
    }
    return totalSize;
  }
}

/// Cache entry metadata
class _CacheEntry {
  final String key;
  final DateTime timestamp;
  final int size;

  _CacheEntry({required this.key, required this.timestamp, required this.size});
}
