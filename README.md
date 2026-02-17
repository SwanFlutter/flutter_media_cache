# Flutter Media Cache

A powerful and easy-to-use Flutter package for caching images and videos with automatic expiration management, memory caching, and disk storage.

[![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS%20%7C%20Windows%20%7C%20macOS%20%7C%20Linux-blue.svg)](https://flutter.dev)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

## Features

- ✅ **Image Caching**: Automatically cache network images with memory and disk storage
- ✅ **Video Caching**: Cache video files for offline playback
- ✅ **Automatic Expiration**: Set custom cache duration (default: 7 days)
- ✅ **Memory Cache**: Fast access with in-memory caching
- ✅ **Disk Cache**: Persistent storage using device temporary directory
- ✅ **Cache Management**: Clear cache, remove expired files, check cache size
- ✅ **Easy to Use**: Simple widgets similar to `cached_network_image`
- ✅ **Customizable**: Configure cache size, duration, and behavior
- ✅ **Cross-Platform**: Works on Android, iOS, Windows, macOS, Linux, and Web

## Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  flutter_media_cache: ^1.0.1
```

Then run:

```bash
flutter pub get
```

## Quick Start

### 1. Initialize the Cache Manager

```dart
import 'package:flutter/material.dart';
import 'package:flutter_media_cache/flutter_media_cache.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await MediaCacheManager.initialize(
    config: CacheConfig(
      maxCacheDuration: Duration(days: 7),
      useMemoryCache: true,
    ),
  );
  
  runApp(MyApp());
}
```

### 2. Display Cached Images

```dart
CachedImage(
  imageUrl: 'https://example.com/image.jpg',
  width: 200,
  height: 200,
  fit: BoxFit.cover,
  borderRadius: BorderRadius.circular(12),
)
```

### 3. Cache and Display Videos

```dart
CachedVideo(
  videoUrl: 'https://example.com/video.mp4',
  builder: (context, videoData) {
    if (videoData == null) return SizedBox();
    // Use video_player package to display
    return VideoPlayer(file: videoData);
  },
)
```

## Documentation

### Main Documentation
- **[doc/README.md](doc/README.md)** - Complete API documentation with detailed examples

### Platform-Specific Guides
- **[WEB_SUPPORT.md](WEB_SUPPORT.md)** - Web platform support and best practices
- **[VIDEO_CACHING_GUIDE.md](VIDEO_CACHING_GUIDE.md)** - How to cache and display videos (English)
- **[VIDEO_CACHING_GUIDE_FA.md](VIDEO_CACHING_GUIDE_FA.md)** - راهنمای کش و نمایش ویدئو (فارسی)

### Quick References
- **[README_FA.md](README_FA.md)** - فارسی راهنمای سریع
- **[PACKAGE_STRUCTURE.md](PACKAGE_STRUCTURE.md)** - Package architecture and structure

## Example

Check out the [example](example) folder for complete working examples:

```bash
cd example
flutter run
```

### Example Files
- `example/lib/main.dart` - Complete demo application
- `example/lib/advanced_example.dart` - Advanced usage patterns
- `example/lib/list_example.dart` - Efficient caching in lists
- `example/lib/complete_video_example.dart` - Video caching and playback
- `example/lib/video_player_example.dart` - Video player integration

## API Overview

### MediaCacheManager

```dart
// Initialize
await MediaCacheManager.initialize(config: CacheConfig(...));

// Get cached image
final imageData = await MediaCacheManager.instance.getImage(url);

// Get cached video
final videoData = await MediaCacheManager.instance.getVideo(url);

// Clear cache
await MediaCacheManager.instance.clearCache();

// Get cache size
final size = await MediaCacheManager.instance.getCacheSize();
```

### CachedImage Widget

```dart
CachedImage(
  imageUrl: 'https://example.com/image.jpg',
  width: 200,
  height: 200,
  fit: BoxFit.cover,
  borderRadius: BorderRadius.circular(12),
  placeholder: CircularProgressIndicator(),
  errorWidget: Icon(Icons.error),
)
```

### CachedVideo Widget

```dart
CachedVideo(
  videoUrl: 'https://example.com/video.mp4',
  builder: (context, videoData) {
    // videoData is File on native, Uint8List on web
    return VideoPlayer(file: videoData);
  },
  placeholder: CircularProgressIndicator(),
  errorWidget: Icon(Icons.error),
)
```

## Configuration

```dart
CacheConfig(
  maxCacheDuration: Duration(days: 7),      // Cache expiration time
  maxCacheSize: 100 * 1024 * 1024,          // 100MB max cache size
  useMemoryCache: true,                      // Enable memory cache
  maxMemoryCacheSize: 100,                   // Max items in memory
)
```

## Platform Support

| Platform | Status |
|----------|--------|
| Android | ✅ Fully supported |
| iOS | ✅ Fully supported |
| Windows | ✅ Fully supported |
| macOS | ✅ Fully supported |
| Linux | ✅ Fully supported |
| Web | ✅ Fully supported (memory cache) |

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Credits

Inspired by:
- [cached_network_image](https://pub.dev/packages/cached_network_image)
- [fast_cached_network_image](https://pub.dev/packages/fast_cached_network_image)

Uses:
- [path_provider_master](https://pub.dev/packages/path_provider_master)
- [http](https://pub.dev/packages/http)
- [crypto](https://pub.dev/packages/crypto)
