import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider_master/path_provider_master.dart';

import 'cache_config.dart';

/// IO (Native) implementation of media cache manager
class MediaCacheManagerIO {
  static MediaCacheManagerIO? _instance;
  static CacheConfig _config = const CacheConfig();

  final Map<String, Uint8List> _memoryCache = {};
  Directory? _cacheDirectory;

  MediaCacheManagerIO._();

  /// Get singleton instance
  static MediaCacheManagerIO get instance {
    _instance ??= MediaCacheManagerIO._();
    return _instance!;
  }

  /// Initialize cache manager with custom configuration
  static Future<void> initialize({CacheConfig? config}) async {
    _config = config ?? const CacheConfig();
    await instance._initCacheDirectory();
  }

  /// Initialize cache directory
  Future<void> _initCacheDirectory() async {
    try {
      final tempDir = await PathProviderMaster.getTemporaryDirectory();
      if (tempDir != null) {
        _cacheDirectory = Directory('${tempDir.path}/media_cache');
        if (!await _cacheDirectory!.exists()) {
          await _cacheDirectory!.create(recursive: true);
        }
      }
    } catch (e) {
      debugPrint('Error initializing cache directory: $e');
    }
  }

  /// Generate cache key from URL
  String _generateCacheKey(String url) {
    final bytes = utf8.encode(url);
    final digest = md5.convert(bytes);
    return digest.toString();
  }

  /// Get cached file path
  String? _getCacheFilePath(String url, {bool isVideo = false}) {
    if (_cacheDirectory == null) return null;
    final key = _generateCacheKey(url);
    final extension = isVideo ? 'mp4' : 'jpg';
    return '${_cacheDirectory!.path}/$key.$extension';
  }

  /// Check if file is expired
  bool _isFileExpired(File file) {
    try {
      final lastModified = file.lastModifiedSync();
      final now = DateTime.now();
      final difference = now.difference(lastModified);
      return difference > _config.maxCacheDuration;
    } catch (e) {
      return true;
    }
  }

  /// Download and cache media file
  Future<File?> _downloadAndCache(String url, String filePath) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final file = File(filePath);
        await file.writeAsBytes(response.bodyBytes);
        return file;
      }
    } catch (e) {
      debugPrint('Error downloading file: $e');
    }
    return null;
  }

  /// Get cached image
  Future<Uint8List?> getImage(String url) async {
    // Check memory cache first
    if (_config.useMemoryCache && _memoryCache.containsKey(url)) {
      return _memoryCache[url];
    }

    // Check disk cache
    final filePath = _getCacheFilePath(url, isVideo: false);
    if (filePath != null) {
      final file = File(filePath);
      if (await file.exists() && !_isFileExpired(file)) {
        final bytes = await file.readAsBytes();

        // Add to memory cache
        if (_config.useMemoryCache) {
          _addToMemoryCache(url, bytes);
        }

        return bytes;
      }
    }

    // Download and cache
    if (filePath != null) {
      final file = await _downloadAndCache(url, filePath);
      if (file != null) {
        final bytes = await file.readAsBytes();

        // Add to memory cache
        if (_config.useMemoryCache) {
          _addToMemoryCache(url, bytes);
        }

        return bytes;
      }
    }

    return null;
  }

  /// Get cached video file
  Future<File?> getVideo(String url) async {
    final filePath = _getCacheFilePath(url, isVideo: true);
    if (filePath != null) {
      final file = File(filePath);
      if (await file.exists() && !_isFileExpired(file)) {
        return file;
      }

      // Download and cache
      return await _downloadAndCache(url, filePath);
    }
    return null;
  }

  /// Add to memory cache with size limit
  void _addToMemoryCache(String url, Uint8List bytes) {
    if (_memoryCache.length >= _config.maxMemoryCacheSize) {
      // Remove oldest entry
      final firstKey = _memoryCache.keys.first;
      _memoryCache.remove(firstKey);
    }
    _memoryCache[url] = bytes;
  }

  /// Clear all cache
  Future<void> clearCache() async {
    // Clear memory cache
    _memoryCache.clear();

    // Clear disk cache
    if (_cacheDirectory != null && await _cacheDirectory!.exists()) {
      try {
        await _cacheDirectory!.delete(recursive: true);
        await _cacheDirectory!.create(recursive: true);
      } catch (e) {
        debugPrint('Error clearing cache: $e');
      }
    }
  }

  /// Clear expired cache files
  Future<void> clearExpiredCache() async {
    if (_cacheDirectory == null || !await _cacheDirectory!.exists()) return;

    try {
      final files = _cacheDirectory!.listSync();
      for (var entity in files) {
        if (entity is File && _isFileExpired(entity)) {
          await entity.delete();
        }
      }
    } catch (e) {
      debugPrint('Error clearing expired cache: $e');
    }
  }

  /// Get cache size in bytes
  Future<int> getCacheSize() async {
    if (_cacheDirectory == null || !await _cacheDirectory!.exists()) return 0;

    int totalSize = 0;
    try {
      final files = _cacheDirectory!.listSync(recursive: true);
      for (var entity in files) {
        if (entity is File) {
          totalSize += await entity.length();
        }
      }
    } catch (e) {
      debugPrint('Error calculating cache size: $e');
    }
    return totalSize;
  }
}
