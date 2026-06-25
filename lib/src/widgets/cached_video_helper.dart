/// Conditional export — resolves to the IO or web helper at compile time.
///
/// On web  → [cached_video_helper_web.dart] (no dart:io).
/// On other → [cached_video_helper_io.dart]  (dart:io File usage).
library;

export 'cached_video_helper_stub.dart'
    if (dart.library.io) 'cached_video_helper_io.dart'
    if (dart.library.html) 'cached_video_helper_web.dart';
