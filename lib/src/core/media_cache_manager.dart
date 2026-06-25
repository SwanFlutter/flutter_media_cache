// lib/src/core/media_cache_manager.dart

import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider_master/path_provider_master.dart';

import '../core/cache_config.dart';
import '../core/exceptions.dart';
import '../core/models.dart';
import '../download/download_engine.dart';
import '../storage/cache_index.dart';
import '../storage/lru_memory_cache.dart';
import '../utils/key_generator.dart';

/// The central singleton that orchestrates caching, downloading, and eviction.
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
/// // Simple image fetch (returns bytes on all platforms)
/// final result = await MediaCacheManager.instance.getMedia('https://...');
///
/// // With progress stream
/// final (:result, :progress) = MediaCacheManager.instance.getMediaWithProgress('https://...');
/// progress.listen((p) => print('${p.progress}'));
/// final data = await result;
/// ```
class MediaCacheManager {
  MediaCacheManager._({required CacheConfig config})
    : _config = config,
      _index = CacheIndex(maxDiskBytes: config.maxDiskBytes),
      _memCache = LruMemoryCache(maxItems: config.maxMemoryItems),
      _engine = DownloadEngine(config: config);

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

  late final Directory _cacheDir;
  late final File _indexFile;

  // Analytics counters.
  int _hitCount = 0;
  int _missCount = 0;
  int _evictionCount = 0;

  bool _disposed = false;

  // Debounce index writes so we don't hit disk on every request.
  Timer? _indexSaveDebounce;

  // ── Initialization ─────────────────────────────────────────────────────────

  Future<void> _init() async {
    final base = kIsWeb
        ? null
        : await PathProviderMaster.getTemporaryDirectory();

    if (!kIsWeb) {
      _cacheDir = Directory('${base!.path}/${_config.subdirectoryName}');
      await _cacheDir.create(recursive: true);
      _indexFile = File('${_cacheDir.path}/_index.json');
      await _index.loadFrom(_indexFile);
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

    // 2. Disk cache hit
    if (!kIsWeb) {
      final entry = _index.get(key);
      if (entry != null && !entry.isExpired(_config.maxAge)) {
        final file = File(entry.localPath);
        if (await file.exists()) {
          final bytes = await file.readAsBytes();
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

    // Serve from cache without a meaningful progress stream.
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
    if (entry != null && !kIsWeb) {
      final file = File(entry.localPath);
      if (await file.exists()) await file.delete();
    }
    _scheduleSave();
  }

  /// Clears the entire cache (memory + disk + index).
  Future<void> clearAll() async {
    _assertNotDisposed();
    _memCache.clear();
    _index.clear();
    if (!kIsWeb && await _cacheDir.exists()) {
      await for (final entity in _cacheDir.list()) {
        if (entity is File && !entity.path.endsWith('_index.json')) {
          await entity.delete();
        }
      }
    }
    await _saveIndex();
  }

  /// Removes all entries older than [CacheConfig.maxAge].
  Future<void> clearExpired() async {
    _assertNotDisposed();
    final paths = _index.removeExpired(_config.maxAge);
    for (final path in paths) {
      _evictionCount++;
      final file = File(path);
      if (await file.exists()) await file.delete();
    }
    if (paths.isNotEmpty) _scheduleSave();
  }

  /// Current cache statistics.
  CacheStats get stats => CacheStats(
    totalEntries: _index.totalEntries,
    totalSizeBytes: _index.totalBytes,
    hitCount: _hitCount,
    missCount: _missCount,
    evictionCount: _evictionCount,
  );

  /// Whether [url] is currently in the cache (memory or disk).
  bool isCached(String url) {
    final key = KeyGenerator.fromUrl(url);
    return _memCache.containsKey(key) || _index.containsKey(key);
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
      if (entry != null && !kIsWeb) {
        final file = File(entry.localPath);
        if (await file.exists()) {
          final bytes = await file.readAsBytes();
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
    if (!kIsWeb) {
      filePath = '${_cacheDir.path}/$key$ext';
      await File(filePath).writeAsBytes(result.bytes, flush: true);

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
      final file = File(path);
      if (await file.exists()) await file.delete();
    }
  }

  Future<void> _purgeOrphanedFiles() async {
    final indexedPaths = _index.allEntries.map((e) => e.localPath).toSet();
    await for (final entity in _cacheDir.list()) {
      if (entity is File && !entity.path.endsWith('_index.json')) {
        if (!indexedPaths.contains(entity.path)) await entity.delete();
      }
    }
  }

  void _scheduleSave() {
    _indexSaveDebounce?.cancel();
    _indexSaveDebounce = Timer(const Duration(seconds: 2), _saveIndex);
  }

  Future<void> _saveIndex() async {
    if (kIsWeb || _disposed) return;
    await _index.saveTo(_indexFile);
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
