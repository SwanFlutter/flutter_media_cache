// lib/src/widgets/download_progress_builder.dart

import 'package:flutter/material.dart';

import '../core/media_cache_manager.dart';
import '../core/models.dart';

/// Subscribes to download progress for a given [url] and rebuilds its child
/// whenever a new [DownloadProgress] event arrives.
///
/// Useful for building custom download progress indicators:
///
/// ```dart
/// DownloadProgressBuilder(
///   url: 'https://example.com/video.mp4',
///   builder: (context, progress, child) {
///     if (progress == null) return child!;
///     return Column(
///       children: [
///         LinearProgressIndicator(value: progress.progress),
///         Text('${progress.bytesDownloaded} / ${progress.totalBytes ?? "?"} bytes'),
///       ],
///     );
///   },
///   child: const Icon(Icons.download),
/// )
/// ```
class DownloadProgressBuilder extends StatefulWidget {
  const DownloadProgressBuilder({
    super.key,
    required this.url,
    required this.builder,
    this.child,
    this.priority = DownloadPriority.normal,
    this.onComplete,
    this.onError,
  });

  final String url;
  final Widget Function(
    BuildContext context,
    DownloadProgress? progress,
    Widget? child,
  )
  builder;
  final Widget? child;
  final DownloadPriority priority;
  final void Function(CacheResult result)? onComplete;
  final void Function(Object error)? onError;

  @override
  State<DownloadProgressBuilder> createState() =>
      _DownloadProgressBuilderState();
}

class _DownloadProgressBuilderState extends State<DownloadProgressBuilder> {
  DownloadProgress? _progress;

  @override
  void initState() {
    super.initState();
    _start();
  }

  @override
  void didUpdateWidget(DownloadProgressBuilder old) {
    super.didUpdateWidget(old);
    if (old.url != widget.url) {
      setState(() => _progress = null);
      _start();
    }
  }

  void _start() {
    if (!MediaCacheManager.isInitialized) return;

    final (:result, :progress) = MediaCacheManager.instance
        .getMediaWithProgress(widget.url, priority: widget.priority);

    progress.listen(
      (p) {
        if (mounted) setState(() => _progress = p);
      },
      onError: (e) {
        widget.onError?.call(e);
      },
      cancelOnError: false,
    );

    result.then(
      (r) {
        if (mounted) widget.onComplete?.call(r);
      },
      onError: (e) {
        if (mounted) widget.onError?.call(e);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, _progress, widget.child);
  }
}
