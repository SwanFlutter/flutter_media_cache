// example/lib/screens/preload_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_media_cache/flutter_media_cache.dart';

import '../widgets/shimmer_box.dart';

// ── Sample URLs ───────────────────────────────────────────────────────────────

const _preloadUrls = [
  'https://picsum.photos/seed/pre1/600/400',
  'https://picsum.photos/seed/pre2/600/400',
  'https://picsum.photos/seed/pre3/600/400',
  'https://picsum.photos/seed/pre4/600/400',
  'https://picsum.photos/seed/pre5/600/400',
  'https://picsum.photos/seed/pre6/600/400',
];

// ── Screen ────────────────────────────────────────────────────────────────────

class PreloadScreen extends StatefulWidget {
  const PreloadScreen({super.key});

  @override
  State<PreloadScreen> createState() => _PreloadScreenState();
}

class _PreloadScreenState extends State<PreloadScreen> {
  bool _preloading = false;
  bool _preloaded = false;
  final Map<String, bool> _cachedMap = {};

  Future<void> _runPreload() async {
    setState(() {
      _preloading = true;
      _preloaded = false;
    });

    // preloadAll uses low priority so it doesn't block visible content.
    await MediaCacheManager.instance.preloadAll(
      _preloadUrls,
      priority: DownloadPriority.low,
    );

    final map = {
      for (final u in _preloadUrls) u: MediaCacheManager.instance.isCached(u),
    };

    setState(() {
      _preloading = false;
      _preloaded = true;
      _cachedMap.addAll(map);
    });
  }

  Future<void> _clearAll() async {
    await MediaCacheManager.instance.clearAll();
    setState(() {
      _preloaded = false;
      _cachedMap.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Preload Demo'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined),
            tooltip: 'Clear all',
            onPressed: _clearAll,
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Info banner ───────────────────────────────────────────────────
          _InfoBanner(preloaded: _preloaded),

          // ── Preload button ────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                icon: _preloading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.download_for_offline_outlined),
                label: Text(
                  _preloading
                      ? 'Preloading ${_preloadUrls.length} images…'
                      : 'Preload all images (low priority)',
                ),
                onPressed: _preloading ? null : _runPreload,
              ),
            ),
          ),

          // ── Priority demo ─────────────────────────────────────────────────
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: _PriorityDemo(),
          ),

          const SizedBox(height: 16),

          // ── Grid ──────────────────────────────────────────────────────────
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: _preloadUrls.length,
              itemBuilder: (context, i) {
                final url = _preloadUrls[i];
                final cached = _cachedMap[url] ?? false;
                return _PreloadTile(url: url, cached: cached);
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── Priority demo card ────────────────────────────────────────────────────────

class _PriorityDemo extends StatefulWidget {
  const _PriorityDemo();

  @override
  State<_PriorityDemo> createState() => _PriorityDemoState();
}

class _PriorityDemoState extends State<_PriorityDemo> {
  // Three URLs — one per priority level.
  static const _high = 'https://picsum.photos/seed/high/600/400';
  static const _normal = 'https://picsum.photos/seed/normal/600/400';
  static const _low = 'https://picsum.photos/seed/low/600/400';

  bool _started = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Priority Queue Demo',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'All three downloads start at the same time. '
              'High-priority finishes first even though network is shared.',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _PriorityTile(
                  label: 'HIGH',
                  url: _high,
                  color: Colors.red.shade400,
                  priority: DownloadPriority.high,
                  visible: _started,
                ),
                const SizedBox(width: 8),
                _PriorityTile(
                  label: 'NORMAL',
                  url: _normal,
                  color: Colors.orange.shade400,
                  priority: DownloadPriority.normal,
                  visible: _started,
                ),
                const SizedBox(width: 8),
                _PriorityTile(
                  label: 'LOW',
                  url: _low,
                  color: Colors.grey.shade400,
                  priority: DownloadPriority.low,
                  visible: _started,
                ),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () async {
                  // Clear so we can see a fresh download each time.
                  await MediaCacheManager.instance.removeEntry(_high);
                  await MediaCacheManager.instance.removeEntry(_normal);
                  await MediaCacheManager.instance.removeEntry(_low);
                  setState(() => _started = false);
                  await Future<void>.delayed(const Duration(milliseconds: 50));
                  setState(() => _started = true);
                },
                child: const Text('Start all downloads'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PriorityTile extends StatelessWidget {
  const _PriorityTile({
    required this.label,
    required this.url,
    required this.color,
    required this.priority,
    required this.visible,
  });

  final String label;
  final String url;
  final Color color;
  final DownloadPriority priority;
  final bool visible;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: color.withValues(alpha: 0.5)),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: visible
                ? CachedImage(
                    imageUrl: url,
                    width: double.infinity,
                    height: 70,
                    fit: BoxFit.cover,
                    priority: priority,
                    placeholder: const ShimmerBox(height: 70),
                  )
                : ShimmerBox(height: 70, width: double.infinity),
          ),
        ],
      ),
    );
  }
}

// ── Preload tile ──────────────────────────────────────────────────────────────

class _PreloadTile extends StatelessWidget {
  const _PreloadTile({required this.url, required this.cached});
  final String url;
  final bool cached;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: CachedImage(
            imageUrl: url,
            fit: BoxFit.cover,
            priority: DownloadPriority.normal,
            placeholder: const ShimmerBox(),
          ),
        ),
        if (cached)
          Positioned(
            bottom: 4,
            right: 4,
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: Colors.green.shade600,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check, size: 10, color: Colors.white),
            ),
          ),
      ],
    );
  }
}

// ── Info banner ───────────────────────────────────────────────────────────────

class _InfoBanner extends StatelessWidget {
  const _InfoBanner({required this.preloaded});
  final bool preloaded;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      color: preloaded ? Colors.green.shade50 : Colors.blue.shade50,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Icon(
            preloaded ? Icons.offline_bolt : Icons.info_outline,
            size: 18,
            color: preloaded ? Colors.green.shade700 : Colors.blue.shade700,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              preloaded
                  ? 'All images cached! Turn off Wi-Fi — they still load instantly.'
                  : 'Tap "Preload" to cache all images in the background.',
              style: TextStyle(
                fontSize: 12,
                color: preloaded ? Colors.green.shade800 : Colors.blue.shade800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
