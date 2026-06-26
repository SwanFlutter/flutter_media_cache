/// Flutter Media Cache — production-grade media caching for Flutter.
///
/// ## Quick start
///
/// ```dart
/// void main() async {
///   WidgetsFlutterBinding.ensureInitialized();
///   await MediaCacheManager.initialize(
///     config: CacheConfig(
///       maxDiskBytes: 300 * 1024 * 1024, // 300 MB
///       maxAge: const Duration(days: 30),
///     ),
///   );
///   runApp(const MyApp());
/// }
/// ```
///
/// Then in your widgets:
///
/// ```dart
/// CachedImage(imageUrl: 'https://picsum.photos/400/300')
///
/// CachedVideo(
///   videoUrl: 'https://example.com/video.mp4',
///   builder: (context, result) => YourVideoPlayer(filePath: result.filePath),
/// )
/// ```
library;

// Core
export 'src/core/cache_config.dart';
export 'src/core/exceptions.dart';
export 'src/core/media_cache_manager.dart';
export 'src/core/models.dart';

// Widgets
export 'src/widgets/cached_image.dart';
export 'src/widgets/cached_video.dart';
export 'src/widgets/cache_manager_provider.dart';
export 'src/widgets/download_progress_builder.dart';

// Utils (for advanced users)
export 'src/utils/key_generator.dart';
