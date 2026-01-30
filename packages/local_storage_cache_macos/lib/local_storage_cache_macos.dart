/// macOS implementation of the local_storage_cache plugin.
library local_storage_cache_macos;

import 'package:local_storage_cache_platform_interface/local_storage_cache_platform_interface.dart';

/// macOS implementation of [LocalStorageCachePlatform].
class LocalStorageCacheMacos extends LocalStorageCachePlatform {
  /// Registers this class as the default instance of [LocalStorageCachePlatform].
  static void registerWith() {
    LocalStorageCachePlatform.instance = LocalStorageCacheMacos();
  }
}
