/// Web implementation — no dart:io, memory-only storage.
///
/// On web there is no persistent file system, so all "disk" operations
/// become no-ops or in-memory operations.
library;

import 'dart:typed_data';

import 'platform_file_stub.dart';

class _WebPlatformStorage implements PlatformStorage {
  @override
  bool get hasDisk => false;

  @override
  String get cacheDir => '';

  @override
  Object? get indexFile => null;

  @override
  Future<void> init(String subdirectoryName) async {
    // Nothing to initialise on web.
  }

  @override
  Future<String?> write(String key, String ext, Uint8List bytes) async {
    // Web has no disk; bytes are kept in LruMemoryCache only.
    return null;
  }

  @override
  Future<Uint8List?> read(String localPath) async => null;

  @override
  Future<void> delete(String localPath) async {}

  @override
  Future<bool> exists(String localPath) async => false;

  @override
  Future<void> deleteAll() async {}
}

/// Returns the web [PlatformStorage] (memory-only).
PlatformStorage createPlatformStorage() => _WebPlatformStorage();
