/// Fallback stub — should never be reached at runtime.
///
/// The conditional export in [platform_file.dart] always resolves to either
/// the io or web implementation before this stub is used.
library;

import 'dart:typed_data';

/// Abstract interface for platform-specific storage operations.
abstract class PlatformStorage {
  /// Initialises the storage layer (e.g. creates cache directory).
  Future<void> init(String subdirectoryName);

  /// Writes [bytes] to persistent storage and returns the local path/key.
  /// Returns null on platforms without persistent storage (web).
  Future<String?> write(String key, String ext, Uint8List bytes);

  /// Reads bytes for [localPath]. Returns null if not found.
  Future<Uint8List?> read(String localPath);

  /// Deletes the file at [localPath]. No-op on web.
  Future<void> delete(String localPath);

  /// Returns true if [localPath] exists on disk.
  Future<bool> exists(String localPath);

  /// Deletes all files in the cache directory except the index.
  Future<void> deleteAll();

  /// True if this platform supports disk persistence.
  bool get hasDisk;

  /// Root directory path. Empty string on web.
  String get cacheDir;

  /// The index file used for persistence. Null on web.
  Object? get indexFile;
}

/// Optional mixin for [PlatformStorage] implementations that support
/// purging files not in a known set.
mixin OrphanPurgeable on PlatformStorage {
  Future<void> purgeOrphans(Set<String> knownPaths);
}

/// Returns a [PlatformStorage] for the current platform.
PlatformStorage createPlatformStorage() =>
    throw UnsupportedError('No platform implementation available.');
