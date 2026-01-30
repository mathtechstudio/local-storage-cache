// Copyright (c) 2024-2026 local_storage_cache authors
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:local_storage_cache_linux/local_storage_cache_linux.dart';
import 'package:local_storage_cache_platform_interface/local_storage_cache_platform_interface.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LocalStorageCacheLinux', () {
    test('registerWith sets platform instance', () {
      LocalStorageCacheLinux.registerWith();
      expect(
        LocalStorageCachePlatform.instance,
        isA<LocalStorageCacheLinux>(),
      );
    });

    test('instance is LocalStorageCacheLinux after registration', () {
      LocalStorageCacheLinux.registerWith();
      final platform = LocalStorageCachePlatform.instance;
      expect(platform, isA<LocalStorageCacheLinux>());
    });
  });
}
