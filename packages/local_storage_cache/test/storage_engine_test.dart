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

  group('StorageEngine', () {
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
                unique: true,
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
      // Close storage if initialized
      try {
        await storage.close();
      } catch (e) {
        // Ignore if not initialized
      }
      resetMockData();
    });

    group('Initialization', () {
      test('should initialize successfully', () async {
        await storage.initialize();
        // Verify initialization by checking if we can perform operations
        expect(() => storage.query('users'), returnsNormally);
      });

      test('should not initialize twice', () async {
        await storage.initialize();
        await storage.initialize(); // Should not throw
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
      });

      test('findById should retrieve record by ID', () async {
        final id = await storage.insert('users', {
          'username': 'jane_doe',
          'email': 'jane@example.com',
          'age': 30,
        });

        final record = await storage.findById('users', id);
        expect(record, isNotNull);
        expect(record!['username'], equals('jane_doe'));
        expect(record['email'], equals('jane@example.com'));
      });

      test('update should modify existing record', () async {
        final id = await storage.insert('users', {
          'username': 'bob',
          'email': 'bob@example.com',
          'age': 20,
        });

        await storage.update('users', {
          'age': 21,
        });

        final record = await storage.findById('users', id);
        expect(record!['age'], equals(21));
      });

      test('delete should remove record', () async {
        await storage.insert('users', {
          'username': 'alice',
          'email': 'alice@example.com',
        });

        await storage.delete('users');

        final results = await storage.query('users').get();
        expect(results, isEmpty);
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

        await storage.batchInsert('users', users);

        final results = await storage.query('users').get();
        expect(results.length, equals(3));
      });

      test('batchUpdate should update multiple records', () async {
        final users = [
          {'username': 'user1', 'email': 'user1@example.com', 'age': 20},
          {'username': 'user2', 'email': 'user2@example.com', 'age': 21},
        ];

        await storage.batchInsert('users', users);

        final updates = [
          {'username': 'user1', 'age': 25},
          {'username': 'user2', 'age': 26},
        ];

        await storage.batchUpdate('users', updates);

        final results = await storage.query('users').get();
        expect(results.any((r) => r['age'] == 25), isTrue);
      });

      test('batchDelete should remove multiple records', () async {
        final id1 = await storage.insert('users', {
          'username': 'user1',
          'email': 'user1@example.com',
        });
        final id2 = await storage.insert('users', {
          'username': 'user2',
          'email': 'user2@example.com',
        });

        await storage.batchDelete('users', [id1, id2]);

        final results = await storage.query('users').get();
        expect(results, isEmpty);
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

      test('should isolate data between spaces', () async {
        // Insert in space1
        await storage.switchSpace(spaceName: 'space1');
        await storage.insert('users', {
          'username': 'user_space1',
          'email': 'user1@example.com',
        });

        // Insert in space2
        await storage.switchSpace(spaceName: 'space2');
        await storage.insert('users', {
          'username': 'user_space2',
          'email': 'user2@example.com',
        });

        // Verify space2 data
        final space2Results = await storage.query('users').get();
        expect(space2Results.length, equals(1));
        expect(space2Results.first['username'], equals('user_space2'));

        // Verify space1 data
        await storage.switchSpace(spaceName: 'space1');
        final space1Results = await storage.query('users').get();
        expect(space1Results.length, equals(1));
        expect(space1Results.first['username'], equals('user_space1'));
      });
    });

    group('Key-Value Operations', () {
      setUp(() async {
        await storage.initialize();
      });

      test('setValue and getValue should work correctly', () async {
        await storage.setValue('test_key', 'test_value');
        final value = await storage.getValue<String>('test_key');
        expect(value, equals('test_value'));
      });

      test('should handle different data types', () async {
        await storage.setValue('string_key', 'hello');
        await storage.setValue('int_key', 42);
        await storage.setValue('double_key', 3.14);
        await storage.setValue('bool_key', true);

        expect(await storage.getValue<String>('string_key'), equals('hello'));
        expect(await storage.getValue<int>('int_key'), equals(42));
        expect(await storage.getValue<double>('double_key'), equals(3.14));
        expect(await storage.getValue<bool>('bool_key'), equals(true));
      });

      test('should support global key-value storage', () async {
        await storage.setValue('global_key', 'global_value', isGlobal: true);

        // Switch space and verify global value is still accessible
        await storage.switchSpace(spaceName: 'other_space');
        final value = await storage.getValue<String>(
          'global_key',
          isGlobal: true,
        );
        expect(value, equals('global_value'));
      });

      test('deleteValue should remove key-value pair', () async {
        await storage.setValue('temp_key', 'temp_value');
        await storage.deleteValue('temp_key');

        final value = await storage.getValue<String>('temp_key');
        expect(value, isNull);
      });
    });

    group('Stream Operations', () {
      setUp(() async {
        await storage.initialize();
      });

      test('stream yields records one by one', () async {
        // Insert test data
        final users = List.generate(
          10,
          (i) => {
            'username': 'user$i',
            'email': 'user$i@example.com',
            'age': 20 + i,
          },
        );
        await storage.batchInsert('users', users);

        // Stream and collect results
        final streamedRecords = <Map<String, dynamic>>[];
        await for (final record in storage.streamQuery('users')) {
          streamedRecords.add(record);
        }

        expect(streamedRecords.length, equals(10));
        expect(streamedRecords.first['username'], equals('user0'));
      });

      test('stream should be cancellable', () async {
        final users = List.generate(
          100,
          (i) => {
            'username': 'user$i',
            'email': 'user$i@example.com',
          },
        );
        await storage.batchInsert('users', users);

        var count = 0;
        await for (final _ in storage.streamQuery('users')) {
          count++;
          if (count >= 10) break; // Cancel after 10 records
        }

        expect(count, equals(10));
      });
    });

    group('Transaction Management', () {
      setUp(() async {
        await storage.initialize();
      });

      test('transaction should commit on success', () async {
        await storage.transaction(() async {
          await storage.insert('users', {
            'username': 'tx_user1',
            'email': 'tx1@example.com',
          });
          await storage.insert('users', {
            'username': 'tx_user2',
            'email': 'tx2@example.com',
          });
        });

        final results = await storage.query('users').get();
        expect(results.length, equals(2));
      });

      test('transaction should rollback on error', () async {
        try {
          await storage.transaction(() async {
            await storage.insert('users', {
              'username': 'tx_user',
              'email': 'tx@example.com',
            });
            throw Exception('Simulated error');
          });
        } catch (e) {
          // Expected error
        }

        final results = await storage.query('users').get();
        expect(results, isEmpty);
      });
    });

    group('Maintenance Operations', () {
      setUp(() async {
        await storage.initialize();
      });

      test('vacuum should execute without error', () async {
        await storage.vacuum();
        // If no exception thrown, test passes
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
      test('close should cleanup resources', () async {
        await storage.initialize();
        await storage.close();

        // Verify cleanup by checking if operations throw StateError
        expect(() => storage.query('users'), throwsStateError);
      });

      test('close should be idempotent', () async {
        await storage.initialize();
        await storage.close();
        await storage.close(); // Should not throw
      });
    });
  });
}
