import 'package:flutter/material.dart';

import '../core/media_cache_manager.dart';
import '../core/models.dart';

typedef VideoPlayerBuilder =
    Widget Function(BuildContext context, CacheResult cacheResult);

class CachedVideo extends StatefulWidget {
  const CachedVideo({
    super.key,
    required this.videoUrl,
    required this.builder,
    this.placeholder,
    this.errorWidget,
    this.priority = DownloadPriority.normal,
    this.onReady,
    this.onError,
  });

  final String videoUrl;
  final VideoPlayerBuilder builder;
  final Widget? placeholder;
  final Widget? errorWidget;
  final DownloadPriority priority;
  final VoidCallback? onReady;
  final void Function(Object error)? onError;

  @override
  State<CachedVideo> createState() => _CachedVideoState();
}

class _CachedVideoState extends State<CachedVideo> {
  _VideoState _state = _VideoState.loading;
  DownloadProgress? _progress;
  CacheResult? _result;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(CachedVideo old) {
    super.didUpdateWidget(old);
    if (old.videoUrl != widget.videoUrl) {
      setState(() {
        _state = _VideoState.loading;
        _progress = null;
        _result = null;
        _error = null;
      });
      _load();
    }
  }

  Future<void> _load() async {
    if (!MediaCacheManager.isInitialized) {
      _setError('MediaCacheManager not initialized');
      return;
    }

    try {
      final (:result, :progress) = MediaCacheManager.instance
          .getMediaWithProgress(widget.videoUrl, priority: widget.priority);

      progress.listen(
        (p) {
          if (mounted) setState(() => _progress = p);
        },
        onError: (_) {},
        cancelOnError: false,
      );

      final cacheResult = await result;
      if (!mounted) return;

      setState(() {
        _result = cacheResult;
        _state = _VideoState.ready;
      });

      widget.onReady?.call();
    } catch (e) {
      if (mounted) _setError(e.toString());
      widget.onError?.call(e);
    }
  }

  void _setError(String message) {
    setState(() {
      _error = message;
      _state = _VideoState.error;
    });
  }

  @override
  Widget build(BuildContext context) {
    switch (_state) {
      case _VideoState.loading:
        return _buildLoadingState();
      case _VideoState.ready:
        return widget.builder(context, _result!);
      case _VideoState.error:
        return _buildError();
    }
  }

  Widget _buildLoadingState() {
    if (widget.placeholder != null) return widget.placeholder!;

    final progress = _progress?.progress;
    return Container(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (progress != null)
              SizedBox(
                width: 80,
                height: 80,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 3,
                  color: Colors.white,
                ),
              )
            else
              const CircularProgressIndicator(
                strokeWidth: 3,
                color: Colors.white,
              ),
            if (progress != null) ...[
              const SizedBox(height: 12),
              Text(
                '${(progress * 100).toStringAsFixed(0)}%',
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildError() =>
      widget.errorWidget ??
      Container(
        color: Colors.black,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.videocam_off, color: Colors.white54, size: 48),
              const SizedBox(height: 8),
              Text(
                _error ?? 'Failed to load video',
                style: const TextStyle(color: Colors.white54, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
}

enum _VideoState { loading, ready, error }
