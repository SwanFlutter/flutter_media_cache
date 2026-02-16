import 'package:flutter/material.dart';
import 'package:flutter_media_cache/flutter_media_cache.dart';

/// Advanced usage examples for Flutter Media Cache
class AdvancedExamples {
  /// Example 1: Custom cache configuration
  static Future<void> customConfiguration() async {
    await MediaCacheManager.initialize(
      config: const CacheConfig(
        maxCacheDuration: Duration(days: 30), // Cache for 30 days
        maxCacheSize: 200 * 1024 * 1024, // 200MB
        useMemoryCache: true,
        maxMemoryCacheSize: 150,
      ),
    );
  }

  /// Example 2: Programmatic image caching
  static Future<void> programmaticImageCache() async {
    final imageUrl = 'https://example.com/image.jpg';

    // Get cached image data
    final imageData = await MediaCacheManager.instance.getImage(imageUrl);

    if (imageData != null) {
      print('Image loaded from cache: ${imageData.length} bytes');
    } else {
      print('Failed to load image');
    }
  }

  /// Example 3: Programmatic video caching
  static Future<void> programmaticVideoCache() async {
    final videoUrl = 'https://example.com/video.mp4';

    // Get cached video file
    final videoFile = await MediaCacheManager.instance.getVideo(videoUrl);

    if (videoFile != null && await videoFile.exists()) {
      print('Video cached at: ${videoFile.path}');
      print('Video size: ${await videoFile.length()} bytes');
    } else {
      print('Failed to cache video');
    }
  }

  /// Example 4: Cache management
  static Future<void> cacheManagement() async {
    // Get current cache size
    final size = await MediaCacheManager.instance.getCacheSize();
    print('Current cache size: ${MediaCacheManager.formatBytes(size)}');

    // Clear expired cache only
    await MediaCacheManager.instance.clearExpiredCache();
    print('Expired cache cleared');

    // Clear all cache
    await MediaCacheManager.instance.clearCache();
    print('All cache cleared');
  }

  /// Example 5: Custom image widget with loading progress
  static Widget customImageWidget(String imageUrl) {
    return CachedImage(
      imageUrl: imageUrl,
      width: 300,
      height: 200,
      fit: BoxFit.cover,
      borderRadius: BorderRadius.circular(16),
      placeholder: Container(
        width: 300,
        height: 200,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading...', style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
      errorWidget: Container(
        width: 300,
        height: 200,
        decoration: BoxDecoration(
          color: Colors.red[100],
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red),
            SizedBox(height: 8),
            Text('Failed to load', style: TextStyle(color: Colors.red)),
          ],
        ),
      ),
    );
  }

  /// Example 6: Image grid with caching
  static Widget imageGrid(List<String> imageUrls) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: imageUrls.length,
      itemBuilder: (context, index) {
        return CachedImage(
          imageUrl: imageUrls[index],
          fit: BoxFit.cover,
          borderRadius: BorderRadius.circular(8),
        );
      },
    );
  }

  /// Example 7: Video player with caching
  static Widget videoPlayerExample(String videoUrl) {
    return CachedVideo(
      videoUrl: videoUrl,
      builder: (context, videoFile) {
        if (videoFile == null) {
          return const Center(child: Text('Video not available'));
        }

        // Use with video_player package
        return Container(
          color: Colors.black,
          child: Center(
            child: Text(
              'Video cached at:\n${videoFile.path}',
              style: const TextStyle(color: Colors.white),
              textAlign: TextAlign.center,
            ),
          ),
        );
      },
      placeholder: Container(
        height: 200,
        color: Colors.black,
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Colors.white),
              SizedBox(height: 16),
              Text('Caching video...', style: TextStyle(color: Colors.white)),
            ],
          ),
        ),
      ),
      errorWidget: Container(
        height: 200,
        color: Colors.red[900],
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, color: Colors.white, size: 48),
              SizedBox(height: 8),
              Text(
                'Failed to cache video',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Example 8: Batch image preloading
  static Future<void> preloadImages(List<String> imageUrls) async {
    print('Preloading ${imageUrls.length} images...');

    for (final url in imageUrls) {
      try {
        await MediaCacheManager.instance.getImage(url);
        print('Preloaded: $url');
      } catch (e) {
        print('Failed to preload $url: $e');
      }
    }

    print('Preloading complete');
  }

  /// Example 9: Cache statistics
  static Future<Map<String, dynamic>> getCacheStatistics() async {
    final size = await MediaCacheManager.instance.getCacheSize();

    return {
      'size': size,
      'formatted_size': MediaCacheManager.formatBytes(size),
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  /// Example 10: Conditional caching based on network
  static Future<void> conditionalCaching(String imageUrl) async {
    // Check if already cached
    final imageData = await MediaCacheManager.instance.getImage(imageUrl);

    if (imageData != null) {
      print('Using cached image');
    } else {
      print('Downloading and caching image');
    }
  }
}

/// Example widget demonstrating advanced usage
class AdvancedCacheDemo extends StatefulWidget {
  const AdvancedCacheDemo({Key? key}) : super(key: key);

  @override
  State<AdvancedCacheDemo> createState() => _AdvancedCacheDemoState();
}

class _AdvancedCacheDemoState extends State<AdvancedCacheDemo> {
  final List<String> _imageUrls = [
    'https://picsum.photos/400/300?random=1',
    'https://picsum.photos/400/300?random=2',
    'https://picsum.photos/400/300?random=3',
    'https://picsum.photos/400/300?random=4',
  ];

  Map<String, dynamic>? _cacheStats;

  @override
  void initState() {
    super.initState();
    _loadCacheStats();
  }

  Future<void> _loadCacheStats() async {
    final stats = await AdvancedExamples.getCacheStatistics();
    setState(() {
      _cacheStats = stats;
    });
  }

  Future<void> _preloadImages() async {
    await AdvancedExamples.preloadImages(_imageUrls);
    await _loadCacheStats();
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Images preloaded')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Advanced Cache Demo')),
      body: Column(
        children: [
          // Cache statistics
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.blue[50],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Cache Size:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  _cacheStats?['formatted_size'] ?? 'Loading...',
                  style: const TextStyle(color: Colors.blue),
                ),
              ],
            ),
          ),

          // Action buttons
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _preloadImages,
                    icon: const Icon(Icons.download),
                    label: const Text('Preload'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      await MediaCacheManager.instance.clearCache();
                      await _loadCacheStats();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Cache cleared')),
                        );
                      }
                    },
                    icon: const Icon(Icons.delete),
                    label: const Text('Clear'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Image grid
          Expanded(child: AdvancedExamples.imageGrid(_imageUrls)),
        ],
      ),
    );
  }
}
