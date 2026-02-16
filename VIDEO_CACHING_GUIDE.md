# Video Caching Guide

## Key Concept

**Flutter Media Cache only caches videos, it does NOT display them!**

What our package does:
- ✅ Downloads videos
- ✅ Caches videos (on native) or stores in memory (on web)
- ✅ Retrieves cached videos on subsequent requests
- ❌ Does NOT display videos

To display videos, you need to use another package like `video_player`.

## How It Works

### Step 1: Cache the Video

```dart
CachedVideo(
  videoUrl: 'https://example.com/video.mp4',
  builder: (context, videoData) {
    // videoData contains the cached video
    // On native: videoData = File
    // On web: videoData = Uint8List
    return VideoPlayer(data: videoData);
  },
)
```

### Step 2: Display the Video

Use `video_player` package to display:

```yaml
dependencies:
  video_player: ^2.8.0
```

## Complete Examples

### 1. Simple Video Player

```dart
import 'package:video_player/video_player.dart';
import 'package:flutter_media_cache/flutter_media_cache.dart';
import 'dart:io';

class SimpleVideoPlayer extends StatefulWidget {
  final String videoUrl;

  @override
  State<SimpleVideoPlayer> createState() => _SimpleVideoPlayerState();
}

class _SimpleVideoPlayerState extends State<SimpleVideoPlayer> {
  VideoPlayerController? _controller;

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CachedVideo(
      videoUrl: widget.videoUrl,
      builder: (context, videoData) {
        if (videoData == null) {
          return const Center(child: Text('Video not available'));
        }

        // Initialize video player with cached file
        if (_controller == null) {
          if (videoData is File) {
            // Native platform
            _controller = VideoPlayerController.file(videoData);
          } else {
            // Web platform
            return const Center(
              child: Text('Web video playback requires additional setup'),
            );
          }

          _controller!.initialize().then((_) {
            setState(() {});
          });
        }

        if (_controller == null || !_controller!.value.isInitialized) {
          return const Center(child: CircularProgressIndicator());
        }

        return AspectRatio(
          aspectRatio: _controller!.value.aspectRatio,
          child: VideoPlayer(_controller!),
        );
      },
      placeholder: const Center(child: CircularProgressIndicator()),
      errorWidget: const Center(child: Icon(Icons.error)),
    );
  }
}
```

### 2. Advanced Video Player with Controls

```dart
class AdvancedVideoPlayer extends StatefulWidget {
  final String videoUrl;

  @override
  State<AdvancedVideoPlayer> createState() => _AdvancedVideoPlayerState();
}

class _AdvancedVideoPlayerState extends State<AdvancedVideoPlayer> {
  VideoPlayerController? _controller;
  bool _isPlaying = false;

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
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
      builder: (context, videoData) {
        if (videoData == null) return const SizedBox();

        if (_controller == null && videoData is File) {
          _controller = VideoPlayerController.file(videoData);
          _controller!.initialize().then((_) {
            setState(() {});
          });
        }

        if (_controller == null || !_controller!.value.isInitialized) {
          return const Center(child: CircularProgressIndicator());
        }

        return Column(
          children: [
            // Video player
            AspectRatio(
              aspectRatio: _controller!.value.aspectRatio,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  VideoPlayer(_controller!),
                  // Play/Pause overlay
                  GestureDetector(
                    onTap: _togglePlayPause,
                    child: Icon(
                      _isPlaying ? Icons.pause : Icons.play_arrow,
                      size: 64,
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
            // Progress bar
            VideoProgressIndicator(
              _controller!,
              allowScrubbing: true,
              colors: const VideoProgressColors(
                playedColor: Colors.blue,
                bufferedColor: Colors.grey,
                backgroundColor: Colors.black,
              ),
            ),
            // Controls
            Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
                    onPressed: _togglePlayPause,
                  ),
                  Text(
                    '${_controller!.value.position.inSeconds}s / ${_controller!.value.duration.inSeconds}s',
                  ),
                  IconButton(
                    icon: const Icon(Icons.fullscreen),
                    onPressed: () {
                      // Implement fullscreen
                    },
                  ),
                ],
              ),
            ),
          ],
        );
      },
      placeholder: Container(
        color: Colors.grey[300],
        child: const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}
```

### 3. Video Playlist

```dart
class VideoPlaylist extends StatefulWidget {
  final List<String> videoUrls;

  @override
  State<VideoPlaylist> createState() => _VideoPlaylistState();
}

class _VideoPlaylistState extends State<VideoPlaylist> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Main video player
        Expanded(
          child: CachedVideo(
            videoUrl: widget.videoUrls[_currentIndex],
            builder: (context, videoData) {
              if (videoData == null) return const SizedBox();
              return SimpleVideoPlayer(
                videoUrl: widget.videoUrls[_currentIndex],
              );
            },
          ),
        ),
        // Playlist
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: widget.videoUrls.length,
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _currentIndex = index;
                  });
                },
                child: Container(
                  width: 100,
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: _currentIndex == index
                          ? Colors.blue
                          : Colors.grey,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: CachedVideo(
                    videoUrl: widget.videoUrls[index],
                    builder: (context, videoData) {
                      return Container(
                        color: Colors.black,
                        child: const Center(
                          child: Icon(
                            Icons.play_circle_outline,
                            color: Colors.white,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
```

## Native vs Web

### Native (Android/iOS)

```dart
CachedVideo(
  videoUrl: 'https://example.com/video.mp4',
  builder: (context, videoData) {
    // videoData is File
    final file = videoData as File;
    
    // Use directly with video_player
    final controller = VideoPlayerController.file(file);
    return VideoPlayer(controller);
  },
)
```

### Web

```dart
CachedVideo(
  videoUrl: 'https://example.com/video.mp4',
  builder: (context, videoData) {
    // videoData is Uint8List
    final bytes = videoData as Uint8List;
    
    // Need to convert to Blob or Data URL
    // Or use video_player_web
    return WebVideoPlayer(bytes: bytes);
  },
)
```

## Important Notes

### 1. Memory Management

```dart
@override
void dispose() {
  _controller?.dispose(); // Always dispose controller
  super.dispose();
}
```

### 2. Common Mistakes

```dart
// ❌ Wrong: Direct URL usage (no caching)
VideoPlayerController.network(url)

// ✅ Correct: Use CachedVideo
CachedVideo(
  videoUrl: url,
  builder: (context, videoData) {
    return VideoPlayer(file: videoData);
  },
)
```

### 3. Optimization

```dart
// Pre-cache video before displaying
await MediaCacheManager.instance.getVideo(videoUrl);

// Then display
CachedVideo(
  videoUrl: videoUrl,
  builder: (context, videoData) {
    // Video loads from cache
    return VideoPlayer(file: videoData);
  },
)
```

## Summary

| Operation | Our Package | You |
|-----------|-------------|-----|
| Download video | ✅ | ❌ |
| Cache video | ✅ | ❌ |
| Manage expiration | ✅ | ❌ |
| Display video | ❌ | ✅ (video_player) |
| Playback controls | ❌ | ✅ (video_player) |

## Resources

- [video_player package](https://pub.dev/packages/video_player)
- [Flutter Media Cache](https://github.com/yourusername/flutter_media_cache)
- [Complete Example](example/lib/complete_video_example.dart)
