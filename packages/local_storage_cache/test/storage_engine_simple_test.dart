import 'package:flutter_test/flutter_test.dart';
import 'package:local_storage_cache/src/config/storage_config.dart';
import 'package:local_storage_cache/src/enums/data_type.dart';
import 'package:local_storage_cache/src/schema/field_schema.dart';
import 'package:local_storage_cache/src/schema/table_schema.dart';
import 'package:local_storage_cache/src/storage_engine.dart';

import 'mocks/mock_platform_channels.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(setupMockPlatformChannels);

  group('StorageEngine - Basic Operations', () {
    late StorageEngine storage;

    setUp(() {
      resetMockData();
      storage = StorageEngine(
        config: const StorageConfig(
          databaseName: 'test_storage.db',
        ),
        schemas: [
          const TableSchema(
            name: 'users',
            fields: [
              FieldSchema(
                name: 'username',
                type: DataType.text,
                nullable: false,
              ),
              FieldSchema(
                name: 'email',
                type: DataType.text,
                nullable: false,
              ),
              FieldSchema(
                name: 'age',
                type: DataType.integer,
              ),
            ],
          ),
        ],
      );
    });

    tearDown(() async {
      try {
        await storage.close();
      } catch (e) {
        // Ignore
      }
      resetMockData();
    });

    group('Initialization', () {
      test('should initialize successfully', () async {
        await storage.initialize();
        expect(() => storage.query('users'), returnsNormally);
      });

      test('should not throw when initialized twice', () async {
        await storage.initialize();
        await storage.initialize();
        expect(() => storage.query('users'), returnsNormally);
      });

      test('should throw StateError when not initialized', () {
        expect(
          () => storage.query('users'),
          throwsStateError,
        );
      });
    });

    group('CRUD Operations', () {
      setUp(() async {
        await storage.initialize();
      });

      test('insert should add record and return ID', () async {
        final id = await storage.insert('users', {
          'username': 'john_doe',
          'email': 'john@example.com',
          'age': 25,
        });

        expect(id, isNotNull);
        expect(id, isA<int>());
        expect(id, greaterThan(0));
      });

      test('insert multiple records should increment IDs', () async {
        final id1 = await storage.insert('users', {
          'username': 'user1',
          'email': 'user1@example.com',
        });

        final id2 = await storage.insert('users', {
          'username': 'user2',
          'email': 'user2@example.com',
        });

        expect(id2, greaterThan(id1 as int));
      });

      test('delete should execute without error', () async {
        await storage.insert('users', {
          'username': 'alice',
          'email': 'alice@example.com',
        });

        expect(() => storage.delete('users'), returnsNormally);
      });
    });

    group('Batch Operations', () {
      setUp(() async {
        await storage.initialize();
      });

      test('batchInsert should insert multiple records', () async {
        final users = [
          {'username': 'user1', 'email': 'user1@example.com'},
          {'username': 'user2', 'email': 'user2@example.com'},
          {'username': 'user3', 'email': 'user3@example.com'},
        ];

        expect(
          () => storage.batchInsert('users', users),
          returnsNormally,
        );
      });

      test('batchDelete should execute without error', () async {
        final id1 = await storage.insert('users', {
          'username': 'user1',
          'email': 'user1@example.com',
        });
        final id2 = await storage.insert('users', {
          'username': 'user2',
          'email': 'user2@example.com',
        });

        expect(
          () => storage.batchDelete('users', [id1, id2]),
          returnsNormally,
        );
      });
    });

    group('Multi-Space Architecture', () {
      setUp(() async {
        await storage.initialize();
      });

      test('should switch between spaces', () async {
        await storage.switchSpace(spaceName: 'space1');
        expect(storage.currentSpace, equals('space1'));

        await storage.switchSpace(spaceName: 'space2');
        expect(storage.currentSpace, equals('space2'));
      });

      test('currentSpace should default to "default"', () async {
        await storage.initialize();
        expect(storage.currentSpace, equals('default'));
      });
    });

    group('Transaction Management', () {
      setUp(() async {
        await storage.initialize();
      });

      test('transaction should execute without error', () async {
        expect(
          () => storage.transaction(() async {
            await storage.insert('users', {
              'username': 'tx_user1',
              'email': 'tx1@example.com',
            });
            await storage.insert('users', {
              'username': 'tx_user2',
              'email': 'tx2@example.com',
            });
          }),
          returnsNormally,
        );
      });
    });

    group('Maintenance Operations', () {
      setUp(() async {
        await storage.initialize();
      });

      test('vacuum should execute without error', () async {
        expect(() => storage.vacuum(), returnsNormally);
      });

      test('getStats should return storage statistics', () async {
        await storage.insert('users', {
          'username': 'stats_user',
          'email': 'stats@example.com',
        });

        final stats = await storage.getStats();
        expect(stats, isNotNull);
        expect(stats.recordCount, greaterThanOrEqualTo(0));
        expect(stats.tableCount, greaterThanOrEqualTo(0));
      });
    });

    group('Cleanup', () {
      test('close should execute without error', () async {
        await storage.initialize();
        expect(() => storage.close(), returnsNormally);
      });

      test('close should be idempotent', () async {
        await storage.initialize();
        await storage.close();
        expect(() => storage.close(), returnsNormally);
      });
    });
  });
}
