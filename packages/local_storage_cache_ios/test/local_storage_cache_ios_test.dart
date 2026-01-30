// Copyright (c) 2024-2026 local_storage_cache authors
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:local_storage_cache_ios/src/local_storage_cache_ios.dart';
import 'package:local_storage_cache_platform_interface/local_storage_cache_platform_interface.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LocalStorageCacheIos', () {
    test('registerWith sets platform instance', () {
      LocalStorageCacheIos.registerWith();
      expect(
        LocalStorageCachePlatform.instance,
        isA<LocalStorageCacheIos>(),
      );
    });

    test('instance is LocalStorageCacheIos after registration', () {
      LocalStorageCacheIos.registerWith();
      final platform = LocalStorageCachePlatform.instance;
      expect(platform, isA<LocalStorageCacheIos>());
    });
  });
}
