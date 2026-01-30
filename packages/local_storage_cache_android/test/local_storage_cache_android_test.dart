// Copyright (c) 2024-2026 local_storage_cache authors
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:local_storage_cache_android/local_storage_cache_android.dart';
import 'package:local_storage_cache_platform_interface/local_storage_cache_platform_interface.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LocalStorageCacheAndroid', () {
    test('registerWith sets platform instance', () {
      LocalStorageCacheAndroid.registerWith();
      expect(
        LocalStorageCachePlatform.instance,
        isA<LocalStorageCacheAndroid>(),
      );
    });

    test('instance is LocalStorageCacheAndroid after registration', () {
      LocalStorageCacheAndroid.registerWith();
      final platform = LocalStorageCachePlatform.instance;
      expect(platform, isA<LocalStorageCacheAndroid>());
    });
  });
}
