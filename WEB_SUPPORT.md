# Web Platform Support

Flutter Media Cache now fully supports web platforms with memory-based caching!

## How It Works

On web platforms, the package automatically uses a memory-only caching strategy since web browsers don't have direct file system access like native platforms.

### Key Differences from Native

| Feature | Native (Android/iOS/Desktop) | Web |
|---------|------------------------------|-----|
| Storage | Disk + Memory | Memory only |
| Cache Persistence | Survives app restart | Lost on page reload |
| Video Format | File object | Uint8List (bytes) |
| Max Cache Size | Limited by disk space | Limited by browser memory |
| Performance | Very fast (disk cache) | Fast (memory cache) |

## Usage

The API is exactly the same on web as on native platforms:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_media_cache/flutter_media_cache.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize - works on all platforms including web
  await MediaCacheManager.initialize(
    config: CacheConfig(
      maxCacheDuration: Duration(days: 7),
      useMemoryCache: true,
      maxMemoryCacheSize: 100, // Important for web!
    ),
  );
  
  runApp(MyApp());
}
```

### Display Images

```dart
CachedImage(
  imageUrl: 'https://example.com/image.jpg',
  width: 200,
  height: 200,
  fit: BoxFit.cover,
)
```

### Handle Videos

On web, videos are returned as `Uint8List` instead of `File`:

```dart
CachedVideo(
  videoUrl: 'https://example.com/video.mp4',
  builder: (context, videoData) {
    if (videoData == null) return SizedBox();
    
    // On web: videoData is Uint8List
    // On native: videoData is File
    
    if (kIsWeb) {
      // Handle Uint8List for web
      final bytes = videoData as Uint8List;
      // Use bytes with video player that supports Uint8List
    } else {
      // Handle File for native
      final file = videoData as File;
      // Use file with video player
    }
    
    return VideoPlayerWidget(data: videoData);
  },
)
```

## Best Practices for Web

### 1. Limit Memory Cache Size

Since web uses memory-only caching, be mindful of memory usage:

```dart
CacheConfig(
  maxMemoryCacheSize: 50, // Lower for web
  useMemoryCache: true,
)
```

### 2. Clear Cache Periodically

Clear cache when navigating away or when memory is low:

```dart
// Clear all cache
await MediaCacheManager.instance.clearCache();

// Or clear expired only
await MediaCacheManager.instance.clearExpiredCache();
```

### 3. Monitor Cache Size

Check cache size to avoid memory issues:

```dart
final size = await MediaCacheManager.instance.getCacheSize();
if (size > 50 * 1024 * 1024) { // 50MB
  await MediaCacheManager.instance.clearExpiredCache();
}
```

### 4. Use Smaller Images

Optimize images for web to reduce memory usage:

```dart
// Use smaller image sizes
CachedImage(
  imageUrl: 'https://example.com/image.jpg?w=400',
  width: 200,
  height: 200,
)
```

## Platform Detection

Use `kIsWeb` to detect web platform:

```dart
import 'package:flutter/foundation.dart' show kIsWeb;

if (kIsWeb) {
  // Web-specific code
  print('Running on web');
} else {
  // Native-specific code
  print('Running on native');
}
```

## Complete Web Example

```dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_media_cache/flutter_media_cache.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Configure for web
  await MediaCacheManager.initialize(
    config: CacheConfig(
      maxCacheDuration: Duration(hours: 24), // Shorter for web
      maxMemoryCacheSize: kIsWeb ? 50 : 100, // Less for web
      useMemoryCache: true,
    ),
  );
  
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Web Cache Demo',
      home: WebCacheDemo(),
    );
  }
}

class WebCacheDemo extends StatelessWidget {
  final List<String> imageUrls = [
    'https://picsum.photos/400/300?random=1',
    'https://picsum.photos/400/300?random=2',
    'https://picsum.photos/400/300?random=3',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(kIsWeb ? 'Web Cache Demo' : 'Native Cache Demo'),
        actions: [
          IconButton(
            icon: Icon(Icons.delete),
            onPressed: () async {
              await MediaCacheManager.instance.clearCache();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Cache cleared')),
              );
            },
          ),
        ],
      ),
      body: GridView.builder(
        padding: EdgeInsets.all(16),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: kIsWeb ? 3 : 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: imageUrls.length,
        itemBuilder: (context, index) {
          return CachedImage(
            imageUrl: imageUrls[index],
            fit: BoxFit.cover,
            borderRadius: BorderRadius.circular(12),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.info),
        onPressed: () async {
          final size = await MediaCacheManager.instance.getCacheSize();
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text('Cache Info'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Platform: ${kIsWeb ? "Web" : "Native"}'),
                  SizedBox(height: 8),
                  Text('Cache Size: ${MediaCacheManager.formatBytes(size)}'),
                  SizedBox(height: 8),
                  Text('Storage: ${kIsWeb ? "Memory" : "Disk + Memory"}'),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('OK'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
```

## Limitations on Web

1. **No Persistence**: Cache is lost when the page is reloaded
2. **Memory Only**: Limited by browser memory constraints
3. **No Disk Storage**: Cannot use file system like native platforms
4. **Video Format**: Videos are returned as bytes, not files

## Future Enhancements

Potential improvements for web support:

- IndexedDB integration for persistent storage
- Service Worker caching
- Progressive Web App (PWA) support
- Automatic cache size management
- Background sync for offline support

## Browser Compatibility

Tested and working on:
- ✅ Chrome/Chromium
- ✅ Firefox
- ✅ Safari
- ✅ Edge

## Performance Tips

1. **Preload Images**: Load images before they're needed
2. **Lazy Loading**: Load images as they come into view
3. **Image Optimization**: Use appropriate image sizes
4. **Cache Cleanup**: Clear cache when memory is low
5. **Monitor Usage**: Track cache size and clear when needed

## Troubleshooting

### High Memory Usage

```dart
// Reduce cache size
CacheConfig(maxMemoryCacheSize: 30)

// Clear cache more frequently
await MediaCacheManager.instance.clearExpiredCache();
```

### Slow Loading

```dart
// Preload images
for (final url in imageUrls) {
  await MediaCacheManager.instance.getImage(url);
}
```

### Cache Not Working

```dart
// Ensure initialization
await MediaCacheManager.initialize();

// Check if web
if (kIsWeb) {
  print('Web caching is memory-only');
}
```

## Support

For web-specific issues, please file an issue on GitHub with:
- Browser name and version
- Error messages
- Code example
- Expected vs actual behavior
