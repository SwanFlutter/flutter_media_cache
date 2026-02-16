import 'package:flutter/foundation.dart';

import 'cache_config.dart';
// Import both implementations
import 'media_cache_manager_io.dart';
import 'media_cache_manager_web.dart';

/// Main cache manager for handling image and video caching
/// Automatically uses the correct implementation based on platform
class MediaCacheManager {
  static MediaCacheManager? _instance;

  MediaCacheManager._();

  /// Get singleton instance
  static MediaCacheManager get instance {
    _instance ??= MediaCacheManager._();
    return _instance!;
  }

  /// Initialize cache manager with custom configuration
  static Future<void> initialize({CacheConfig? config}) async {
    if (kIsWeb) {
      await MediaCacheManagerWeb.initialize(config: config);
    } else {
      await MediaCacheManagerIO.initialize(config: config);
    }
  }

  /// Get cached image
  Future<Uint8List?> getImage(String url) async {
    if (kIsWeb) {
      return MediaCacheManagerWeb.instance.getImage(url);
    } else {
      return MediaCacheManagerIO.instance.getImage(url);
    }
  }

  /// Get cached video file (returns File on native, Uint8List on web)
  Future<dynamic> getVideo(String url) async {
    if (kIsWeb) {
      return MediaCacheManagerWeb.instance.getVideo(url);
    } else {
      return MediaCacheManagerIO.instance.getVideo(url);
    }
  }

  /// Clear all cache
  Future<void> clearCache() async {
    if (kIsWeb) {
      await MediaCacheManagerWeb.instance.clearCache();
    } else {
      await MediaCacheManagerIO.instance.clearCache();
    }
  }

  /// Clear expired cache files
  Future<void> clearExpiredCache() async {
    if (kIsWeb) {
      await MediaCacheManagerWeb.instance.clearExpiredCache();
    } else {
      await MediaCacheManagerIO.instance.clearExpiredCache();
    }
  }

  /// Get cache size in bytes
  Future<int> getCacheSize() async {
    if (kIsWeb) {
      return MediaCacheManagerWeb.instance.getCacheSize();
    } else {
      return MediaCacheManagerIO.instance.getCacheSize();
    }
  }

  /// Format bytes to human readable string
  static String formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(2)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }
}
