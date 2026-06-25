# flutter_media_cache

[![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS%20%7C%20Windows%20%7C%20macOS%20%7C%20Linux-blue.svg)](https://flutter.dev)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![pub.dev](https://img.shields.io/pub/v/flutter_media_cache.svg)](https://pub.dev/packages/flutter_media_cache)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![style: flutter_lints](https://img.shields.io/badge/style-flutter__lints-4BC0F5.svg)](https://pub.dev/packages/flutter_lints)

Production-grade media caching for Flutter — images **and** videos — with a
priority download queue, automatic LRU eviction, deduplication, exponential-
backoff retry, per-download progress streams, and conditional HTTP GET.

---

## Features

| Feature | Details |
|---|---|
| 🗂️ Two-tier cache | In-memory LRU + disk storage |
| 🚦 Priority queue | `high` / `normal` / `low` per request |
| 🔁 Deduplication | Same URL → one in-flight download |
| 🔄 Retry | Exponential backoff, configurable attempts |
| 📡 Progress stream | `Stream<DownloadProgress>` with byte counts |
| 🌐 Conditional GET | `ETag` / `If-None-Match` / `Last-Modified` |
| 🧹 LRU eviction | Separate limits for memory (items) and disk (bytes) |
| 🎬 Video support | `CachedVideo` widget with built-in controls |
| ⏸️ Cancellation | Cancel any queued or in-flight download |
| 📦 Preloading | `preloadAll([url1, url2, ...])` |
| 📊 Analytics | Hit rate, miss count, total cache size |

---

## Getting started

```yaml
dependencies:
  flutter_media_cache: ^2.0.1
```

### Initialize once

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await MediaCacheManager.initialize(
    config: CacheConfig(
      maxDiskBytes: 300 * 1024 * 1024,  // 300 MB disk
      maxMemoryItems: 200,               // 200 items in RAM
      maxAge: const Duration(days: 30),
      maxConcurrentDownloads: 6,
      maxRetries: 3,
    ),
  );

  runApp(const MyApp());
}
```

Alternatively, use `CacheManagerProvider` near the root of your widget tree
and skip the manual `initialize` call:

```dart
return CacheManagerProvider(
  config: CacheConfig(maxDiskBytes: 300 * 1024 * 1024),
  child: MaterialApp(home: HomePage()),
);
```

---

## Usage

### Display a cached image

```dart
CachedImage(
  imageUrl: 'https://picsum.photos/400/300',
  width: 400,
  height: 300,
  fit: BoxFit.cover,
  borderRadius: BorderRadius.circular(12),
  priority: DownloadPriority.high,
  placeholder: const ShimmerBox(),     // optional
  errorWidget: const ErrorPlaceholder(), // optional
)
```

### Custom progress indicator

```dart
CachedImage(
  imageUrl: 'https://example.com/large.jpg',
  progressIndicatorBuilder: (context, url, progress) {
    return CircularProgressIndicator(value: progress.progress);
  },
)
```

### Display a cached video

```dart
CachedVideo(
  videoUrl: 'https://example.com/clip.mp4',
  autoPlay: false,
  showControls: true,
  aspectRatio: 16 / 9,
)
```

### Programmatic fetch (bytes)

```dart
final result = await MediaCacheManager.instance.getMedia(
  'https://example.com/image.jpg',
  priority: DownloadPriority.high,
);

if (result.bytes != null) {
  // Use result.bytes (Uint8List) or result.filePath (String? on non-web)
}
```

### Fetch with progress stream

```dart
final (:result, :progress) = MediaCacheManager.instance.getMediaWithProgress(
  'https://example.com/video.mp4',
);

progress.listen((p) {
  print('${p.bytesDownloaded} / ${p.totalBytes ?? "?"}  '
        '— ${p.status.name}');
});

final data = await result;
```

### Custom progress UI with `DownloadProgressBuilder`

```dart
DownloadProgressBuilder(
  url: 'https://example.com/video.mp4',
  builder: (context, progress, child) {
    if (progress == null || progress.isCompleted) return child!;
    return LinearProgressIndicator(value: progress.progress);
  },
  child: const Icon(Icons.check_circle, color: Colors.green),
)
```

### Preloading

```dart
// Fire-and-forget; uses low priority so it doesn't block visible content.
await MediaCacheManager.instance.preloadAll([
  'https://example.com/next1.jpg',
  'https://example.com/next2.jpg',
]);
```

### Cache management

```dart
final manager = MediaCacheManager.instance;

// Is this URL cached?
final cached = manager.isCached('https://example.com/image.jpg');

// Remove one entry.
await manager.removeEntry('https://example.com/image.jpg');

// Remove all expired entries.
await manager.clearExpired();

// Wipe everything.
await manager.clearAll();

// Analytics snapshot.
final stats = manager.stats;
print('Hit rate: ${(stats.hitRate * 100).toStringAsFixed(1)}%');
print('Disk used: ${stats.totalSizeBytes ~/ 1024} KB');
```

---

## Configuration reference

```dart
CacheConfig(
  maxDiskBytes: 200 * 1024 * 1024,   // 200 MB (default)
  maxMemoryItems: 150,                // LRU item cap (default)
  maxAge: const Duration(days: 14),  // TTL (default)
  maxConcurrentDownloads: 4,         // parallel limit (default)
  maxRetries: 3,                     // retry attempts (default)
  retryBaseDelay: Duration(seconds: 1), // backoff base (default)
  downloadTimeout: Duration(seconds: 30),
  connectTimeout: Duration(seconds: 10),
  useMemoryCache: true,
  useConditionalGet: true,           // ETag / Last-Modified
  subdirectoryName: 'flutter_media_cache',
  customHeaders: {'Authorization': 'Bearer token'},
)
```

---

## Architecture

```
┌──────────────────────────────────────────────────────────┐
│                   MediaCacheManager                       │
│  ┌─────────────┐  ┌──────────────┐  ┌────────────────┐  │
│  │ LruMemory   │  │  CacheIndex  │  │ DownloadEngine │  │
│  │ Cache       │  │  (disk meta) │  │ (queue+retry)  │  │
│  └─────────────┘  └──────────────┘  └────────────────┘  │
└──────────────────────────────────────────────────────────┘
       ▲                   ▲                   ▲
  Memory hit           Disk hit           Network miss
  (< 1 ms)            (I/O)              (HTTP + retry)
```

**Request flow:**

1. Check `LruMemoryCache` (in-process, instant).
2. Check `CacheIndex` → read file from disk → promote to memory.
3. Enqueue in `DownloadEngine` — deduplicated, priority-sorted.
4. On success: persist bytes to disk, update index, promote to memory.
5. On failure: exponential-backoff retry up to `maxRetries`.

---

## Migration from v1

| v1 | v2 |
|---|---|
| `FlutterMediaCache()` | `MediaCacheManager.initialize()` |
| `CachedImage(url: ...)` | `CachedImage(imageUrl: ...)` |
| `FlutterMediaCache.clearCache()` | `MediaCacheManager.instance.clearAll()` |
| No progress support | `getMediaWithProgress(url)` |
| No video widget | `CachedVideo(videoUrl: ...)` |

---

## Contributing

PRs and issues are welcome at
[github.com/SwanFlutter/flutter_media_cache](https://github.com/SwanFlutter/flutter_media_cache).

---

## License

MIT © [SwanFlutter](https://swanflutterdev.com)
