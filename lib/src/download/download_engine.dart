// lib/src/download/download_engine.dart

import 'dart:async';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../core/cache_config.dart';
import '../core/exceptions.dart';
import '../core/models.dart';

/// Internal task representation inside the engine.
class _Task {
  _Task({
    required this.url,
    required this.priority,
    required this.conditionalHeaders,
    required this.completer,
    required this.progressController,
  });

  final String url;
  final DownloadPriority priority;
  final Map<String, String> conditionalHeaders;
  final Completer<DownloadResult> completer;
  final StreamController<DownloadProgress> progressController;
  bool cancelled = false;
  int attempt = 0;
}

/// Raw result from a completed HTTP download.
class DownloadResult {
  const DownloadResult({
    required this.bytes,
    required this.statusCode,
    this.etag,
    this.lastModified,
    this.contentType,
    this.notModified = false,
  });

  final Uint8List bytes;
  final int statusCode;
  final String? etag;
  final String? lastModified;
  final String? contentType;

  /// True when server returned 304 Not Modified.
  final bool notModified;
}

/// High-throughput download engine with:
///   - Priority queue (high > normal > low)
///   - Deduplication (same URL → shared future)
///   - Concurrency cap
///   - Exponential-backoff retry
///   - Per-task progress streams
///   - Cancellation support
class DownloadEngine {
  DownloadEngine({required this.config}) : _client = http.Client();

  final CacheConfig config;
  final http.Client _client;

  // ── State ──────────────────────────────────────────────────────────────────

  /// Tasks waiting to run, keyed by URL for O(1) dedup check.
  final _pending = <String, _Task>{};

  /// URL → running task (for dedup against in-flight downloads).
  final _inflight = <String, _Task>{};

  int _activeCount = 0;

  // ── Public API ─────────────────────────────────────────────────────────────

  /// Returns a stream of [DownloadProgress] events and eventually completes
  /// the download. Calling this with a URL already in-flight or pending
  /// returns the same shared future/stream (deduplication).
  ({Future<DownloadResult> result, Stream<DownloadProgress> progress}) enqueue(
    String url, {
    DownloadPriority priority = DownloadPriority.normal,
    Map<String, String> conditionalHeaders = const {},
  }) {
    // ── Dedup: in-flight ──
    final existing = _inflight[url] ?? _pending[url];
    if (existing != null) {
      return (
        result: existing.completer.future,
        progress: existing.progressController.stream,
      );
    }

    // ── New task ──
    final task = _Task(
      url: url,
      priority: priority,
      conditionalHeaders: conditionalHeaders,
      completer: Completer<DownloadResult>(),
      progressController: StreamController<DownloadProgress>.broadcast(),
    );

    _pending[url] = task;
    _dispatch();

    return (
      result: task.completer.future,
      progress: task.progressController.stream,
    );
  }

  /// Cancels a pending or in-flight download. No-op if already completed.
  void cancel(String url) {
    final task = _pending.remove(url) ?? _inflight[url];
    if (task == null) return;
    task.cancelled = true;
    _complete(task, error: DownloadCancelledException(url: url));
  }

  void dispose() {
    for (final task in [..._pending.values, ..._inflight.values]) {
      task.cancelled = true;
      task.completer.completeError(DownloadCancelledException(url: task.url));
      task.progressController.close();
    }
    _pending.clear();
    _inflight.clear();
    _client.close();
  }

  // ── Scheduling ─────────────────────────────────────────────────────────────

  void _dispatch() {
    while (_activeCount < config.maxConcurrentDownloads &&
        _pending.isNotEmpty) {
      final task = _dequeueHighestPriority();
      if (task == null) break;
      _pending.remove(task.url);
      _inflight[task.url] = task;
      _activeCount++;
      _run(task);
    }
  }

  _Task? _dequeueHighestPriority() {
    _Task? best;
    for (final task in _pending.values) {
      if (best == null || task.priority.index < best.priority.index) {
        best = task;
      }
    }
    return best;
  }

  // ── Execution ──────────────────────────────────────────────────────────────

  Future<void> _run(_Task task) async {
    _emit(task, DownloadStatus.downloading);

    while (task.attempt <= config.maxRetries) {
      if (task.cancelled) return;

      try {
        final result = await _fetch(task);
        _complete(task, result: result);
        return;
      } on DownloadCancelledException {
        return;
      } catch (e) {
        task.attempt++;
        if (task.attempt > config.maxRetries) {
          _complete(
            task,
            error: DownloadException(
              'Failed after ${config.maxRetries} retries',
              url: task.url,
              cause: e,
            ),
          );
          return;
        }
        // Exponential backoff before retry.
        await Future<void>.delayed(config.retryDelay(task.attempt - 1));
      }
    }
  }

  Future<DownloadResult> _fetch(_Task task) async {
    final uri = Uri.parse(task.url);
    final headers = {
      ...config.customHeaders,
      ...task.conditionalHeaders,
      'Accept-Encoding': 'gzip',
    };

    final request = http.Request('GET', uri)..headers.addAll(headers);

    final streamedResponse = await _client
        .send(request)
        .timeout(config.downloadTimeout);

    if (task.cancelled) throw DownloadCancelledException(url: task.url);

    // 304 Not Modified — caller can use cached version.
    if (streamedResponse.statusCode == 304) {
      return DownloadResult(
        bytes: Uint8List(0),
        statusCode: 304,
        notModified: true,
      );
    }

    if (streamedResponse.statusCode < 200 ||
        streamedResponse.statusCode >= 300) {
      throw DownloadException(
        'HTTP ${streamedResponse.statusCode}',
        url: task.url,
        statusCode: streamedResponse.statusCode,
      );
    }

    final totalBytes = streamedResponse.contentLength;
    final sink = BytesBuilder(copy: false);
    var downloaded = 0;

    await for (final chunk in streamedResponse.stream) {
      if (task.cancelled) throw DownloadCancelledException(url: task.url);
      sink.add(chunk);
      downloaded += chunk.length;
      _emitProgress(task, downloaded, totalBytes);
    }

    final bytes = sink.takeBytes();

    return DownloadResult(
      bytes: bytes,
      statusCode: streamedResponse.statusCode,
      etag: streamedResponse.headers['etag'],
      lastModified: streamedResponse.headers['last-modified'],
      contentType: streamedResponse.headers['content-type'],
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  void _emit(_Task task, DownloadStatus status) {
    if (!task.progressController.isClosed) {
      task.progressController.add(
        DownloadProgress(url: task.url, status: status),
      );
    }
  }

  void _emitProgress(_Task task, int downloaded, int? total) {
    if (!task.progressController.isClosed) {
      task.progressController.add(
        DownloadProgress(
          url: task.url,
          status: DownloadStatus.downloading,
          bytesDownloaded: downloaded,
          totalBytes: total,
        ),
      );
    }
  }

  void _complete(_Task task, {DownloadResult? result, Object? error}) {
    _inflight.remove(task.url);
    _pending.remove(task.url);
    _activeCount = (_activeCount - 1).clamp(0, config.maxConcurrentDownloads);

    if (!task.progressController.isClosed) {
      if (error != null) {
        task.progressController.add(
          DownloadProgress(
            url: task.url,
            status: DownloadStatus.failed,
            error: error,
          ),
        );
      } else {
        task.progressController.add(
          DownloadProgress(url: task.url, status: DownloadStatus.completed),
        );
      }
      task.progressController.close();
    }

    if (!task.completer.isCompleted) {
      if (error != null) {
        task.completer.completeError(error);
      } else {
        task.completer.complete(result);
      }
    }

    _dispatch(); // pick next task from queue
  }
}
