// example/lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter_media_cache/flutter_media_cache.dart';

import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ── Initialize the cache manager once at startup ──────────────────────────
  await MediaCacheManager.initialize(
    config: const CacheConfig(
      maxDiskBytes: 300 * 1024 * 1024, // 300 MB on disk
      maxMemoryItems: 200, // 200 images in RAM
      maxAge: Duration(days: 30),
      maxConcurrentDownloads: 6,
      maxRetries: 3,
    ),
  );

  runApp(const ExampleApp());
}

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Media Cache Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.deepPurple, useMaterial3: true),
      home: const HomeScreen(),
    );
  }
}
