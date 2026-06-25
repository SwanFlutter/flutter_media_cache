// lib/src/widgets/cached_image.dart

import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../core/media_cache_manager.dart';
import '../core/models.dart';

/// A drop-in replacement for [Image.network] that caches images using
/// [MediaCacheManager].
///
/// Features:
///   - Memory + disk caching with LRU eviction
///   - Smooth fade-in transition
///   - Configurable placeholder and error widgets
///   - Download priority support
///   - Real-time download progress
///
/// ```dart
/// CachedImage(
///   imageUrl: 'https://picsum.photos/400/300',
///   width: 400,
///   height: 300,
///   fit: BoxFit.cover,
///   borderRadius: BorderRadius.circular(12),
/// )
/// ```
class CachedImage extends StatefulWidget {
  const CachedImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.alignment = Alignment.center,
    this.borderRadius,
    this.color,
    this.colorBlendMode,
    this.placeholder,
    this.errorWidget,
    this.progressIndicatorBuilder,
    this.fadeInDuration = const Duration(milliseconds: 300),
    this.priority = DownloadPriority.normal,
    this.memCacheWidth,
    this.memCacheHeight,
  });

  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Alignment alignment;
  final BorderRadius? borderRadius;
  final Color? color;
  final BlendMode? colorBlendMode;

  /// Widget shown while loading. Defaults to a grey shimmer.
  final Widget? placeholder;

  /// Widget shown on error. Defaults to an error icon.
  final Widget? errorWidget;

  /// Builder that receives [DownloadProgress]. If set, [placeholder] is ignored
  /// while downloading.
  final Widget Function(BuildContext, String, DownloadProgress)?
  progressIndicatorBuilder;

  final Duration fadeInDuration;
  final DownloadPriority priority;

  /// Resize hints passed to [ResizeImage] to reduce memory footprint.
  final int? memCacheWidth;
  final int? memCacheHeight;

  @override
  State<CachedImage> createState() => _CachedImageState();
}

class _CachedImageState extends State<CachedImage>
    with SingleTickerProviderStateMixin {
  _LoadState _state = _LoadState.loading;
  Uint8List? _bytes;
  DownloadProgress? _progress;
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: widget.fadeInDuration,
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeIn);
    _load();
  }

  @override
  void didUpdateWidget(CachedImage old) {
    super.didUpdateWidget(old);
    if (old.imageUrl != widget.imageUrl) {
      setState(() {
        _state = _LoadState.loading;
        _bytes = null;
        _progress = null;
      });
      _fadeCtrl.reset();
      _load();
    }
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (!MediaCacheManager.isInitialized) {
      if (mounted) setState(() => _state = _LoadState.error);
      return;
    }

    try {
      final (:result, :progress) = MediaCacheManager.instance
          .getMediaWithProgress(widget.imageUrl, priority: widget.priority);

      progress.listen(
        (p) {
          if (mounted) setState(() => _progress = p);
        },
        onError: (_) {},
        cancelOnError: false,
      );

      final cacheResult = await result;
      if (!mounted) return;

      if (cacheResult.bytes != null && cacheResult.bytes!.isNotEmpty) {
        setState(() {
          _bytes = cacheResult.bytes;
          _state = _LoadState.loaded;
        });
        _fadeCtrl.forward();
      } else {
        setState(() => _state = _LoadState.error);
      }
    } catch (_) {
      if (mounted) setState(() => _state = _LoadState.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget child;

    switch (_state) {
      case _LoadState.loading:
        child = widget.progressIndicatorBuilder != null && _progress != null
            ? widget.progressIndicatorBuilder!(
                context,
                widget.imageUrl,
                _progress!,
              )
            : _buildPlaceholder();

      case _LoadState.loaded:
        child = FadeTransition(opacity: _fadeAnim, child: _buildImage(_bytes!));

      case _LoadState.error:
        child = _buildError();
    }

    final sized = SizedBox(
      width: widget.width,
      height: widget.height,
      child: child,
    );

    if (widget.borderRadius != null) {
      return ClipRRect(borderRadius: widget.borderRadius!, child: sized);
    }
    return sized;
  }

  Widget _buildImage(Uint8List bytes) {
    ImageProvider provider = MemoryImage(bytes);
    if (widget.memCacheWidth != null || widget.memCacheHeight != null) {
      provider = ResizeImage(
        provider,
        width: widget.memCacheWidth,
        height: widget.memCacheHeight,
      );
    }
    return Image(
      image: provider,
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      alignment: widget.alignment,
      color: widget.color,
      colorBlendMode: widget.colorBlendMode,
      gaplessPlayback: true,
    );
  }

  Widget _buildPlaceholder() =>
      widget.placeholder ??
      Container(
        width: widget.width,
        height: widget.height,
        color: Colors.grey.shade200,
        child: const Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );

  Widget _buildError() =>
      widget.errorWidget ??
      Container(
        width: widget.width,
        height: widget.height,
        color: Colors.grey.shade100,
        child: Icon(
          Icons.broken_image_outlined,
          color: Colors.grey.shade400,
          size: 32,
        ),
      );
}

enum _LoadState { loading, loaded, error }
