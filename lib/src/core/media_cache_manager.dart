// lib/src/core/media_cache_manager.dart
//
// Cross-platform (Android / iOS / macOS / Windows / Linux / Web) cache manager.
// dart:io is never imported directly here; all file I/O is delegated to
// PlatformStorage so that this file compiles cleanly on the web.

import 'dart:async';

import '../core/cache_config.dart';
import '../core/exceptions.dart';
import '../core/models.dart';
import '../download/download_engine.dart';
import '../platform/platform_file.dart';
import '../storage/cache_index.dart';
import '../storage/lru_memory_cache.dart';
import '../utils/key_generator.dart';

/// The central singleton that orchestrates caching, downloading, and eviction.
///
/// Works on **all** Flutter platforms:
///   - Android / iOS / macOS / Windows / Linux — memory + disk cache.
///   - Web — memory-only cache (disk ops silently skipped).
///
/// ## Initialization
/// ```dart
/// void main() async {
///   WidgetsFlutterBinding.ensureInitialized();
///   await MediaCacheManager.initialize();
///   runApp(MyApp());
/// }
/// ```
///
/// ## Usage
/// ```dart
/// // Simple image fetch
/// final result = await MediaCacheManager.instance.getMedia('https://...');
///
/// // With progress stream
/// final (:result, :progress) =
///     MediaCacheManager.instance.getMediaWithProgress('https://...');
/// progress.listen((p) => print('${p.progress}'));
/// final data = await result;
/// ```
class MediaCacheManager {
  MediaCacheManager._({required CacheConfig config})
    : _config = config,
      _index = CacheIndex(maxDiskBytes: config.maxDiskBytes),
      _memCache = LruMemoryCache(maxItems: config.maxMemoryItems),
      _engine = DownloadEngine(config: config),
      _storage = createPlatformStorage();

  // ── Singleton ──────────────────────────────────────────────────────────────

  static MediaCacheManager? _instance;

  static MediaCacheManager get instance {
    if (_instance == null) throw const NotInitializedException();
    return _instance!;
  }

  static bool get isInitialized => _instance != null;

  /// Initializes the cache manager. Must be called once before any use.
  ///
  /// Safe to call multiple times — subsequent calls are no-ops unless
  /// [force] is true.
  static Future<void> initialize({
    CacheConfig config = const CacheConfig(),
    bool force = false,
  }) async {
    if (_instance != null && !force) return;
    await _instance?.dispose();

    final manager = MediaCacheManager._(config: config);
    await manager._init();
    _instance = manager;
  }

  // ── Internal state ─────────────────────────────────────────────────────────

  final CacheConfig _config;
  final CacheIndex _index;
  final LruMemoryCache _memCache;
  final DownloadEngine _engine;
  final PlatformStorage _storage;

  // Analytics counters.
  int _hitCount = 0;
  int _missCount = 0;
  int _evictionCount = 0;

  bool _disposed = false;

  // Debounce index writes so we don't hit disk on every request.
  Timer? _indexSaveDebounce;

  // ── Initialization ─────────────────────────────────────────────────────────

  Future<void> _init() async {
    await _storage.init(_config.subdirectoryName);

    if (_storage.hasDisk) {
      // Load persisted index from disk (key = '_index', ext = '.json').
      final indexPath = '${_storage.cacheDir}/_index.json';
      final bytes = await _storage.read(indexPath);
      if (bytes != null) {
        _index.loadFromBytes(bytes);
      }
      await _purgeOrphanedFiles();
    }
  }

  // ── Core Public API ────────────────────────────────────────────────────────

  /// Fetches media bytes from memory → disk → network (in that order).
  ///
  /// Throws [DownloadException] on unrecoverable network failure.
  Future<CacheResult> getMedia(
    String url, {
    DownloadPriority priority = DownloadPriority.normal,
  }) async {
    _assertNotDisposed();
    final key = KeyGenerator.fromUrl(url);

    // 1. Memory cache hit
    if (_config.useMemoryCache) {
      final bytes = _memCache.get(key);
      if (bytes != null) {
        _hitCount++;
        final entry = _index.get(key);
        _scheduleSave();
        return CacheResult.hit(
          url: url,
          mediaType: entry?.mediaType ?? MediaType.unknown,
          bytes: bytes,
          filePath: entry?.localPath,
        );
      }
    }

    // 2. Disk cache hit (native only)
    if (_storage.hasDisk) {
      final entry = _index.get(key);
      if (entry != null && !entry.isExpired(_config.maxAge)) {
        final bytes = await _storage.read(entry.localPath);
        if (bytes != null) {
          if (_config.useMemoryCache) _memCache.put(key, bytes);
          _hitCount++;
          _scheduleSave();
          return CacheResult.hit(
            url: url,
            mediaType: entry.mediaType,
            bytes: bytes,
            filePath: entry.localPath,
          );
        }
        // File missing despite index entry — remove stale entry.
        _index.remove(key);
      }
    }

    // 3. Network download
    _missCount++;
    return _download(url, key: key, priority: priority);
  }

  /// Like [getMedia] but also exposes a real-time [DownloadProgress] stream.
  ({Future<CacheResult> result, Stream<DownloadProgress> progress})
  getMediaWithProgress(
    String url, {
    DownloadPriority priority = DownloadPriority.normal,
  }) {
    _assertNotDisposed();
    final key = KeyGenerator.fromUrl(url);

    // Serve from memory cache without a meaningful progress stream.
    if (_config.useMemoryCache && _memCache.containsKey(key)) {
      return (
        result: getMedia(url, priority: priority),
        progress: Stream.value(
          DownloadProgress(url: url, status: DownloadStatus.completed),
        ),
      );
    }

    final conditionalHeaders = _buildConditionalHeaders(key);
    final (:result, :progress) = _engine.enqueue(
      url,
      priority: priority,
      conditionalHeaders: conditionalHeaders,
    );

    return (
      result: result.then((r) => _handleDownloadResult(r, url: url, key: key)),
      progress: progress,
    );
  }

  /// Preloads a list of URLs into cache in the background.
  Future<void> preloadAll(
    List<String> urls, {
    DownloadPriority priority = DownloadPriority.low,
  }) async {
    _assertNotDisposed();
    final futures = urls.map((url) => getMedia(url, priority: priority));
    await Future.wait(futures, eagerError: false);
  }

  /// Cancels an in-flight or queued download. No-op otherwise.
  void cancelDownload(String url) {
    _assertNotDisposed();
    _engine.cancel(url);
  }

  // ── Cache Management ───────────────────────────────────────────────────────

  /// Removes a single entry (memory + disk + index).
  Future<void> removeEntry(String url) async {
    _assertNotDisposed();
    final key = KeyGenerator.fromUrl(url);
    _memCache.remove(key);
    final entry = _index.get(key);
    _index.remove(key);
    if (entry != null && _storage.hasDisk) {
      await _storage.delete(entry.localPath);
    }
    _scheduleSave();
  }

  /// Clears the entire cache (memory + disk + index).
  Future<void> clearAll() async {
    _assertNotDisposed();
    _memCache.clear();
    _index.clear();
    if (_storage.hasDisk) {
      await _storage.deleteAll();
    }
    await _saveIndex();
  }

  /// Removes all entries older than [CacheConfig.maxAge].
  Future<void> clearExpired() async {
    _assertNotDisposed();
    final paths = _index.removeExpired(_config.maxAge);
    for (final path in paths) {
      _evictionCount++;
      if (_storage.hasDisk) await _storage.delete(path);
    }
    if (paths.isNotEmpty) _scheduleSave();
  }

  /// Current cache statistics.
  CacheStats get stats => CacheStats(
    totalEntries: _index.totalEntries,
    totalSizeBytes: _storage.hasDisk ? _index.totalBytes : _memCache.totalBytes,
    hitCount: _hitCount,
    missCount: _missCount,
    evictionCount: _evictionCount,
  );

  /// Total bytes currently stored (memory on web, disk on native).
  int get totalCacheSize =>
      _storage.hasDisk ? _index.totalBytes : _memCache.totalBytes;

  /// Whether [url] is currently in the cache (memory or disk).
  bool isCached(String url) {
    final key = KeyGenerator.fromUrl(url);
    return _memCache.containsKey(key) || _index.containsKey(key);
  }

  /// Formats [bytes] into a human-readable string (e.g. "12.3 MB").
  static String formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  // ── Internal Helpers ───────────────────────────────────────────────────────

  Future<CacheResult> _download(
    String url, {
    required String key,
    required DownloadPriority priority,
  }) async {
    final conditionalHeaders = _buildConditionalHeaders(key);
    final (:result, :progress) = _engine.enqueue(
      url,
      priority: priority,
      conditionalHeaders: conditionalHeaders,
    );
    final raw = await result;
    return _handleDownloadResult(raw, url: url, key: key);
  }

  Future<CacheResult> _handleDownloadResult(
    DownloadResult result, {
    required String url,
    required String key,
  }) async {
    // 304 Not Modified — the cached version is still valid.
    if (result.notModified) {
      final entry = _index.get(key);
      if (entry != null && _storage.hasDisk) {
        final bytes = await _storage.read(entry.localPath);
        if (bytes != null) {
          if (_config.useMemoryCache) _memCache.put(key, bytes);
          return CacheResult.hit(
            url: url,
            mediaType: entry.mediaType,
            bytes: bytes,
            filePath: entry.localPath,
          );
        }
      }
    }

    return _persist(url, key: key, result: result);
  }

  Future<CacheResult> _persist(
    String url, {
    required String key,
    required DownloadResult result,
  }) async {
    final mediaType = KeyGenerator.mediaTypeOf(
      url,
      contentType: result.contentType,
    );
    final ext = KeyGenerator.extensionFor(url, contentType: result.contentType);

    if (_config.useMemoryCache) _memCache.put(key, result.bytes);

    String? filePath;
    if (_storage.hasDisk) {
      filePath = await _storage.write(key, ext, result.bytes);

      if (filePath != null) {
        final entry = CacheEntry(
          url: url,
          key: key,
          localPath: filePath,
          mediaType: mediaType,
          createdAt: DateTime.now(),
          lastAccessedAt: DateTime.now(),
          sizeBytes: result.bytes.length,
          etag: result.etag,
          lastModified: result.lastModified,
          contentType: result.contentType,
        );
        _index.put(entry);
        await _enforceStorageLimit();
        _scheduleSave();
      }
    }

    return CacheResult.miss(
      url: url,
      mediaType: mediaType,
      bytes: result.bytes,
      filePath: filePath,
    );
  }

  Map<String, String> _buildConditionalHeaders(String key) {
    if (!_config.useConditionalGet) return {};
    final entry = _index.get(key);
    if (entry == null) return {};
    return {
      if (entry.etag != null) 'If-None-Match': entry.etag!,
      if (entry.lastModified != null) 'If-Modified-Since': entry.lastModified!,
    };
  }

  Future<void> _enforceStorageLimit() async {
    final evictedPaths = _index.evictToLimit();
    for (final path in evictedPaths) {
      _evictionCount++;
      await _storage.delete(path);
    }
  }

  Future<void> _purgeOrphanedFiles() async {
    if (!_storage.hasDisk) return;
    final indexedPaths = _index.allEntries.map((e) => e.localPath).toSet();
    // Add the index file itself so it's never deleted.
    indexedPaths.add('${_storage.cacheDir}/_index.json');
    // _IoPlatformStorage exposes purgeOrphans via OrphanPurgeable mixin.
    final storage = _storage;
    if (storage is OrphanPurgeable) {
      await storage.purgeOrphans(indexedPaths);
    }
  }

  void _scheduleSave() {
    if (!_storage.hasDisk) return;
    _indexSaveDebounce?.cancel();
    _indexSaveDebounce = Timer(const Duration(seconds: 2), _saveIndex);
  }

  Future<void> _saveIndex() async {
    if (!_storage.hasDisk || _disposed) return;
    try {
      final bytes = _index.toBytes();
      // Write the index JSON directly using a fixed key + extension.
      // The io implementation places it at <cacheDir>/_index.json.
      await _storage.write('_index', '.json', bytes);
    } catch (_) {
      // Non-fatal — index will be rebuilt on next launch.
    }
  }

  void _assertNotDisposed() {
    if (_disposed) throw StateError('MediaCacheManager has been disposed.');
  }

  Future<void> dispose() async {
    _disposed = true;
    _indexSaveDebounce?.cancel();
    _engine.dispose();
    await _saveIndex();
    _instance = null;
  }
}
