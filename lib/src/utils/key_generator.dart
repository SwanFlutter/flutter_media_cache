// lib/src/utils/key_generator.dart

import 'dart:convert';

import 'package:crypto/crypto.dart';

import '../core/models.dart';

/// Generates a deterministic, filesystem-safe cache key from a URL.
///
/// Uses SHA-256 to avoid collisions and to keep filenames short and uniform.
abstract final class KeyGenerator {
  /// Returns a 64-character hex string derived from [url].
  static String fromUrl(String url) {
    final bytes = utf8.encode(url.trim());
    return sha256.convert(bytes).toString();
  }

  /// Infers [MediaType] from URL or Content-Type header.
  static MediaType mediaTypeOf(String url, {String? contentType}) {
    final ct = contentType?.toLowerCase() ?? '';
    if (ct.startsWith('image/')) return MediaType.image;
    if (ct.startsWith('video/')) return MediaType.video;

    final lower = url.toLowerCase().split('?').first;
    if (_imageExts.any(lower.endsWith)) return MediaType.image;
    if (_videoExts.any(lower.endsWith)) return MediaType.video;
    return MediaType.unknown;
  }

  /// Returns the file extension to use for a cached file.
  static String extensionFor(String url, {String? contentType}) {
    final ct = contentType?.toLowerCase().split(';').first.trim() ?? '';
    final fromCt = _mimeToExt[ct];
    if (fromCt != null) return fromCt;

    final lower = url.toLowerCase().split('?').first;
    for (final ext in {..._imageExts, ..._videoExts}) {
      if (lower.endsWith(ext)) return ext;
    }
    return '';
  }

  static const _imageExts = {
    '.jpg',
    '.jpeg',
    '.png',
    '.gif',
    '.webp',
    '.bmp',
    '.svg',
    '.ico',
  };

  static const _videoExts = {
    '.mp4',
    '.mov',
    '.avi',
    '.mkv',
    '.webm',
    '.m4v',
    '.ts',
  };

  static const _mimeToExt = {
    'image/jpeg': '.jpg',
    'image/png': '.png',
    'image/gif': '.gif',
    'image/webp': '.webp',
    'image/bmp': '.bmp',
    'image/svg+xml': '.svg',
    'video/mp4': '.mp4',
    'video/quicktime': '.mov',
    'video/x-msvideo': '.avi',
    'video/x-matroska': '.mkv',
    'video/webm': '.webm',
  };
}
