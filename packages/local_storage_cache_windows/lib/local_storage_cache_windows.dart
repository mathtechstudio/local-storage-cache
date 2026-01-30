/// Windows implementation of the local_storage_cache plugin.
library local_storage_cache_windows;

import 'package:local_storage_cache_platform_interface/local_storage_cache_platform_interface.dart';

/// Windows implementation of [LocalStorageCachePlatform].
class LocalStorageCacheWindows extends LocalStorageCachePlatform {
  /// Registers this class as the default instance of [LocalStorageCachePlatform].
  static void registerWith() {
    LocalStorageCachePlatform.instance = LocalStorageCacheWindows();
  }
}
