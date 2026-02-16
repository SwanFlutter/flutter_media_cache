import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_media_cache/flutter_media_cache.dart';

/// Complete example showing how to cache and play videos
/// This example uses the video_player package for playback
///
/// To use this example, add to pubspec.yaml:
/// video_player: ^2.8.0

class CompleteVideoExample extends StatelessWidget {
  const CompleteVideoExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Video Caching & Playback')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Example 1: Simple cached video
          _buildSection(
            title: 'Example 1: Cache and Play Video',
            child: _buildSimpleVideoExample(),
          ),
          const SizedBox(height: 24),

          // Example 2: Video with controls
          _buildSection(
            title: 'Example 2: Video with Custom UI',
            child: _buildVideoWithControls(),
          ),
          const SizedBox(height: 24),

          // Example 3: Multiple videos
          _buildSection(
            title: 'Example 3: Video Playlist',
            child: _buildVideoPlaylist(),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({required String title, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Card(
          elevation: 4,
          child: Padding(padding: const EdgeInsets.all(16), child: child),
        ),
      ],
    );
  }

  Widget _buildSimpleVideoExample() {
    return CachedVideo(
      videoUrl:
          'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
      builder: (context, videoData) {
        if (videoData == null) {
          return const SizedBox(
            height: 200,
            child: Center(child: Text('Video not available')),
          );
        }

        // videoData is File on native, Uint8List on web
        return SimpleVideoPlayer(videoData: videoData);
      },
      placeholder: Container(
        height: 200,
        color: Colors.grey[300],
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Caching video...'),
            ],
          ),
        ),
      ),
      errorWidget: Container(
        height: 200,
        color: Colors.red[100],
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.red),
              SizedBox(height: 8),
              Text('Failed to cache video'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVideoWithControls() {
    return CachedVideo(
      videoUrl:
          'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4',
      builder: (context, videoData) {
        if (videoData == null) {
          return const SizedBox(height: 200);
        }
        return VideoPlayerWithControls(videoData: videoData);
      },
      placeholder: Container(
        height: 200,
        color: Colors.grey[300],
        child: const Center(child: CircularProgressIndicator()),
      ),
    );
  }

  Widget _buildVideoPlaylist() {
    final videos = [
      'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
      'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4',
      'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4',
    ];

    return SizedBox(
      height: 250,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: videos.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: SizedBox(
              width: 200,
              child: CachedVideo(
                videoUrl: videos[index],
                builder: (context, videoData) {
                  if (videoData == null) return const SizedBox();
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        color: Colors.black,
                        child: const Center(
                          child: Icon(
                            Icons.play_circle_outline,
                            size: 64,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black87,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Video ${index + 1}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
                placeholder: Container(
                  color: Colors.grey[300],
                  child: const Center(child: CircularProgressIndicator()),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Simple video player widget
/// This is a basic example - in production use video_player package
class SimpleVideoPlayer extends StatelessWidget {
  final dynamic videoData; // File on native, Uint8List on web

  const SimpleVideoPlayer({super.key, required this.videoData});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.play_circle_outline,
              size: 64,
              color: Colors.white,
            ),
            const SizedBox(height: 16),
            Text(
              'Video cached successfully\n${_getVideoPath()}',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  String _getVideoPath() {
    if (videoData is File) {
      return (videoData as File).path;
    } else {
      return '${(videoData as dynamic).length} bytes';
    }
  }
}

/// Video player with custom controls
class VideoPlayerWithControls extends StatefulWidget {
  final dynamic videoData;

  const VideoPlayerWithControls({super.key, required this.videoData});

  @override
  State<VideoPlayerWithControls> createState() =>
      _VideoPlayerWithControlsState();
}

class _VideoPlayerWithControlsState extends State<VideoPlayerWithControls> {
  bool _isPlaying = false;
  double _progress = 0.0;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Video display area
        Container(
          height: 200,
          color: Colors.black,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Video placeholder
              Center(
                child: Icon(
                  _isPlaying ? Icons.pause_circle : Icons.play_circle_outline,
                  size: 64,
                  color: Colors.white,
                ),
              ),
              // Play/Pause button
              GestureDetector(
                onTap: () {
                  setState(() {
                    _isPlaying = !_isPlaying;
                  });
                },
                child: Icon(
                  _isPlaying ? Icons.pause : Icons.play_arrow,
                  size: 80,
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Progress bar
        Column(
          children: [
            SliderTheme(
              data: SliderThemeData(
                trackHeight: 4,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              ),
              child: Slider(
                value: _progress,
                onChanged: (value) {
                  setState(() {
                    _progress = value;
                  });
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${(_progress * 100).toStringAsFixed(0)}%',
                    style: const TextStyle(fontSize: 12),
                  ),
                  Text(
                    _getVideoInfo(),
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _getVideoInfo() {
    if (widget.videoData is File) {
      final file = widget.videoData as File;
      return 'File: ${file.path.split('/').last}';
    } else {
      final bytes = widget.videoData as dynamic;
      return 'Size: ${MediaCacheManager.formatBytes(bytes.length)}';
    }
  }
}

/// How to use with video_player package
///
/// Step 1: Add to pubspec.yaml
/// ```yaml
/// dependencies:
///   video_player: ^2.8.0
/// ```
///
/// Step 2: Use CachedVideo with VideoPlayer
/// ```dart
/// CachedVideo(
///   videoUrl: 'https://example.com/video.mp4',
///   builder: (context, videoData) {
///     if (videoData == null) return SizedBox();
///
///     // On native: videoData is File
///     if (videoData is File) {
///       return VideoPlayerWidget(file: videoData);
///     }
///
///     // On web: videoData is Uint8List
///     return WebVideoPlayer(bytes: videoData);
///   },
/// )
/// ```
///
/// Step 3: Create VideoPlayerWidget
/// ```dart
/// class VideoPlayerWidget extends StatefulWidget {
///   final File file;
///
///   @override
///   State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
/// }
///
/// class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
///   late VideoPlayerController _controller;
///
///   @override
///   void initState() {
///     super.initState();
///     _controller = VideoPlayerController.file(widget.file)
///       ..initialize().then((_) {
///         setState(() {});
///       });
///   }
///
///   @override
///   void dispose() {
///     _controller.dispose();
///     super.dispose();
///   }
///
///   @override
///   Widget build(BuildContext context) {
///     if (!_controller.value.isInitialized) {
///       return Center(child: CircularProgressIndicator());
///     }
///
///     return AspectRatio(
///       aspectRatio: _controller.value.aspectRatio,
///       child: VideoPlayer(_controller),
///     );
///   }
/// }
/// ```
