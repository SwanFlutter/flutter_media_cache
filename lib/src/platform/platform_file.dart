/// Conditional import entry point for platform-specific file/storage ops.
///
/// On web  → uses [WebPlatformFile] (no dart:io, memory only).
/// On other → uses [IoPlatformFile]  (dart:io, full disk access).
library;

export 'platform_file_stub.dart'
    if (dart.library.io) 'platform_file_io.dart'
    if (dart.library.html) 'platform_file_web.dart';
