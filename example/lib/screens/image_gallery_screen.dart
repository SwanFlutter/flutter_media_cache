// example/lib/screens/image_gallery_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_media_cache/flutter_media_cache.dart';

import '../widgets/shimmer_box.dart';

// ── Sample data ──────────────────────────────────────────────────────────────

const _images = [
  'https://picsum.photos/seed/swan1/800/600',
  'https://picsum.photos/seed/swan2/800/600',
  'https://picsum.photos/seed/swan3/800/600',
  'https://picsum.photos/seed/swan4/800/600',
  'https://picsum.photos/seed/swan5/800/600',
  'https://picsum.photos/seed/swan6/800/600',
  'https://picsum.photos/seed/swan7/800/600',
  'https://picsum.photos/seed/swan8/800/600',
  'https://picsum.photos/seed/swan9/800/600',
  'https://picsum.photos/seed/swan10/800/600',
  'https://picsum.photos/seed/swan11/800/600',
  'https://picsum.photos/seed/swan12/800/600',
];

// ── Screen ───────────────────────────────────────────────────────────────────

class ImageGalleryScreen extends StatelessWidget {
  const ImageGalleryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Image Gallery'),
        actions: [
          IconButton(
            tooltip: 'Clear cache',
            icon: const Icon(Icons.delete_sweep_outlined),
            onPressed: () async {
              await MediaCacheManager.instance.clearAll();
              if (context.mounted) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('Cache cleared!')));
              }
            },
          ),
        ],
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(8),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemCount: _images.length,
        itemBuilder: (context, index) => _ImageCard(url: _images[index]),
      ),
    );
  }
}

// ── Card ─────────────────────────────────────────────────────────────────────

class _ImageCard extends StatelessWidget {
  const _ImageCard({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    final isCached = MediaCacheManager.instance.isCached(url);

    return GestureDetector(
      onTap: () => _openDetail(context),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // ── Cached image ─────────────────────────────────────────────────
            CachedImage(
              imageUrl: url,
              fit: BoxFit.cover,
              // High priority for visible grid items.
              priority: DownloadPriority.high,
              placeholder: const ShimmerBox(),
              errorWidget: const _ErrorCard(),
              fadeInDuration: const Duration(milliseconds: 400),
              // Limit decoded size to save GPU memory.
              memCacheWidth: 400,
              memCacheHeight: 400,
            ),

            // ── Cache status badge ────────────────────────────────────────────
            Positioned(
              top: 6,
              right: 6,
              child: _CacheBadge(isCached: isCached),
            ),
          ],
        ),
      ),
    );
  }

  void _openDetail(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => _ImageDetailScreen(url: url)),
    );
  }
}

// ── Detail screen ─────────────────────────────────────────────────────────────

class _ImageDetailScreen extends StatelessWidget {
  const _ImageDetailScreen({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.white),
            tooltip: 'Remove from cache',
            onPressed: () async {
              await MediaCacheManager.instance.removeEntry(url);
              if (context.mounted) Navigator.of(context).pop();
            },
          ),
        ],
      ),
      // ── Example: custom progress builder on the detail view ───────────────
      body: DownloadProgressBuilder(
        url: url,
        priority: DownloadPriority.high,
        builder: (context, progress, child) {
          // Already cached or completed — show the image.
          if (progress == null || progress.isCompleted) {
            return InteractiveViewer(
              child: Center(
                child: CachedImage(
                  imageUrl: url,
                  fit: BoxFit.contain,
                  priority: DownloadPriority.high,
                ),
              ),
            );
          }

          // Downloading — show a numeric progress overlay.
          final pct = progress.progress;
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 80,
                  height: 80,
                  child: CircularProgressIndicator(
                    value: pct,
                    strokeWidth: 4,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  pct != null
                      ? '${(pct * 100).toStringAsFixed(0)}%'
                      : 'Downloading…',
                  style: const TextStyle(color: Colors.white, fontSize: 18),
                ),
                if (progress.totalBytes != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    '${_kb(progress.bytesDownloaded)} / ${_kb(progress.totalBytes!)} KB',
                    style: const TextStyle(color: Colors.white54, fontSize: 13),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  String _kb(int bytes) => (bytes / 1024).toStringAsFixed(1);
}

// ── Small helpers ─────────────────────────────────────────────────────────────

class _CacheBadge extends StatelessWidget {
  const _CacheBadge({required this.isCached});
  final bool isCached;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: isCached ? Colors.green.shade700 : Colors.black54,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isCached ? Icons.check_circle : Icons.cloud_download,
            color: Colors.white,
            size: 12,
          ),
          const SizedBox(width: 3),
          Text(
            isCached ? 'cached' : 'net',
            style: const TextStyle(color: Colors.white, fontSize: 10),
          ),
        ],
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey.shade200,
      child: const Center(
        child: Icon(Icons.broken_image_outlined, color: Colors.grey, size: 40),
      ),
    );
  }
}
