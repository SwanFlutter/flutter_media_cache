// example/lib/screens/stats_screen.dart

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_media_cache/flutter_media_cache.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  late Timer _timer;
  CacheStats? _stats;

  @override
  void initState() {
    super.initState();
    _refresh();
    // Poll stats every second for live feel.
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _refresh());
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void _refresh() {
    if (!MediaCacheManager.isInitialized) return;
    setState(() => _stats = MediaCacheManager.instance.stats);
  }

  @override
  Widget build(BuildContext context) {
    final stats = _stats;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cache Stats'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _refresh),
        ],
      ),
      body: stats == null
          ? const Center(child: Text('Cache not initialized'))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // ── Summary cards row ─────────────────────────────────────
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        icon: Icons.folder_outlined,
                        label: 'Entries',
                        value: stats.totalEntries.toString(),
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        icon: Icons.storage_outlined,
                        label: 'Disk used',
                        value: _formatBytes(stats.totalSizeBytes),
                        color: Colors.purple,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        icon: Icons.bolt_outlined,
                        label: 'Hit rate',
                        value: '${(stats.hitRate * 100).toStringAsFixed(1)}%',
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        icon: Icons.cloud_outlined,
                        label: 'Misses',
                        value: stats.missCount.toString(),
                        color: Colors.orange,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // ── Hit/Miss bar ──────────────────────────────────────────
                Text(
                  'Hit / Miss Ratio',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                _HitMissBar(stats: stats),
                const SizedBox(height: 24),

                // ── Detailed list ─────────────────────────────────────────
                Text(
                  'Details',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                _DetailTile(
                  label: 'Total requests',
                  value: stats.totalRequests.toString(),
                ),
                _DetailTile(
                  label: 'Cache hits',
                  value: stats.hitCount.toString(),
                ),
                _DetailTile(
                  label: 'Cache misses',
                  value: stats.missCount.toString(),
                ),
                _DetailTile(
                  label: 'Evictions (LRU)',
                  value: stats.evictionCount.toString(),
                ),
                _DetailTile(
                  label: 'Disk size',
                  value: _formatBytes(stats.totalSizeBytes),
                ),
                const SizedBox(height: 24),

                // ── Actions ───────────────────────────────────────────────
                Text(
                  'Actions',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                _ActionButton(
                  icon: Icons.auto_delete_outlined,
                  label: 'Remove expired entries',
                  color: Colors.orange,
                  onTap: () async {
                    await MediaCacheManager.instance.clearExpired();
                    _refresh();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Expired entries removed'),
                        ),
                      );
                    }
                  },
                ),
                const SizedBox(height: 8),
                _ActionButton(
                  icon: Icons.delete_sweep_outlined,
                  label: 'Clear entire cache',
                  color: Colors.red,
                  onTap: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text('Clear cache?'),
                        content: const Text(
                          'This will delete all cached media from disk and memory.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Cancel'),
                          ),
                          FilledButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('Clear'),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      await MediaCacheManager.instance.clearAll();
                      _refresh();
                    }
                  },
                ),
              ],
            ),
    );
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / 1024 / 1024).toStringAsFixed(2)} MB';
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

class _HitMissBar extends StatelessWidget {
  const _HitMissBar({required this.stats});
  final CacheStats stats;

  @override
  Widget build(BuildContext context) {
    final total = stats.totalRequests;
    final hitFraction = total == 0 ? 0.0 : stats.hitCount / total;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: hitFraction,
            minHeight: 20,
            backgroundColor: Colors.red.shade100,
            valueColor: AlwaysStoppedAnimation(Colors.green.shade400),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: Colors.green.shade400,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  'Hits: ${stats.hitCount}',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
            Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: Colors.red.shade100,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  'Misses: ${stats.missCount}',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

class _DetailTile extends StatelessWidget {
  const _DetailTile({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      icon: Icon(icon, color: color),
      label: Text(label, style: TextStyle(color: color)),
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: color.withValues(alpha: 0.4)),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      onPressed: onTap,
    );
  }
}
