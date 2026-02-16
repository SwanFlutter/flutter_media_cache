import 'package:flutter/material.dart';

import 'media_cache_manager.dart';

/// A widget that provides cached video file path (or bytes on web)
class CachedVideo extends StatefulWidget {
  /// The URL of the video to cache
  final String videoUrl;

  /// Builder function that receives the cached video file (or bytes on web)
  /// On native platforms: receives File?
  /// On web platform: receives Uint8List?
  final Widget Function(BuildContext context, dynamic videoData) builder;

  /// Widget to display while loading
  final Widget? placeholder;

  /// Widget to display on error
  final Widget? errorWidget;

  const CachedVideo({
    super.key,
    required this.videoUrl,
    required this.builder,
    this.placeholder,
    this.errorWidget,
  });

  @override
  State<CachedVideo> createState() => _CachedVideoState();
}

class _CachedVideoState extends State<CachedVideo> {
  dynamic _videoData;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadVideo();
  }

  @override
  void didUpdateWidget(CachedVideo oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoUrl != widget.videoUrl) {
      _loadVideo();
    }
  }

  Future<void> _loadVideo() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final data = await MediaCacheManager.instance.getVideo(widget.videoUrl);
      if (mounted) {
        setState(() {
          _videoData = data;
          _isLoading = false;
          _hasError = data == null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return widget.placeholder ??
          const Center(child: CircularProgressIndicator());
    }

    if (_hasError || _videoData == null) {
      return widget.errorWidget ??
          const Center(
            child: Icon(Icons.error_outline, color: Colors.red, size: 48),
          );
    }

    return widget.builder(context, _videoData);
  }
}
