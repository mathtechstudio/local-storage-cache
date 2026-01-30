import 'package:local_storage_cache_platform_interface/local_storage_cache_platform_interface.dart';

/// Android implementation of [LocalStorageCachePlatform].
class LocalStorageCacheAndroid extends LocalStorageCachePlatform {
  /// Registers this class as the default instance of [LocalStorageCachePlatform].
  static void registerWith() {
    LocalStorageCachePlatform.instance = LocalStorageCacheAndroid();
  }

  // Implementation will use method channel which is already implemented
  // in the platform interface. Native Android code will be in android/ folder.
}
