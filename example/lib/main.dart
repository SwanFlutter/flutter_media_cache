import 'package:flutter/material.dart';
import 'package:flutter_media_cache/flutter_media_cache.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize media cache with custom configuration
  await MediaCacheManager.initialize(
    config: const CacheConfig(
      maxCacheDuration: Duration(days: 7), // Cache expires after 7 days
      maxCacheSize: 100 * 1024 * 1024, // 100MB max cache size
      useMemoryCache: true, // Enable memory cache for faster access
      maxMemoryCacheSize: 100, // Max 100 items in memory
    ),
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Media Cache Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const MediaCacheDemoPage(),
    );
  }
}

class MediaCacheDemoPage extends StatefulWidget {
  const MediaCacheDemoPage({super.key});

  @override
  State<MediaCacheDemoPage> createState() => _MediaCacheDemoPageState();
}

class _MediaCacheDemoPageState extends State<MediaCacheDemoPage> {
  int _selectedIndex = 0;
  String _cacheSize = 'Calculating...';

  // Sample image URLs
  final List<String> imageUrls = [
    'https://picsum.photos/400/300?random=1',
    'https://picsum.photos/400/300?random=2',
    'https://picsum.photos/400/300?random=3',
    'https://picsum.photos/400/300?random=4',
    'https://picsum.photos/400/300?random=5',
    'https://picsum.photos/400/300?random=6',
  ];

  // Sample video URL (you can replace with your own)
  final String videoUrl =
      'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4';

  @override
  void initState() {
    super.initState();
    _updateCacheSize();
  }

  Future<void> _updateCacheSize() async {
    final size = await MediaCacheManager.instance.getCacheSize();
    setState(() {
      _cacheSize = MediaCacheManager.formatBytes(size);
    });
  }

  Future<void> _clearCache() async {
    await MediaCacheManager.instance.clearCache();
    await _updateCacheSize();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cache cleared successfully'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _clearExpiredCache() async {
    await MediaCacheManager.instance.clearExpiredCache();
    await _updateCacheSize();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Expired cache cleared'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flutter Media Cache Demo'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showCacheInfo(),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'clear') {
                _clearCache();
              } else if (value == 'clear_expired') {
                _clearExpiredCache();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'clear',
                child: Row(
                  children: [
                    Icon(Icons.delete_forever, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Clear All Cache'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'clear_expired',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline, color: Colors.orange),
                    SizedBox(width: 8),
                    Text('Clear Expired'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _buildImageGallery(),
          _buildVideoExample(),
          _buildCacheManagement(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.image), label: 'Images'),
          NavigationDestination(
            icon: Icon(Icons.video_library),
            label: 'Videos',
          ),
          NavigationDestination(icon: Icon(Icons.settings), label: 'Cache'),
        ],
      ),
    );
  }

  Widget _buildImageGallery() {
    return RefreshIndicator(
      onRefresh: () async {
        setState(() {});
        await _updateCacheSize();
      },
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.2,
        ),
        itemCount: imageUrls.length,
        itemBuilder: (context, index) {
          return Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: CachedImage(
                imageUrl: imageUrls[index],
                fit: BoxFit.cover,
                placeholder: Container(
                  color: Colors.grey[300],
                  child: const Center(child: CircularProgressIndicator()),
                ),
                errorWidget: Container(
                  color: Colors.red[100],
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.broken_image, size: 48, color: Colors.red),
                      SizedBox(height: 8),
                      Text(
                        'Failed to load',
                        style: TextStyle(color: Colors.red),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildVideoExample() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.video_library, size: 80, color: Colors.blue),
            const SizedBox(height: 24),
            const Text(
              'Video Caching Example',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              'Use CachedVideo widget to cache video files',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'CachedVideo(\n'
                '  videoUrl: "https://example.com/video.mp4",\n'
                '  builder: (context, videoFile) {\n'
                '    return VideoPlayer(file: videoFile);\n'
                '  },\n'
                ')',
                style: TextStyle(fontFamily: 'monospace'),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Note: Add video_player package to play videos',
              style: TextStyle(fontSize: 12, color: Colors.orange),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCacheManagement() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Cache Information',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                _buildInfoRow('Cache Size', _cacheSize),
                const Divider(),
                _buildInfoRow('Max Duration', '7 days'),
                const Divider(),
                _buildInfoRow('Max Size', '100 MB'),
                const Divider(),
                _buildInfoRow('Memory Cache', 'Enabled'),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _updateCacheSize,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Refresh Info'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Cache Actions',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _clearExpiredCache,
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Clear Expired Cache'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: () => _showClearCacheDialog(),
                  icon: const Icon(Icons.delete_forever),
                  label: const Text('Clear All Cache'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Configuration',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Current cache configuration:',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'CacheConfig(\n'
                    '  maxCacheDuration: Duration(days: 7),\n'
                    '  maxCacheSize: 100 * 1024 * 1024,\n'
                    '  useMemoryCache: true,\n'
                    '  maxMemoryCacheSize: 100,\n'
                    ')',
                    style: TextStyle(fontFamily: 'monospace', fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          Text(value, style: const TextStyle(fontSize: 16, color: Colors.blue)),
        ],
      ),
    );
  }

  void _showCacheInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cache Information'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Cache Size: $_cacheSize'),
            const SizedBox(height: 8),
            const Text('Max Duration: 7 days'),
            const SizedBox(height: 8),
            const Text('Max Size: 100 MB'),
            const SizedBox(height: 8),
            const Text('Memory Cache: Enabled'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showClearCacheDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Cache'),
        content: const Text(
          'Are you sure you want to clear all cached files? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _clearCache();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }
}
