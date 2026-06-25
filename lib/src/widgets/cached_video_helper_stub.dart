// Stub — never reached at runtime; always replaced by io or web variant.
import 'package:video_player/video_player.dart';

import '../core/models.dart';

Future<VideoPlayerController> buildNativeVideoController(
  CacheResult cacheResult,
) {
  throw UnsupportedError(
    'buildNativeVideoController: no platform implementation.',
  );
}
