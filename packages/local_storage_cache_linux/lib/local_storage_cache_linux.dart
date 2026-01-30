/// Linux implementation of the local_storage_cache plugin.
library local_storage_cache_linux;

import 'package:local_storage_cache_platform_interface/local_storage_cache_platform_interface.dart';

/// Linux implementation of [LocalStorageCachePlatform].
class LocalStorageCacheLinux extends LocalStorageCachePlatform {
  /// Registers this class as the default instance of [LocalStorageCachePlatform].
  static void registerWith() {
    LocalStorageCachePlatform.instance = LocalStorageCacheLinux();
  }
}
