# Changelog

All notable changes to `flutter_media_cache` will be documented here.
This project adheres to [Semantic Versioning](https://semver.org/).

---

## [2.0.0] — 2025-XX-XX

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
