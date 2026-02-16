import 'package:flutter_media_cache/flutter_media_cache.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CacheConfig', () {
    test('creates config with default values', () {
      const config = CacheConfig();

      expect(config.maxCacheDuration, const Duration(days: 7));
      expect(config.maxCacheSize, 100 * 1024 * 1024);
      expect(config.useMemoryCache, true);
      expect(config.maxMemoryCacheSize, 100);
    });

    test('creates config with custom values', () {
      const config = CacheConfig(
        maxCacheDuration: Duration(days: 30),
        maxCacheSize: 200 * 1024 * 1024,
        useMemoryCache: false,
        maxMemoryCacheSize: 50,
      );

      expect(config.maxCacheDuration, const Duration(days: 30));
      expect(config.maxCacheSize, 200 * 1024 * 1024);
      expect(config.useMemoryCache, false);
      expect(config.maxMemoryCacheSize, 50);
    });

    test('copyWith creates new config with updated values', () {
      const config = CacheConfig();
      final newConfig = config.copyWith(
        maxCacheDuration: const Duration(days: 14),
      );

      expect(newConfig.maxCacheDuration, const Duration(days: 14));
      expect(newConfig.maxCacheSize, config.maxCacheSize);
      expect(newConfig.useMemoryCache, config.useMemoryCache);
    });
  });

  group('MediaCacheManager', () {
    test('formatBytes formats correctly', () {
      expect(MediaCacheManager.formatBytes(500), '500 B');
      expect(MediaCacheManager.formatBytes(1024), '1.00 KB');
      expect(MediaCacheManager.formatBytes(1024 * 1024), '1.00 MB');
      expect(MediaCacheManager.formatBytes(1024 * 1024 * 1024), '1.00 GB');
    });

    test('instance returns singleton', () {
      final instance1 = MediaCacheManager.instance;
      final instance2 = MediaCacheManager.instance;

      expect(instance1, same(instance2));
    });
  });
}
