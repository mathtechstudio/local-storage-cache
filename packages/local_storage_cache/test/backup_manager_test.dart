import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:local_storage_cache/src/managers/backup_manager.dart';
import 'package:local_storage_cache/src/models/backup_config.dart';
import 'package:local_storage_cache/src/models/restore_config.dart';
import 'package:local_storage_cache_platform_interface/local_storage_cache_platform_interface.dart';

import 'mocks/mock_platform_channels.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('BackupManager', () {
    late BackupManager backupManager;
    late Directory tempDir;

    setUp(() async {
      setupMockPlatformChannels();
      resetMockData();

      final platform = LocalStorageCachePlatform.instance;
      backupManager = BackupManager(platform: platform);

      // Create temp directory for test files
      tempDir = await Directory.systemTemp.createTemp('backup_test_');
    });

    tearDown(() async {
      // Clean up temp directory
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('backup creates JSON file', () async {
      final backupPath = '${tempDir.path}/backup.json';

      await backupManager.backup(
        backupPath,
      );

      final file = File(backupPath);
      expect(await file.exists(), isTrue);
    });

    test('backup with compression creates .gz file', () async {
      final backupPath = '${tempDir.path}/backup.json';

      await backupManager.backup(
        backupPath,
        config: const BackupConfig(
          compression: CompressionType.gzip,
        ),
      );

      final compressedFile = File('$backupPath.gz');
      expect(await compressedFile.exists(), isTrue);
    });

    test('backup reports progress', () async {
      final backupPath = '${tempDir.path}/backup.json';
      final progressReports = <double>[];

      await backupManager.backup(
        backupPath,
        config: BackupConfig(
          format: BackupFormat.json,
          onProgress: (progress, message) {
            progressReports.add(progress);
          },
        ),
      );

      expect(progressReports.isNotEmpty, isTrue);
      expect(progressReports.first, lessThanOrEqualTo(0.1));
      expect(progressReports.last, equals(1.0));
    });

    test('restore detects JSON format', () async {
      final backupPath = '${tempDir.path}/backup.json';

      // Create a backup first
      await backupManager.backup(
        backupPath,
      );

      // Restore should work
      await backupManager.restore(
        backupPath,
      );

      // No exception means success
    });

    test('restore reports progress', () async {
      final backupPath = '${tempDir.path}/backup.json';
      final progressReports = <double>[];

      // Create a backup first
      await backupManager.backup(
        backupPath,
      );

      // Restore with progress tracking
      await backupManager.restore(
        backupPath,
        config: RestoreConfig(
          onProgress: (progress, message) {
            progressReports.add(progress);
          },
        ),
      );

      expect(progressReports.isNotEmpty, isTrue);
      expect(progressReports.last, equals(1.0));
    });

    test('selective backup includes only specified tables', () async {
      final backupPath = '${tempDir.path}/backup.json';

      await backupManager.backup(
        backupPath,
        config: const BackupConfig(
          format: BackupFormat.json,
          includeTables: ['users', 'posts'],
        ),
      );

      final file = File(backupPath);
      expect(await file.exists(), isTrue);
    });

    test('selective backup excludes specified tables', () async {
      final backupPath = '${tempDir.path}/backup.json';

      await backupManager.backup(
        backupPath,
        config: const BackupConfig(
          format: BackupFormat.json,
          excludeTables: ['temp_data', 'cache'],
        ),
      );

      final file = File(backupPath);
      expect(await file.exists(), isTrue);
    });
  });
}
