// lib/src/widgets/cached_video.dart

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../core/media_cache_manager.dart';
import '../core/models.dart';

/// A cached video player widget built on top of [video_player].
///
/// Automatically downloads and caches the video file on first view,
/// then serves from disk on subsequent plays — even offline.
///
/// ```dart
/// CachedVideo(
///   videoUrl: 'https://example.com/video.mp4',
///   autoPlay: false,
///   showControls: true,
///   aspectRatio: 16 / 9,
/// )
/// ```
class CachedVideo extends StatefulWidget {
  const CachedVideo({
    super.key,
    required this.videoUrl,
    this.autoPlay = false,
    this.looping = false,
    this.showControls = true,
    this.aspectRatio = 16 / 9,
    this.placeholder,
    this.errorWidget,
    this.priority = DownloadPriority.normal,
    this.onReady,
    this.onError,
  });

  final String videoUrl;
  final bool autoPlay;
  final bool looping;
  final bool showControls;
  final double aspectRatio;
  final Widget? placeholder;
  final Widget? errorWidget;
  final DownloadPriority priority;
  final VoidCallback? onReady;
  final void Function(Object error)? onError;

  @override
  State<CachedVideo> createState() => _CachedVideoState();
}

class _CachedVideoState extends State<CachedVideo> {
  VideoPlayerController? _controller;
  _VideoState _state = _VideoState.loading;
  DownloadProgress? _progress;
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
      _controller?.dispose();
      _controller = null;
      setState(() {
        _state = _VideoState.loading;
        _progress = null;
        _error = null;
      });
      _load();
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (!MediaCacheManager.isInitialized) {
      _setError('MediaCacheManager not initialized');
      return;
    }

    try {
      final (:result, :progress) = MediaCacheManager.instance
          .getMediaWithProgress(widget.videoUrl, priority: widget.priority);

      // Listen to download progress for UI feedback.
      progress.listen(
        (p) {
          if (mounted) setState(() => _progress = p);
        },
        onError: (_) {},
        cancelOnError: false,
      );

      final cacheResult = await result;
      if (!mounted) return;

      // On native platforms use the local file path for best performance.
      final filePath = cacheResult.filePath;
      if (filePath == null || filePath.isEmpty) {
        _setError('Video file path unavailable on this platform');
        return;
      }

      final file = File(filePath);
      if (!await file.exists()) {
        _setError('Cached file missing: $filePath');
        return;
      }

      final controller = VideoPlayerController.file(file);
      await controller.initialize();
      controller.setLooping(widget.looping);
      if (widget.autoPlay) await controller.play();

      if (!mounted) {
        controller.dispose();
        return;
      }

      setState(() {
        _controller = controller;
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
    return AspectRatio(aspectRatio: widget.aspectRatio, child: _buildContent());
  }

  Widget _buildContent() {
    switch (_state) {
      case _VideoState.loading:
        return _buildLoadingState();
      case _VideoState.ready:
        return _buildPlayer();
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

  Widget _buildPlayer() {
    final controller = _controller!;
    return Stack(
      alignment: Alignment.center,
      children: [
        VideoPlayer(controller),
        if (widget.showControls) _VideoControls(controller: controller),
      ],
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

// ── Minimal built-in controls ──────────────────────────────────────────────

class _VideoControls extends StatefulWidget {
  const _VideoControls({required this.controller});
  final VideoPlayerController controller;

  @override
  State<_VideoControls> createState() => _VideoControlsState();
}

class _VideoControlsState extends State<_VideoControls> {
  bool _visible = true;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_refresh);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = widget.controller;
    final position = ctrl.value.position;
    final duration = ctrl.value.duration;
    final isPlaying = ctrl.value.isPlaying;

    return GestureDetector(
      onTap: () => setState(() => _visible = !_visible),
      child: AnimatedOpacity(
        opacity: _visible ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 200),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.transparent, Colors.black54],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              VideoProgressIndicator(
                ctrl,
                allowScrubbing: true,
                colors: VideoProgressColors(
                  playedColor: Theme.of(context).colorScheme.primary,
                  bufferedColor: Colors.white38,
                  backgroundColor: Colors.white12,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        isPlaying ? Icons.pause : Icons.play_arrow,
                        color: Colors.white,
                      ),
                      onPressed: () => isPlaying ? ctrl.pause() : ctrl.play(),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${_fmt(position)} / ${_fmt(duration)}',
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: Icon(
                        ctrl.value.volume > 0
                            ? Icons.volume_up
                            : Icons.volume_off,
                        color: Colors.white,
                      ),
                      onPressed: () =>
                          ctrl.setVolume(ctrl.value.volume > 0 ? 0 : 1),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}

enum _VideoState { loading, ready, error }
