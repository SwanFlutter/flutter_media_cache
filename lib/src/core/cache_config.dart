// lib/src/core/cache_config.dart

import 'package:flutter/foundation.dart';

/// Comprehensive configuration for [MediaCacheManager].
///
/// All values have sensible production-ready defaults.
///
/// ```dart
/// await MediaCacheManager.initialize(
///   config: CacheConfig(
///     maxDiskBytes: 500 * 1024 * 1024, // 500 MB
///     maxAge: const Duration(days: 30),
///     maxConcurrentDownloads: 6,
///   ),
/// );
/// ```
@immutable
class CacheConfig {
  const CacheConfig({
    this.maxDiskBytes = 200 * 1024 * 1024, // 200 MB
    this.maxMemoryItems = 150,
    this.maxAge = const Duration(days: 14),
    this.maxConcurrentDownloads = 4,
    this.maxRetries = 3,
    this.retryBaseDelay = const Duration(seconds: 1),
    this.downloadTimeout = const Duration(seconds: 30),
    this.connectTimeout = const Duration(seconds: 10),
    this.useMemoryCache = true,
    this.useConditionalGet = true,
    this.subdirectoryName = 'flutter_media_cache',
    this.customHeaders = const {},
    this.allowedExtensions = const {
      '.jpg',
      '.jpeg',
      '.png',
      '.gif',
      '.webp',
      '.bmp',
      '.svg',
      '.mp4',
      '.mov',
      '.avi',
      '.mkv',
      '.webm',
      '.m4v',
    },
  });

  /// Maximum total size of disk cache in bytes.
  final int maxDiskBytes;

  /// Maximum number of items kept in memory (LRU).
  final int maxMemoryItems;

  /// How long a cache entry lives before being treated as stale.
  final Duration maxAge;

  /// Maximum simultaneous HTTP downloads.
  final int maxConcurrentDownloads;

  /// Maximum number of retry attempts on transient failure.
  final int maxRetries;

  /// Base delay for exponential-backoff retries.
  final Duration retryBaseDelay;

  /// Per-download timeout.
  final Duration downloadTimeout;

  /// Initial TCP-connection timeout.
  final Duration connectTimeout;

  /// Whether to keep a fast in-memory LRU on top of disk.
  final bool useMemoryCache;

  /// Whether to send If-None-Match / If-Modified-Since headers.
  final bool useConditionalGet;

  /// Subdirectory inside the system temp/cache folder.
  final String subdirectoryName;

  /// Extra HTTP headers sent with every download request.
  final Map<String, String> customHeaders;

  /// Allowed file extensions; requests for other types are passed through.
  final Set<String> allowedExtensions;

  /// Computes the retry delay for [attempt] (0-based) with jitter.
  Duration retryDelay(int attempt) {
    final base = retryBaseDelay.inMilliseconds * (1 << attempt); // 2^n backoff
    final jitter = (base * 0.2).round();
    return Duration(milliseconds: base + jitter);
  }

  CacheConfig copyWith({
    int? maxDiskBytes,
    int? maxMemoryItems,
    Duration? maxAge,
    int? maxConcurrentDownloads,
    int? maxRetries,
    Duration? retryBaseDelay,
    Duration? downloadTimeout,
    Duration? connectTimeout,
    bool? useMemoryCache,
    bool? useConditionalGet,
    String? subdirectoryName,
    Map<String, String>? customHeaders,
    Set<String>? allowedExtensions,
  }) => CacheConfig(
    maxDiskBytes: maxDiskBytes ?? this.maxDiskBytes,
    maxMemoryItems: maxMemoryItems ?? this.maxMemoryItems,
    maxAge: maxAge ?? this.maxAge,
    maxConcurrentDownloads:
        maxConcurrentDownloads ?? this.maxConcurrentDownloads,
    maxRetries: maxRetries ?? this.maxRetries,
    retryBaseDelay: retryBaseDelay ?? this.retryBaseDelay,
    downloadTimeout: downloadTimeout ?? this.downloadTimeout,
    connectTimeout: connectTimeout ?? this.connectTimeout,
    useMemoryCache: useMemoryCache ?? this.useMemoryCache,
    useConditionalGet: useConditionalGet ?? this.useConditionalGet,
    subdirectoryName: subdirectoryName ?? this.subdirectoryName,
    customHeaders: customHeaders ?? this.customHeaders,
    allowedExtensions: allowedExtensions ?? this.allowedExtensions,
  );
}
