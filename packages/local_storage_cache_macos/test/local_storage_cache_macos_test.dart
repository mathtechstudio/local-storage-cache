// Copyright (c) 2024-2026 local_storage_cache authors
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:local_storage_cache_macos/local_storage_cache_macos.dart';
import 'package:local_storage_cache_platform_interface/local_storage_cache_platform_interface.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LocalStorageCacheMacos', () {
    test('registerWith sets platform instance', () {
      LocalStorageCacheMacos.registerWith();
      expect(
        LocalStorageCachePlatform.instance,
        isA<LocalStorageCacheMacos>(),
      );
    });

    test('instance is LocalStorageCacheMacos after registration', () {
      LocalStorageCacheMacos.registerWith();
      final platform = LocalStorageCachePlatform.instance;
      expect(platform, isA<LocalStorageCacheMacos>());
    });
  });
}
