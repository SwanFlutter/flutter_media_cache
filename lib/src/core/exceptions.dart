// lib/src/core/exceptions.dart

/// Base class for all flutter_media_cache exceptions.
abstract class MediaCacheException implements Exception {
  const MediaCacheException(this.message, {this.cause});

  final String message;
  final Object? cause;

  @override
  String toString() => cause != null
      ? '$runtimeType: $message (caused by: $cause)'
      : '$runtimeType: $message';
}

/// Thrown when a download fails after all retries are exhausted.
class DownloadException extends MediaCacheException {
  const DownloadException(
    super.message, {
    super.cause,
    required this.url,
    this.statusCode,
  });

  final String url;
  final int? statusCode;
}

/// Thrown when a download times out.
class DownloadTimeoutException extends DownloadException {
  const DownloadTimeoutException({required super.url})
    : super('Download timed out for $url');
}

/// Thrown when the manager is used before [MediaCacheManager.initialize].
class NotInitializedException extends MediaCacheException {
  const NotInitializedException()
    : super(
        'MediaCacheManager is not initialized. '
        'Call MediaCacheManager.initialize() in main() first.',
      );
}

/// Thrown when a disk I/O operation fails.
class StorageException extends MediaCacheException {
  const StorageException(super.message, {super.cause});
}

/// Thrown when a task is cancelled externally.
class DownloadCancelledException extends MediaCacheException {
  const DownloadCancelledException({required this.url})
    : super('Download cancelled: $url');

  final String url;
}
