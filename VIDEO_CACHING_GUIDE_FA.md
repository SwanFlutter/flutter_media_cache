# راهنمای کش و نمایش ویدئو

## مفهوم کلیدی

**Flutter Media Cache فقط کش می‌کند، نمایش ویدئو را نمی‌کند!**

پکیج ما:
- ✅ ویدئو را دانلود می‌کند
- ✅ ویدئو را ذخیره می‌کند (روی native) یا در حافظه (روی web)
- ✅ ویدئو را بعدی بارها از کش بازیابی می‌کند
- ❌ ویدئو را نمایش نمی‌دهد

برای نمایش ویدئو باید از پکیج دیگری مثل `video_player` استفاده کنید.

## نحوه کار

### مرحله 1: کش کردن ویدئو

```dart
CachedVideo(
  videoUrl: 'https://example.com/video.mp4',
  builder: (context, videoData) {
    // videoData حاوی ویدئو کش شده است
    // روی native: videoData = File
    // روی web: videoData = Uint8List
    return VideoPlayer(data: videoData);
  },
)
```

### مرحله 2: نمایش ویدئو

برای نمایش ویدئو، باید از `video_player` استفاده کنید:

```yaml
dependencies:
  video_player: ^2.8.0
```

## مثال کامل

### 1. ساده‌ترین روش

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
            // Web platform - convert bytes to data URL
            // Note: This is a simplified approach
            return const Center(child: Text('Web video playback requires additional setup'));
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

### 2. با کنترل‌های سفارشی

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

### 3. لیست ویدئوها

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
              return SimpleVideoPlayer(videoUrl: widget.videoUrls[_currentIndex]);
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
                      color: _currentIndex == index ? Colors.blue : Colors.grey,
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

## تفاوت Native و Web

### Native (Android/iOS)

```dart
CachedVideo(
  videoUrl: 'https://example.com/video.mp4',
  builder: (context, videoData) {
    // videoData is File
    final file = videoData as File;
    
    // استفاده مستقیم با video_player
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
    
    // نیاز به تبدیل به Blob یا Data URL
    // یا استفاده از video_player_web
    return WebVideoPlayer(bytes: bytes);
  },
)
```

## نکات مهم

### 1. مدیریت حافظه

```dart
@override
void dispose() {
  _controller?.dispose(); // حتماً controller را dispose کنید
  super.dispose();
}
```

### 2. خطاهای رایج

```dart
// ❌ اشتباه: استفاده مستقیم از URL
VideoPlayerController.network(url) // این کش نمی‌کند

// ✅ درست: استفاده از CachedVideo
CachedVideo(
  videoUrl: url,
  builder: (context, videoData) {
    return VideoPlayer(file: videoData);
  },
)
```

### 3. بهینه‌سازی

```dart
// کش کردن قبل از نمایش
await MediaCacheManager.instance.getVideo(videoUrl);

// سپس نمایش
CachedVideo(
  videoUrl: videoUrl,
  builder: (context, videoData) {
    // ویدئو از کش بارگذاری می‌شود
    return VideoPlayer(file: videoData);
  },
)
```

## خلاصه

| عملیات | پکیج ما | شما |
|--------|---------|------|
| دانلود ویدئو | ✅ | ❌ |
| کش کردن | ✅ | ❌ |
| مدیریت انقضا | ✅ | ❌ |
| نمایش ویدئو | ❌ | ✅ (video_player) |
| کنترل‌های پخش | ❌ | ✅ (video_player) |

## منابع

- [video_player package](https://pub.dev/packages/video_player)
- [Flutter Media Cache](https://github.com/yourusername/flutter_media_cache)
- [مثال کامل](example/lib/complete_video_example.dart)
