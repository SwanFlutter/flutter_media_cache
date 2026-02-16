# Flutter Media Cache - Package Structure

## Overview

This package provides a complete solution for caching images and videos in Flutter applications with automatic expiration management and memory optimization.

## Directory Structure

```
flutter_media_cache/
├── lib/
│   ├── flutter_media_cache.dart          # Main export file
│   └── src/
│       ├── media_cache_manager.dart      # Core cache manager
│       ├── cache_config.dart             # Configuration class
│       ├── cached_image_widget.dart      # Image widget
│       └── cached_video_widget.dart      # Video widget
├── example/
│   └── lib/
│       ├── main.dart                     # Main demo app
│       ├── advanced_example.dart         # Advanced usage examples
│       ├── list_example.dart             # List/Grid examples
│       └── video_player_example.dart     # Video player integration
├── test/
│   └── flutter_media_cache_test.dart     # Unit tests
├── doc/
│   └── README.md                         # Complete documentation
├── README.md                             # Quick start guide (English)
├── README_FA.md                          # Quick start guide (Persian)
├── CHANGELOG.md                          # Version history
├── LICENSE                               # MIT License
└── pubspec.yaml                          # Package configuration
```

## Core Components

### 1. MediaCacheManager (`lib/src/media_cache_manager.dart`)

The main cache manager that handles:
- Downloading and caching media files
- Memory cache management
- Disk cache management
- Cache expiration checking
- Cache size calculation
- Cache cleanup operations

**Key Methods:**
- `initialize()` - Initialize cache with configuration
- `getImage()` - Get cached image data
- `getVideo()` - Get cached video file
- `clearCache()` - Clear all cache
- `clearExpiredCache()` - Remove expired files
- `getCacheSize()` - Get total cache size

### 2. CacheConfig (`lib/src/cache_config.dart`)

Configuration class for customizing cache behavior:
- `maxCacheDuration` - How long files are cached (default: 7 days)
- `maxCacheSize` - Maximum cache size in bytes (default: 100MB)
- `useMemoryCache` - Enable/disable memory caching (default: true)
- `maxMemoryCacheSize` - Max items in memory (default: 100)

### 3. CachedImage (`lib/src/cached_image_widget.dart`)

Widget for displaying cached network images:
- Automatic caching and loading
- Customizable placeholder and error widgets
- Support for border radius and sizing
- Memory and disk cache integration

### 4. CachedVideo (`lib/src/cached_video_widget.dart`)

Widget for accessing cached video files:
- Downloads and caches video files
- Provides cached file to builder function
- Customizable loading and error states
- Integration with video player packages

## Example Applications

### 1. Main Demo (`example/lib/main.dart`)

Complete demo application featuring:
- Image gallery with caching
- Video caching example
- Cache management interface
- Cache statistics display
- Clear cache functionality

### 2. Advanced Examples (`example/lib/advanced_example.dart`)

Advanced usage patterns:
- Custom cache configuration
- Programmatic caching
- Batch image preloading
- Cache statistics
- Conditional caching

### 3. List Examples (`example/lib/list_example.dart`)

Efficient caching in lists:
- ListView with cached images
- GridView with cached images
- PageView with cached images
- Lazy loading with pagination

### 4. Video Player Example (`example/lib/video_player_example.dart`)

Integration with video_player package:
- Basic video player setup
- Custom video controls
- Code examples and documentation

## Dependencies

### Runtime Dependencies
- `flutter` - Flutter SDK
- `path_provider_master: ^1.0.0` - Directory access
- `http: ^1.2.0` - Network requests
- `crypto: ^3.0.3` - Cache key generation

### Development Dependencies
- `flutter_test` - Testing framework
- `flutter_lints: ^6.0.0` - Linting rules

## Features

### Image Caching
- Automatic download and cache
- Memory cache for fast access
- Disk cache for persistence
- Automatic expiration management
- MD5-based cache keys

### Video Caching
- Download and cache video files
- File-based caching
- Expiration management
- Integration with video players

### Cache Management
- Clear all cache
- Clear expired files only
- Calculate cache size
- Format size display
- Automatic cleanup

### Performance
- Memory cache for frequently accessed images
- Efficient disk storage
- Minimal memory footprint
- Fast cache key generation
- Optimized file operations

## Usage Patterns

### Basic Usage
```dart
// Initialize
await MediaCacheManager.initialize();

// Display image
CachedImage(imageUrl: 'https://example.com/image.jpg')

// Display video
CachedVideo(
  videoUrl: 'https://example.com/video.mp4',
  builder: (context, file) => VideoPlayer(file),
)
```

### Advanced Usage
```dart
// Custom configuration
await MediaCacheManager.initialize(
  config: CacheConfig(
    maxCacheDuration: Duration(days: 30),
    maxCacheSize: 200 * 1024 * 1024,
  ),
);

// Programmatic access
final imageData = await MediaCacheManager.instance.getImage(url);
final videoFile = await MediaCacheManager.instance.getVideo(url);

// Cache management
await MediaCacheManager.instance.clearExpiredCache();
final size = await MediaCacheManager.instance.getCacheSize();
```

## Testing

Run tests with:
```bash
flutter test
```

Current test coverage:
- CacheConfig creation and copying
- MediaCacheManager singleton pattern
- Byte formatting utility

## Platform Support

| Platform | Status |
|----------|--------|
| Android | ✅ Fully supported |
| iOS | ✅ Fully supported |
| Windows | ✅ Fully supported |
| macOS | ✅ Fully supported |
| Linux | ✅ Fully supported |
| Web | ✅ Fully supported (memory cache) |

## Documentation

- **README.md** - Quick start guide (English)
- **README_FA.md** - Quick start guide (Persian)
- **doc/README.md** - Complete API documentation
- **CHANGELOG.md** - Version history
- **LICENSE** - MIT License

## Contributing

Contributions are welcome! Please ensure:
1. Code follows Flutter style guidelines
2. All tests pass
3. New features include tests
4. Documentation is updated

## License

MIT License - see LICENSE file for details.

## Credits

Inspired by:
- cached_network_image
- fast_cached_network_image

Built with:
- path_provider_master
- http
- crypto
