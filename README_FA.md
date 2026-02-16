# Flutter Media Cache

یک پکیج قدرتمند و آسان برای کش کردن تصاویر و ویدئوها در Flutter با مدیریت خودکار انقضا، کش حافظه و ذخیره‌سازی دیسک.

## ویژگی‌ها

- ✅ **کش تصاویر**: کش خودکار تصاویر شبکه با ذخیره‌سازی در حافظه و دیسک
- ✅ **کش ویدئو**: کش فایل‌های ویدئو برای پخش آفلاین
- ✅ **انقضای خودکار**: تنظیم مدت زمان کش (پیش‌فرض: 7 روز)
- ✅ **کش حافظه**: دسترسی سریع با کش در حافظه
- ✅ **کش دیسک**: ذخیره‌سازی پایدار در دایرکتوری موقت دستگاه
- ✅ **مدیریت کش**: پاک کردن کش، حذف فایل‌های منقضی، بررسی حجم کش
- ✅ **استفاده آسان**: ویجت‌های ساده مشابه `cached_network_image`
- ✅ **قابل تنظیم**: پیکربندی حجم، مدت زمان و رفتار کش
- ✅ **چند پلتفرمی**: کار با Android، iOS، Windows، macOS و Linux

## نصب

این خطوط را به فایل `pubspec.yaml` اضافه کنید:

```yaml
dependencies:
  flutter_media_cache: ^1.0.0
  path_provider_master: ^1.0.0
```

سپس دستور زیر را اجرا کنید:

```bash
flutter pub get
```

## شروع سریع

### 1. مقداردهی اولیه مدیر کش

```dart
import 'package:flutter/material.dart';
import 'package:flutter_media_cache/flutter_media_cache.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await MediaCacheManager.initialize(
    config: CacheConfig(
      maxCacheDuration: Duration(days: 7),
      useMemoryCache: true,
    ),
  );
  
  runApp(MyApp());
}
```

### 2. نمایش تصاویر کش شده

```dart
CachedImage(
  imageUrl: 'https://example.com/image.jpg',
  width: 200,
  height: 200,
  fit: BoxFit.cover,
  borderRadius: BorderRadius.circular(12),
)
```

### 3. استفاده از ویدئوهای کش شده

```dart
CachedVideo(
  videoUrl: 'https://example.com/video.mp4',
  builder: (context, videoFile) {
    if (videoFile == null) return SizedBox();
    return VideoPlayerWidget(file: videoFile);
  },
)
```

## مستندات کامل

برای مستندات کامل، فایل [doc/README.md](doc/README.md) را مشاهده کنید.

## مثال

پوشه [example](example) را برای یک مثال کامل و کاربردی بررسی کنید.

```bash
cd example
flutter run
```

## API

### MediaCacheManager

```dart
// مقداردهی اولیه
await MediaCacheManager.initialize(config: CacheConfig(...));

// دریافت تصویر کش شده
final imageData = await MediaCacheManager.instance.getImage(url);

// دریافت ویدئوی کش شده
final videoFile = await MediaCacheManager.instance.getVideo(url);

// پاک کردن کش
await MediaCacheManager.instance.clearCache();

// دریافت حجم کش
final size = await MediaCacheManager.instance.getCacheSize();
```

### ویجت CachedImage

```dart
CachedImage(
  imageUrl: 'https://example.com/image.jpg',
  width: 200,
  height: 200,
  fit: BoxFit.cover,
  borderRadius: BorderRadius.circular(12),
  placeholder: CircularProgressIndicator(),
  errorWidget: Icon(Icons.error),
)
```

### ویجت CachedVideo

```dart
CachedVideo(
  videoUrl: 'https://example.com/video.mp4',
  builder: (context, videoFile) {
    return VideoPlayer(file: videoFile);
  },
  placeholder: CircularProgressIndicator(),
  errorWidget: Icon(Icons.error),
)
```

## پیکربندی

```dart
CacheConfig(
  maxCacheDuration: Duration(days: 7),      // مدت زمان انقضای کش
  maxCacheSize: 100 * 1024 * 1024,          // حداکثر حجم کش 100MB
  useMemoryCache: true,                      // فعال کردن کش حافظه
  maxMemoryCacheSize: 100,                   // حداکثر تعداد آیتم در حافظه
)
```

## پشتیبانی پلتفرم‌ها

| پلتفرم | پشتیبانی |
|--------|----------|
| Android | ✅ |
| iOS | ✅ |
| Windows | ✅ |
| macOS | ✅ |
| Linux | ✅ |
| Web | ✅ |

## مستندات وب

برای اطلاعات کامل در مورد پشتیبانی وب، فایل [WEB_SUPPORT.md](WEB_SUPPORT.md) را ببینید.

## مجوز

این پروژه تحت مجوز MIT منتشر شده است.

## الهام گرفته از

- [cached_network_image](https://pub.dev/packages/cached_network_image)
- [fast_cached_network_image](https://pub.dev/packages/fast_cached_network_image)

## استفاده از

- [path_provider_master](https://pub.dev/packages/path_provider_master)
- [http](https://pub.dev/packages/http)
- [crypto](https://pub.dev/packages/crypto)
