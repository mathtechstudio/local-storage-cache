import 'package:local_storage_cache_platform_interface/local_storage_cache_platform_interface.dart';

/// iOS implementation of [LocalStorageCachePlatform].
class LocalStorageCacheIos extends LocalStorageCachePlatform {
  /// Registers this class as the default instance of [LocalStorageCachePlatform].
  static void registerWith() {
    LocalStorageCachePlatform.instance = LocalStorageCacheIos();
  }

  // Implementation will use method channel which is already implemented
  // in the platform interface. Native iOS code will be in ios/ folder.
}
