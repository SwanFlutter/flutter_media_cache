# FlutterMediaCach

## 1.0.1

### Changed
* **BREAKING CHANGE**: Updated `CachedImage` widget API
  * `placeholder` property now accepts a callback function: `Widget Function(BuildContext context, String url)`
  * `errorWidget` property now accepts a callback function: `Widget Function(BuildContext context, String url, Object error)`
  * This change provides more flexibility by giving access to context, URL, and error information

### Migration Guide
Before:
```dart
CachedImage(
  imageUrl: 'https://example.com/image.jpg',
  placeholder: Container(color: Colors.grey),
  errorWidget: Icon(Icons.error),
)
```

After:
```dart
CachedImage(
  imageUrl: 'https://example.com/image.jpg',
  placeholder: (context, url) => Container(color: Colors.grey),
  errorWidget: (context, url, error) => Icon(Icons.error),
)
```

---

## 1.0.0

* Initial release of Flutter Media Cache
* Image caching with memory and disk storage
* Video caching support
* Automatic cache expiration management
* Configurable cache size and duration
* CachedImage widget for easy image display
* CachedVideo widget for video file access
* Cache management utilities (clear, size check, expired cleanup)
* Full cross-platform support (Android, iOS, Windows, macOS, Linux, Web)
* Web platform support with memory-based caching
* Integration with path_provider_master for directory access
* Platform-specific implementations (IO for native, Web for browsers)


---