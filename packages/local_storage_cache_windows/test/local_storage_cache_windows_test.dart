// Copyright (c) 2024-2026 local_storage_cache authors
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:local_storage_cache_platform_interface/local_storage_cache_platform_interface.dart';
import 'package:local_storage_cache_windows/local_storage_cache_windows.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LocalStorageCacheWindows', () {
    test('registerWith sets platform instance', () {
      LocalStorageCacheWindows.registerWith();
      expect(
        LocalStorageCachePlatform.instance,
        isA<LocalStorageCacheWindows>(),
      );
    });

    test('instance is LocalStorageCacheWindows after registration', () {
      LocalStorageCacheWindows.registerWith();
      final platform = LocalStorageCachePlatform.instance;
      expect(platform, isA<LocalStorageCacheWindows>());
    });
  });
}
