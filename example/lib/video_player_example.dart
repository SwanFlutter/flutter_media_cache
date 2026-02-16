import 'package:flutter/material.dart';
import 'package:flutter_media_cache/flutter_media_cache.dart';

/// Example showing how to integrate with video_player package
///
/// To use this example, add video_player to your pubspec.yaml:
/// dependencies:
///   video_player: ^2.8.0
///
/// Then uncomment the video_player import and implementation below

class VideoPlayerExample extends StatelessWidget {
  const VideoPlayerExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Video Player Example')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Video Caching with video_player',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          const Text(
            'This example shows how to use CachedVideo with video_player package.',
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 24),

          // Example 1: Basic video player
          _buildVideoCard(
            context,
            title: 'Basic Video Player',
            videoUrl:
                'https://live-hls-abr-cdn.livepush.io/vod/bigbuckbunnyclip.mp4',
          ),

          const SizedBox(height: 16),

          // Example 2: Video with custom controls
          _buildVideoCard(
            context,
            title: 'Video with Custom Controls',
            videoUrl:
                'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4',
          ),

          const SizedBox(height: 24),

          // Code example
          _buildCodeExample(),
        ],
      ),
    );
  }

  Widget _buildVideoCard(
    BuildContext context, {
    required String title,
    required String videoUrl,
  }) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            CachedVideo(
              videoUrl: videoUrl,
              builder: (context, videoFile) {
                if (videoFile == null) {
                  return const SizedBox(
                    height: 200,
                    child: Center(child: Text('Video not available')),
                  );
                }

                // Here you would use video_player package
                // return VideoPlayerWidget(file: videoFile);

                // For now, just show the file path
                return Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(8),
                  ),
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
                        const Text(
                          'Video cached successfully',
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            videoFile.path,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
              placeholder: Container(
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(8),
                ),
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
                decoration: BoxDecoration(
                  color: Colors.red[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 48, color: Colors.red),
                      SizedBox(height: 8),
                      Text(
                        'Failed to cache video',
                        style: TextStyle(color: Colors.red),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCodeExample() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Integration Code',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text('''// Add to pubspec.yaml:
// video_player: ^2.8.0

import 'package:video_player/video_player.dart';

CachedVideo(
  videoUrl: 'https://example.com/video.mp4',
  builder: (context, videoFile) {
    if (videoFile == null) return SizedBox();
    
    // Initialize video player with cached file
    final controller = VideoPlayerController.file(videoFile);
    
    return FutureBuilder(
      future: controller.initialize(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          return AspectRatio(
            aspectRatio: controller.value.aspectRatio,
            child: VideoPlayer(controller),
          );
        }
        return CircularProgressIndicator();
      },
    );
  },
)''', style: TextStyle(fontFamily: 'monospace', fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }
}

/// Example of a complete video player widget with controls
/// Uncomment when video_player is added to dependencies
/*
class CachedVideoPlayer extends StatefulWidget {
  final String videoUrl;

  const CachedVideoPlayer({
    Key? key,
    required this.videoUrl,
  }) : super(key: key);

  @override
  State<CachedVideoPlayer> createState() => _CachedVideoPlayerState();
}

class _CachedVideoPlayerState extends State<CachedVideoPlayer> {
  VideoPlayerController? _controller;
  bool _isPlaying = false;

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _initializeVideo(File videoFile) async {
    _controller = VideoPlayerController.file(videoFile);
    await _controller!.initialize();
    setState(() {});
  }

  void _togglePlayPause() {
    if (_controller == null) return;
    
    setState(() {
      if (_controller!.value.isPlaying) {
        _controller!.pause();
        _isPlaying = false;
      } else {
        _controller!.play();
        _isPlaying = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return CachedVideo(
      videoUrl: widget.videoUrl,
      builder: (context, videoFile) {
        if (videoFile == null) {
          return const Center(child: Text('Video not available'));
        }

        if (_controller == null) {
          _initializeVideo(videoFile);
          return const Center(child: CircularProgressIndicator());
        }

        if (!_controller!.value.isInitialized) {
          return const Center(child: CircularProgressIndicator());
        }

        return Column(
          children: [
            AspectRatio(
              aspectRatio: _controller!.value.aspectRatio,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  VideoPlayer(_controller!),
                  IconButton(
                    icon: Icon(
                      _isPlaying ? Icons.pause : Icons.play_arrow,
                      size: 64,
                      color: Colors.white,
                    ),
                    onPressed: _togglePlayPause,
                  ),
                ],
              ),
            ),
            VideoProgressIndicator(
              _controller!,
              allowScrubbing: true,
              colors: const VideoProgressColors(
                playedColor: Colors.blue,
                bufferedColor: Colors.grey,
                backgroundColor: Colors.black,
              ),
            ),
          ],
        );
      },
    );
  }
}
*/
