// lib/src/core/models.dart
// ignore_for_file: constant_identifier_names

import 'dart:typed_data';

/// Priority of a download task.
enum DownloadPriority {
  /// For UI-visible items (e.g. currently visible list items).
  high,

  /// Default priority for normal requests.
  normal,

  /// For prefetch / preload operations.
  low,
}

/// Current status of a [DownloadTask].
enum DownloadStatus { queued, downloading, completed, failed, cancelled }

/// Type of media being cached.
enum MediaType { image, video, unknown }

/// Immutable snapshot of a download's progress.
class DownloadProgress {
  const DownloadProgress({
    required this.url,
    required this.status,
    this.bytesDownloaded = 0,
    this.totalBytes,
    this.error,
  });

  final String url;
  final DownloadStatus status;
  final int bytesDownloaded;
  final int? totalBytes;
  final Object? error;

  double? get progress => (totalBytes != null && totalBytes! > 0)
      ? bytesDownloaded / totalBytes!
      : null;

  bool get isCompleted => status == DownloadStatus.completed;
  bool get isFailed => status == DownloadStatus.failed;
  bool get isActive =>
      status == DownloadStatus.queued || status == DownloadStatus.downloading;

  @override
  String toString() =>
      'DownloadProgress(url: $url, status: $status, '
      'bytes: $bytesDownloaded/${totalBytes ?? "?"})';
}

/// A single record stored in the cache index.
class CacheEntry {
  CacheEntry({
    required this.url,
    required this.key,
    required this.localPath,
    required this.mediaType,
    required this.createdAt,
    required this.lastAccessedAt,
    required this.sizeBytes,
    this.etag,
    this.lastModified,
    this.contentType,
  });

  final String url;

  /// SHA-256 hash of the URL used as the filename.
  final String key;

  final String localPath;
  final MediaType mediaType;
  final DateTime createdAt;
  DateTime lastAccessedAt;
  final int sizeBytes;

  /// HTTP ETag for conditional GET.
  final String? etag;

  /// HTTP Last-Modified for conditional GET.
  final String? lastModified;

  final String? contentType;

  bool isExpired(Duration maxAge) =>
      DateTime.now().difference(createdAt) > maxAge;

  CacheEntry copyWithAccess() => CacheEntry(
    url: url,
    key: key,
    localPath: localPath,
    mediaType: mediaType,
    createdAt: createdAt,
    lastAccessedAt: DateTime.now(),
    sizeBytes: sizeBytes,
    etag: etag,
    lastModified: lastModified,
    contentType: contentType,
  );

  Map<String, dynamic> toJson() => {
    'url': url,
    'key': key,
    'localPath': localPath,
    'mediaType': mediaType.name,
    'createdAt': createdAt.toIso8601String(),
    'lastAccessedAt': lastAccessedAt.toIso8601String(),
    'sizeBytes': sizeBytes,
    if (etag != null) 'etag': etag,
    if (lastModified != null) 'lastModified': lastModified,
    if (contentType != null) 'contentType': contentType,
  };

  factory CacheEntry.fromJson(Map<String, dynamic> json) => CacheEntry(
    url: json['url'] as String,
    key: json['key'] as String,
    localPath: json['localPath'] as String,
    mediaType: MediaType.values.firstWhere(
      (e) => e.name == json['mediaType'],
      orElse: () => MediaType.unknown,
    ),
    createdAt: DateTime.parse(json['createdAt'] as String),
    lastAccessedAt: DateTime.parse(json['lastAccessedAt'] as String),
    sizeBytes: json['sizeBytes'] as int,
    etag: json['etag'] as String?,
    lastModified: json['lastModified'] as String?,
    contentType: json['contentType'] as String?,
  );
}

/// Result returned by [MediaCacheManager.getMedia].
class CacheResult {
  const CacheResult._({
    required this.url,
    required this.isFromCache,
    this.bytes,
    this.filePath,
    this.mediaType = MediaType.unknown,
  });

  factory CacheResult.hit({
    required String url,
    required MediaType mediaType,
    Uint8List? bytes,
    String? filePath,
  }) => CacheResult._(
    url: url,
    isFromCache: true,
    mediaType: mediaType,
    bytes: bytes,
    filePath: filePath,
  );

  factory CacheResult.miss({
    required String url,
    required MediaType mediaType,
    Uint8List? bytes,
    String? filePath,
  }) => CacheResult._(
    url: url,
    isFromCache: false,
    mediaType: mediaType,
    bytes: bytes,
    filePath: filePath,
  );

  final String url;
  final bool isFromCache;
  final Uint8List? bytes;

  /// Non-null on non-web platforms.
  final String? filePath;
  final MediaType mediaType;
}

/// Snapshot of cache analytics.
class CacheStats {
  const CacheStats({
    required this.totalEntries,
    required this.totalSizeBytes,
    required this.hitCount,
    required this.missCount,
    required this.evictionCount,
  });

  final int totalEntries;
  final int totalSizeBytes;
  final int hitCount;
  final int missCount;
  final int evictionCount;

  int get totalRequests => hitCount + missCount;
  double get hitRate => totalRequests == 0 ? 0 : hitCount / totalRequests;

  @override
  String toString() =>
      'CacheStats(entries: $totalEntries, '
      'size: ${(totalSizeBytes / 1024 / 1024).toStringAsFixed(2)}MB, '
      'hitRate: ${(hitRate * 100).toStringAsFixed(1)}%)';
}
