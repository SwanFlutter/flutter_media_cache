// Web video controller helper — no dart:io.
//
// On web, CachedVideo already uses VideoPlayerController.networkUrl() directly
// in cached_video.dart (the kIsWeb branch), so this function is never called.
// It exists only to satisfy the conditional export contract.

import 'package:video_player/video_player.dart';

import '../core/models.dart';

/// Not used on web — [CachedVideo] short-circuits to networkUrl() first.
Future<VideoPlayerController> buildNativeVideoController(
  CacheResult cacheResult,
) async {
  // Should never be reached; web path is handled in cached_video.dart.
  return VideoPlayerController.networkUrl(Uri.parse(cacheResult.url));
}
