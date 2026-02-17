import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'media_cache_manager.dart';

/// A widget that displays a cached network image
class CachedImage extends StatefulWidget {
  /// The URL of the image to display
  final String imageUrl;

  /// Widget to display while loading
  final Widget Function(BuildContext context, String url)? placeholder;

  /// Widget to display on error
  final Widget Function(BuildContext context, String url, Object error)?
  errorWidget;

  /// Image fit mode
  final BoxFit fit;

  /// Image width
  final double? width;

  /// Image height
  final double? height;

  /// Border radius
  final BorderRadius? borderRadius;

  const CachedImage({
    super.key,
    required this.imageUrl,
    this.placeholder,
    this.errorWidget,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.borderRadius,
  });

  @override
  State<CachedImage> createState() => _CachedImageState();
}

class _CachedImageState extends State<CachedImage> {
  Uint8List? _imageData;
  bool _isLoading = true;
  bool _hasError = false;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  @override
  void didUpdateWidget(CachedImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl) {
      _loadImage();
    }
  }

  Future<void> _loadImage() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
      _error = null;
    });

    try {
      final data = await MediaCacheManager.instance.getImage(widget.imageUrl);
      if (mounted) {
        setState(() {
          _imageData = data;
          _isLoading = false;
          _hasError = data == null;
          if (data == null) {
            _error = Exception('Failed to load image');
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _error = e;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget child;

    if (_isLoading) {
      child =
          widget.placeholder?.call(context, widget.imageUrl) ??
          const Center(child: CircularProgressIndicator());
    } else if (_hasError || _imageData == null) {
      child =
          widget.errorWidget?.call(
            context,
            widget.imageUrl,
            _error ?? Exception('Unknown error'),
          ) ??
          const Center(
            child: Icon(Icons.error_outline, color: Colors.red, size: 48),
          );
    } else {
      child = Image.memory(
        _imageData!,
        fit: widget.fit,
        width: widget.width,
        height: widget.height,
      );
    }

    if (widget.borderRadius != null) {
      child = ClipRRect(borderRadius: widget.borderRadius!, child: child);
    }

    return SizedBox(width: widget.width, height: widget.height, child: child);
  }
}
