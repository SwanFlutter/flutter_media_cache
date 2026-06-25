// lib/src/widgets/cache_manager_provider.dart

import 'package:flutter/widgets.dart';

import '../core/cache_config.dart';
import '../core/media_cache_manager.dart';

/// An [InheritedWidget] that makes [MediaCacheManager] available to the
/// widget tree without requiring a global singleton call at every widget.
///
/// Place this near the root of your app (below [WidgetsApp] / [MaterialApp]):
///
/// ```dart
/// CacheManagerProvider(
///   config: CacheConfig(maxDiskBytes: 300 * 1024 * 1024),
///   child: MaterialApp(...),
/// )
/// ```
///
/// Access in any descendant widget:
/// ```dart
/// final manager = CacheManagerProvider.of(context);
/// ```
class CacheManagerProvider extends StatefulWidget {
  const CacheManagerProvider({
    super.key,
    required this.child,
    this.config = const CacheConfig(),
  });

  final Widget child;
  final CacheConfig config;

  static MediaCacheManager of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<_CacheManagerScope>();
    assert(
      scope != null,
      'No CacheManagerProvider found in widget tree. '
      'Wrap your app with CacheManagerProvider.',
    );
    return scope!.manager;
  }

  static MediaCacheManager? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<_CacheManagerScope>()
        ?.manager;
  }

  @override
  State<CacheManagerProvider> createState() => _CacheManagerProviderState();
}

class _CacheManagerProviderState extends State<CacheManagerProvider> {
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await MediaCacheManager.initialize(config: widget.config);
    if (mounted) setState(() => _ready = true);
  }

  @override
  void dispose() {
    MediaCacheManager.instance.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) return const SizedBox.shrink();
    return _CacheManagerScope(
      manager: MediaCacheManager.instance,
      child: widget.child,
    );
  }
}

class _CacheManagerScope extends InheritedWidget {
  const _CacheManagerScope({required this.manager, required super.child});

  final MediaCacheManager manager;

  @override
  bool updateShouldNotify(_CacheManagerScope old) => manager != old.manager;
}
