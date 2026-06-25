/// Native (Android / iOS / macOS / Windows / Linux) implementation.
///
/// Uses dart:io for full disk read/write and path_provider_master for the
/// system cache directory.
library;

import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider_master/path_provider_master.dart';

import 'platform_file_stub.dart';

class _IoPlatformStorage extends PlatformStorage with OrphanPurgeable {
  Directory? _dir;
  File? _idxFile;

  @override
  bool get hasDisk => true;

  @override
  String get cacheDir => _dir?.path ?? '';

  @override
  Object? get indexFile => _idxFile;

  @override
  Future<void> init(String subdirectoryName) async {
    final base = await PathProviderMaster.getTemporaryDirectory();
    _dir = Directory('${base!.path}/$subdirectoryName');
    await _dir!.create(recursive: true);
    _idxFile = File('${_dir!.path}/_index.json');
  }

  @override
  Future<String?> write(String key, String ext, Uint8List bytes) async {
    final path = '${_dir!.path}/$key$ext';
    await File(path).writeAsBytes(bytes, flush: true);
    return path;
  }

  @override
  Future<Uint8List?> read(String localPath) async {
    final f = File(localPath);
    if (!await f.exists()) return null;
    return f.readAsBytes();
  }

  @override
  Future<void> delete(String localPath) async {
    final f = File(localPath);
    if (await f.exists()) await f.delete();
  }

  @override
  Future<bool> exists(String localPath) => File(localPath).exists();

  @override
  Future<void> deleteAll() async {
    if (_dir == null || !await _dir!.exists()) return;
    await for (final entity in _dir!.list()) {
      if (entity is File && !entity.path.endsWith('_index.json')) {
        await entity.delete();
      }
    }
  }

  /// Deletes any files in the cache directory that are not in [knownPaths].
  @override
  Future<void> purgeOrphans(Set<String> knownPaths) async {
    if (_dir == null || !await _dir!.exists()) return;
    await for (final entity in _dir!.list()) {
      if (entity is File &&
          !entity.path.endsWith('_index.json') &&
          !knownPaths.contains(entity.path)) {
        await entity.delete();
      }
    }
  }
}

/// Returns the IO-backed [PlatformStorage] for native platforms.
PlatformStorage createPlatformStorage() => _IoPlatformStorage();
