// Native (Android / iOS / macOS / Windows / Linux) video controller helper.
// Uses dart:io File — compiled out on web.

import 'dart:io';

import 'package:video_player/video_player.dart';

import '../core/exceptions.dart';
import '../core/models.dart';

/// Builds a [VideoPlayerController] backed by the locally cached file.
///
/// Throws [StorageException] when the cached file path is missing or the
/// file no longer exists on disk.
Future<VideoPlayerController> buildNativeVideoController(
  CacheResult cacheResult,
) async {
  final filePath = cacheResult.filePath;
  if (filePath == null || filePath.isEmpty) {
    throw const StorageException(
      'Video file path unavailable on this platform',
    );
  }

  final file = File(filePath);
  if (!await file.exists()) {
    throw StorageException('Cached file missing: $filePath');
  }

  return VideoPlayerController.file(file);
}
