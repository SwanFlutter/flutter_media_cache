# Changelog

## [3.0.0] — 2026-06-25

### ⚠️ Breaking Changes
- **`CachedVideo` now uses a builder pattern** — the `autoPlay`, `showControls`,
  and `aspectRatio` parameters have been removed. Use the new `builder` callback
  to supply your own video player widget with full control.

  ```dart
  // Before (v2)
  CachedVideo(
    videoUrl: url,
    autoPlay: false,
    showControls: true,
    aspectRatio: 16 / 9,
  )

  // After (v3)
  CachedVideo(
    videoUrl: url,
    builder: (context, result) => YourPlayer(filePath: result.filePath),
  )
  ```

- Removed `video_player` dependency — the package no longer ships a built-in
  player. Users choose any player they prefer (video_player, chewy, fvp, etc.).

### 🌍 Improvements
- **Full 6-platform support** — removing `video_player` unblocks Windows and
  Linux, giving the package 20/20 on pub.dev platform score.
- Zero platform-specific dependencies; only `flutter`, `http`, `crypto`, and
  `path_provider_master`.

---

## [2.0.1] — 2026-06-25

### ✨ New Features
- **Web platform support** — package now works on all 6 Flutter platforms:
  Android · iOS · Web · macOS · Windows · Linux.
- `MediaCacheManager.formatBytes(int)` utility for human-readable cache sizes.
- `MediaCacheManager.totalCacheSize` getter (memory bytes on web, disk bytes on native).

### 🔧 Improvements
- `CachedVideo` on web uses `VideoPlayerController.networkUrl()` automatically —
  no code changes needed in calling code.
- All disk I/O isolated behind `PlatformStorage` conditional-import abstraction;
  `dart:io` is never imported on web.
- `CacheIndex` rewritten to be `dart:io`-free (serialises via `Uint8List`).
- Orphaned file cleanup (`purgeOrphans`) runs at startup on native platforms.

### 🐛 Bug Fixes
- Fixed: Package failed to compile on Flutter Web due to `dart:io` imports in
  `media_cache_manager.dart` and `cached_video.dart`.
- Fixed: `CachedVideo` crashed on web with "Video file path unavailable".
- Fixed: pub point issues.

---

## [2.0.0] — 2026-06-25

### ⚠️ Breaking Changes
- Complete rewrite — public API is redesigned. See README for migration guide.
- `FlutterMediaCache` class replaced by `MediaCacheManager` singleton.
- `CachedImage` constructor parameters reorganised (`imageUrl` replaces `url`).

### ✨ New Features
- **Priority download queue** — `DownloadPriority.high/normal/low` per request.
- **Request deduplication** — duplicate URLs share one in-flight download.
- **Exponential-backoff retry** — configurable via `CacheConfig.maxRetries`.
- **Per-download progress stream** — `Stream<DownloadProgress>` with bytes received.
- **Conditional HTTP GET** — `ETag` / `Last-Modified` / `If-None-Match` support.
- **Smart LRU eviction** — separate memory (item count) and disk (byte size) limits.
- **Preloading API** — `MediaCacheManager.instance.preloadAll([...])`.
- **Cancellation** — `cancelDownload(url)` stops queued or in-flight tasks.
- **`CachedVideo`** widget with built-in progress indicator and playback controls.
- **`DownloadProgressBuilder`** for fully custom progress UIs.
- **`CacheManagerProvider`** `InheritedWidget` for dependency injection.
- **`CacheStats`** — hit count, miss count, eviction count, hit rate, total size.
- **Atomic index persistence** — write-then-rename prevents index corruption.
- **Orphan file cleanup** — dangling files not in the index are removed on startup.

### 🔧 Improvements
- Cache keys now use **SHA-256** (not MD5) for collision-resistance.
- Download engine lives on the main isolate with `async`/`await` — no Isolate
  overhead for small payloads, correct Flutter API access.
- `CacheConfig.copyWith()` for easy per-screen overrides.
- Debounced index writes (2 s) — avoids disk thrash on rapid requests.
- `ResizeImage` support in `CachedImage` to reduce decoded memory footprint.

### 🐛 Bug Fixes
- Fixed: Concurrent requests for the same URL triggered multiple downloads.
- Fixed: Memory cache could grow unboundedly.
- Fixed: Download failures were silently swallowed.
- Fixed: Stale index entries for missing files caused errors.

---

## [1.x.x] — Legacy

See Git history for 1.x changes.
