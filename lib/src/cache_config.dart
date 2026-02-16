/// Configuration class for media cache settings
class CacheConfig {
  /// Maximum cache duration before files expire
  final Duration maxCacheDuration;

  /// Maximum cache size in bytes (default: 100MB)
  final int maxCacheSize;

  /// Whether to use memory cache
  final bool useMemoryCache;

  /// Maximum number of items in memory cache
  final int maxMemoryCacheSize;

  const CacheConfig({
    this.maxCacheDuration = const Duration(days: 7),
    this.maxCacheSize = 100 * 1024 * 1024, // 100MB
    this.useMemoryCache = true,
    this.maxMemoryCacheSize = 100,
  });

  CacheConfig copyWith({
    Duration? maxCacheDuration,
    int? maxCacheSize,
    bool? useMemoryCache,
    int? maxMemoryCacheSize,
  }) {
    return CacheConfig(
      maxCacheDuration: maxCacheDuration ?? this.maxCacheDuration,
      maxCacheSize: maxCacheSize ?? this.maxCacheSize,
      useMemoryCache: useMemoryCache ?? this.useMemoryCache,
      maxMemoryCacheSize: maxMemoryCacheSize ?? this.maxMemoryCacheSize,
    );
  }
}
