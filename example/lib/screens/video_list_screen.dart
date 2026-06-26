// example/lib/screens/video_list_screen.dart
//
// This example uses the builder pattern of CachedVideo. The user provides
// their own video player widget — any package that accepts a file path or
// network URL works. In this demo we use a simple placeholder; swap it
// with your preferred video player package.

import 'package:flutter/material.dart';
import 'package:flutter_media_cache/flutter_media_cache.dart';

// ── Sample data ───────────────────────────────────────────────────────────────

class _VideoItem {
  const _VideoItem({
    required this.title,
    required this.url,
    required this.desc,
  });
  final String title;
  final String url;
  final String desc;
}

const _videos = [
  _VideoItem(
    title: 'Big Buck Bunny — Clip 1',
    url:
        'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
    desc:
        'Classic open-source animation. First play downloads & caches. '
        'Disconnect Wi-Fi then replay — still works!',
  ),
  _VideoItem(
    title: 'Elephant Dream',
    url:
        'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4',
    desc: 'Blender Foundation open movie. Cached on first view.',
  ),
  _VideoItem(
    title: 'For Bigger Blazes',
    url:
        'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4',
    desc: 'Short sample clip for testing fast cache hits.',
  ),
];

// ── Screen ────────────────────────────────────────────────────────────────────

class VideoListScreen extends StatelessWidget {
  const VideoListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Video Cache')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _videos.length,
        separatorBuilder: (_, _) => const SizedBox(height: 24),
        itemBuilder: (_, i) => _VideoCard(item: _videos[i]),
      ),
    );
  }
}

// ── Card ──────────────────────────────────────────────────────────────────────

class _VideoCard extends StatelessWidget {
  const _VideoCard({required this.item});
  final _VideoItem item;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── CachedVideo widget ─────────────────────────────────────────────
          CachedVideo(
            videoUrl: item.url,

            // Builder receives the CacheResult. Use whatever video player
            // package you like — here we just show the cached path.
            builder: (context, result) => AspectRatio(
              aspectRatio: 16 / 9,
              child: Container(
                color: Colors.black87,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.play_circle_outline,
                        color: Colors.white,
                        size: 64,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        result.isFromCache ? 'Cached' : 'Network',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                      if (result.filePath != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            result.filePath!,
                            style: const TextStyle(
                              color: Colors.white38,
                              fontSize: 10,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),

            priority: DownloadPriority.normal,

            // Custom loading state with byte-level progress.
            placeholder: _VideoLoadingOverlay(url: item.url),

            errorWidget: Container(
              color: Colors.black87,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.videocam_off, color: Colors.white54, size: 48),
                    SizedBox(height: 8),
                    Text(
                      'Failed to load video',
                      style: TextStyle(color: Colors.white54),
                    ),
                  ],
                ),
              ),
            ),

            onReady: () => debugPrint('✅ ${item.title} ready'),
            onError: (e) => debugPrint('❌ ${item.title}: $e'),
          ),

          // ── Metadata ───────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.title,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                    // Show cache status badge.
                    _CacheStatusChip(url: item.url),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  item.desc,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
                ),
                const SizedBox(height: 10),
                // Remove from cache button.
                TextButton.icon(
                  icon: const Icon(Icons.delete_outline, size: 16),
                  label: const Text('Remove from cache'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red.shade400,
                    padding: EdgeInsets.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  onPressed: () async {
                    await MediaCacheManager.instance.removeEntry(item.url);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Removed "${item.title}" from cache'),
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Loading overlay with real-time byte progress ──────────────────────────────

class _VideoLoadingOverlay extends StatefulWidget {
  const _VideoLoadingOverlay({required this.url});
  final String url;

  @override
  State<_VideoLoadingOverlay> createState() => _VideoLoadingOverlayState();
}

class _VideoLoadingOverlayState extends State<_VideoLoadingOverlay> {
  DownloadProgress? _progress;

  @override
  void initState() {
    super.initState();
    if (!MediaCacheManager.isInitialized) return;

    final (:result, :progress) = MediaCacheManager.instance
        .getMediaWithProgress(widget.url);

    progress.listen(
      (p) {
        if (mounted) setState(() => _progress = p);
      },
      onError: (_) {},
      cancelOnError: false,
    );

    // Ignore result here — CachedVideo handles it.
    result.ignore();
  }

  @override
  Widget build(BuildContext context) {
    final p = _progress;
    final pct = p?.progress;
    final downloaded = p?.bytesDownloaded ?? 0;
    final total = p?.totalBytes;

    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Container(
        color: Colors.black,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 64,
                height: 64,
                child: CircularProgressIndicator(
                  value: pct,
                  strokeWidth: 3,
                  color: Colors.white,
                  backgroundColor: Colors.white12,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                pct != null
                    ? '${(pct * 100).toStringAsFixed(0)}%'
                    : 'Connecting…',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (total != null) ...[
                const SizedBox(height: 4),
                Text(
                  '${_mb(downloaded)} / ${_mb(total)} MB',
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: 200,
                  child: LinearProgressIndicator(
                    value: pct,
                    minHeight: 4,
                    borderRadius: BorderRadius.circular(4),
                    color: Colors.deepPurpleAccent,
                    backgroundColor: Colors.white12,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _mb(int bytes) => (bytes / 1024 / 1024).toStringAsFixed(1);
}

// ── Cache status chip ─────────────────────────────────────────────────────────

class _CacheStatusChip extends StatefulWidget {
  const _CacheStatusChip({required this.url});
  final String url;

  @override
  State<_CacheStatusChip> createState() => _CacheStatusChipState();
}

class _CacheStatusChipState extends State<_CacheStatusChip> {
  bool get _cached =>
      MediaCacheManager.isInitialized &&
      MediaCacheManager.instance.isCached(widget.url);

  @override
  Widget build(BuildContext context) {
    final cached = _cached;
    return Chip(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      avatar: Icon(
        cached ? Icons.check_circle : Icons.cloud_download_outlined,
        size: 14,
        color: cached ? Colors.green : Colors.grey,
      ),
      label: Text(
        cached ? 'Cached' : 'Not cached',
        style: TextStyle(
          fontSize: 11,
          color: cached ? Colors.green.shade700 : Colors.grey.shade600,
        ),
      ),
      backgroundColor: cached ? Colors.green.shade50 : Colors.grey.shade100,
      side: BorderSide.none,
    );
  }
}
