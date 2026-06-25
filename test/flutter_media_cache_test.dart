// test/flutter_media_cache_test.dart

import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_media_cache/flutter_media_cache.dart';
import 'package:flutter_media_cache/src/storage/lru_memory_cache.dart';
import 'package:flutter_media_cache/src/storage/cache_index.dart';

// ── Mocks ──────────────────────────────────────────────────────────────────

// ── Helpers ────────────────────────────────────────────────────────────────

Uint8List _bytes(int size) => Uint8List.fromList(List.generate(size, (i) => i));

CacheEntry _entry({
  String url = 'https://example.com/image.jpg',
  String key = 'abc123',
  int size = 1024,
  DateTime? createdAt,
}) => CacheEntry(
  url: url,
  key: key,
  localPath: '/tmp/$key.jpg',
  mediaType: MediaType.image,
  createdAt: createdAt ?? DateTime.now(),
  lastAccessedAt: DateTime.now(),
  sizeBytes: size,
);

// ══════════════════════════════════════════════════════════════════════════════
// Tests
// ══════════════════════════════════════════════════════════════════════════════

void main() {
  // ── KeyGenerator ──────────────────────────────────────────────────────────
  group('KeyGenerator', () {
    test('produces consistent 64-char hex key', () {
      const url = 'https://example.com/photo.jpg';
      final key1 = KeyGenerator.fromUrl(url);
      final key2 = KeyGenerator.fromUrl(url);

      expect(key1, equals(key2));
      expect(key1.length, 64);
      expect(RegExp(r'^[0-9a-f]+$').hasMatch(key1), isTrue);
    });

    test('different URLs produce different keys', () {
      final key1 = KeyGenerator.fromUrl('https://example.com/a.jpg');
      final key2 = KeyGenerator.fromUrl('https://example.com/b.jpg');
      expect(key1, isNot(equals(key2)));
    });

    test('ignores leading/trailing whitespace', () {
      final key1 = KeyGenerator.fromUrl('https://example.com/a.jpg');
      final key2 = KeyGenerator.fromUrl('  https://example.com/a.jpg  ');
      expect(key1, equals(key2));
    });

    group('mediaTypeOf', () {
      test('detects image from URL', () {
        expect(
          KeyGenerator.mediaTypeOf('https://x.com/photo.png'),
          MediaType.image,
        );
      });

      test('detects video from URL', () {
        expect(
          KeyGenerator.mediaTypeOf('https://x.com/video.mp4'),
          MediaType.video,
        );
      });

      test('detects image from Content-Type header', () {
        expect(
          KeyGenerator.mediaTypeOf(
            'https://x.com/asset',
            contentType: 'image/webp',
          ),
          MediaType.image,
        );
      });

      test('falls back to unknown', () {
        expect(
          KeyGenerator.mediaTypeOf('https://x.com/file.pdf'),
          MediaType.unknown,
        );
      });
    });
  });

  // ── LruMemoryCache ────────────────────────────────────────────────────────
  group('LruMemoryCache', () {
    test('stores and retrieves bytes', () {
      final cache = LruMemoryCache(maxItems: 10);
      final data = _bytes(100);
      cache.put('k1', data);
      expect(cache.get('k1'), equals(data));
    });

    test('returns null for missing key', () {
      final cache = LruMemoryCache(maxItems: 10);
      expect(cache.get('missing'), isNull);
    });

    test('evicts LRU item when capacity exceeded', () {
      final cache = LruMemoryCache(maxItems: 3);
      cache.put('k1', _bytes(10));
      cache.put('k2', _bytes(10));
      cache.put('k3', _bytes(10));

      // Access k1 to make it MRU.
      cache.get('k1');

      // Adding k4 should evict k2 (LRU).
      cache.put('k4', _bytes(10));

      expect(cache.get('k2'), isNull); // evicted
      expect(cache.get('k1'), isNotNull); // still present (accessed recently)
      expect(cache.get('k3'), isNotNull);
      expect(cache.get('k4'), isNotNull);
    });

    test('length never exceeds maxItems', () {
      final cache = LruMemoryCache(maxItems: 5);
      for (var i = 0; i < 20; i++) {
        cache.put('key$i', _bytes(8));
      }
      expect(cache.length, lessThanOrEqualTo(5));
    });

    test('clear empties the cache', () {
      final cache = LruMemoryCache(maxItems: 10);
      cache.put('k1', _bytes(10));
      cache.put('k2', _bytes(10));
      cache.clear();
      expect(cache.length, 0);
      expect(cache.get('k1'), isNull);
    });

    test('remove deletes specific key', () {
      final cache = LruMemoryCache(maxItems: 10);
      cache.put('k1', _bytes(10));
      cache.put('k2', _bytes(10));
      cache.remove('k1');
      expect(cache.get('k1'), isNull);
      expect(cache.get('k2'), isNotNull);
    });

    test('tracks totalBytes', () {
      final cache = LruMemoryCache(maxItems: 10);
      cache.put('k1', _bytes(100));
      cache.put('k2', _bytes(200));
      expect(cache.totalBytes, 300);
    });
  });

  // ── CacheIndex ────────────────────────────────────────────────────────────
  group('CacheIndex', () {
    test('put and get returns entry', () {
      final index = CacheIndex(maxDiskBytes: 10 * 1024 * 1024);
      final entry = _entry(key: 'key1', size: 512);
      index.put(entry);
      expect(index.get('key1'), isNotNull);
    });

    test('tracks totalBytes correctly', () {
      final index = CacheIndex(maxDiskBytes: 10 * 1024 * 1024);
      index.put(_entry(key: 'k1', size: 100));
      index.put(_entry(key: 'k2', size: 200));
      expect(index.totalBytes, 300);
    });

    test('updates totalBytes on remove', () {
      final index = CacheIndex(maxDiskBytes: 10 * 1024 * 1024);
      index.put(_entry(key: 'k1', size: 100));
      index.put(_entry(key: 'k2', size: 200));
      index.remove('k1');
      expect(index.totalBytes, 200);
    });

    test('evictToLimit removes LRU entries', () {
      final index = CacheIndex(maxDiskBytes: 250); // 250 bytes max
      index.put(_entry(key: 'k1', size: 100));
      index.put(_entry(key: 'k2', size: 100));
      index.put(_entry(key: 'k3', size: 100));

      // Now at 300 bytes — 50 over limit.
      final evicted = index.evictToLimit();

      expect(evicted.length, greaterThan(0));
      expect(index.totalBytes, lessThanOrEqualTo(250));
    });

    test('removeExpired clears stale entries', () {
      final old = _entry(
        key: 'old',
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
      );
      final fresh = _entry(key: 'fresh');

      final index = CacheIndex(maxDiskBytes: 10 * 1024 * 1024);
      index.put(old);
      index.put(fresh);

      final paths = index.removeExpired(const Duration(days: 14));

      expect(paths.length, 1);
      expect(index.containsKey('old'), isFalse);
      expect(index.containsKey('fresh'), isTrue);
    });
  });

  // ── CacheConfig ───────────────────────────────────────────────────────────
  group('CacheConfig', () {
    test('default values are reasonable', () {
      const config = CacheConfig();
      expect(config.maxDiskBytes, greaterThan(0));
      expect(config.maxConcurrentDownloads, greaterThan(0));
      expect(config.maxRetries, greaterThan(0));
    });

    test('retryDelay grows exponentially', () {
      const config = CacheConfig(retryBaseDelay: Duration(milliseconds: 100));
      final d0 = config.retryDelay(0).inMilliseconds;
      final d1 = config.retryDelay(1).inMilliseconds;
      final d2 = config.retryDelay(2).inMilliseconds;

      // Each should be roughly double the previous (allowing for jitter).
      expect(d1, greaterThan(d0));
      expect(d2, greaterThan(d1));
    });

    test('copyWith overrides individual fields', () {
      const base = CacheConfig(maxRetries: 3);
      final updated = base.copyWith(maxRetries: 10);
      expect(updated.maxRetries, 10);
      expect(updated.maxDiskBytes, base.maxDiskBytes);
    });
  });

  // ── CacheEntry ────────────────────────────────────────────────────────────
  group('CacheEntry', () {
    test('serializes and deserializes correctly', () {
      final original = _entry();
      final json = original.toJson();
      final restored = CacheEntry.fromJson(json);

      expect(restored.url, original.url);
      expect(restored.key, original.key);
      expect(restored.sizeBytes, original.sizeBytes);
      expect(restored.mediaType, original.mediaType);
    });

    test('isExpired returns true for old entries', () {
      final old = _entry(
        createdAt: DateTime.now().subtract(const Duration(days: 100)),
      );
      expect(old.isExpired(const Duration(days: 14)), isTrue);
    });

    test('isExpired returns false for fresh entries', () {
      final fresh = _entry(createdAt: DateTime.now());
      expect(fresh.isExpired(const Duration(days: 14)), isFalse);
    });
  });

  // ── DownloadProgress ──────────────────────────────────────────────────────
  group('DownloadProgress', () {
    test('progress is null when totalBytes is unknown', () {
      const p = DownloadProgress(
        url: 'https://x.com',
        status: DownloadStatus.downloading,
        bytesDownloaded: 500,
      );
      expect(p.progress, isNull);
    });

    test('progress is 0.5 when halfway', () {
      const p = DownloadProgress(
        url: 'https://x.com',
        status: DownloadStatus.downloading,
        bytesDownloaded: 500,
        totalBytes: 1000,
      );
      expect(p.progress, closeTo(0.5, 0.001));
    });

    test('isCompleted is true only for completed status', () {
      const completed = DownloadProgress(
        url: 'x',
        status: DownloadStatus.completed,
      );
      const failed = DownloadProgress(url: 'x', status: DownloadStatus.failed);
      expect(completed.isCompleted, isTrue);
      expect(failed.isCompleted, isFalse);
    });
  });
}
