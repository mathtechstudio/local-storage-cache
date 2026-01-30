import 'package:flutter_test/flutter_test.dart';
import 'package:local_storage_cache/src/config/storage_config.dart';
import 'package:local_storage_cache/src/enums/data_type.dart';
import 'package:local_storage_cache/src/models/query_condition.dart';
import 'package:local_storage_cache/src/schema/field_schema.dart';
import 'package:local_storage_cache/src/schema/table_schema.dart';
import 'package:local_storage_cache/src/storage_engine.dart';

import 'mocks/mock_platform_channels.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(setupMockPlatformChannels);

  group('QueryBuilder', () {
    late StorageEngine storage;

    setUp(() async {
      resetMockData();
      storage = StorageEngine(
        config: const StorageConfig(
          databaseName: 'test_query_builder.db',
        ),
        schemas: [
          const TableSchema(
            name: 'users',
            fields: [
              FieldSchema(name: 'username', type: DataType.text),
              FieldSchema(name: 'email', type: DataType.text),
              FieldSchema(name: 'age', type: DataType.integer),
              FieldSchema(name: 'status', type: DataType.text),
              FieldSchema(name: 'role', type: DataType.text),
            ],
          ),
          const TableSchema(
            name: 'posts',
            fields: [
              FieldSchema(name: 'title', type: DataType.text),
              FieldSchema(name: 'content', type: DataType.text),
              FieldSchema(name: 'author_id', type: DataType.integer),
              FieldSchema(name: 'published', type: DataType.boolean),
            ],
          ),
        ],
      );
      await storage.initialize();

      // Setup mock data for tests
      setMockQueryResults([
        {
          'id': 1,
          'username': 'john',
          'email': 'john@example.com',
          'age': 25,
          'status': 'active',
          'role': 'user',
        },
        {
          'id': 2,
          'username': 'jane',
          'email': 'jane@example.com',
          'age': 30,
          'status': 'active',
          'role': 'admin',
        },
        {
          'id': 3,
          'username': 'bob',
          'email': 'bob@example.com',
          'age': 20,
          'status': 'inactive',
          'role': 'user',
        },
        {
          'id': 4,
          'username': 'alice',
          'email': 'alice@example.com',
          'age': 35,
          'status': 'active',
          'role': 'moderator',
        },
      ]);
    });

    tearDown(() async {
      await storage.close();
      resetMockData();
    });

    group('Basic WHERE Clauses', () {
      test('where with = operator', () async {
        final query = storage.query('users')..where('status', '=', 'active');
        final results = await query.get();

        expect(results.length, equals(3));
        expect(results.every((r) => r['status'] == 'active'), isTrue);
      });

      test('whereEqual shorthand', () async {
        final query = storage.query('users')..whereEqual('role', 'admin');
        final results = await query.get();

        expect(results.length, equals(1));
        expect(results.first['username'], equals('jane'));
      });

      test('whereNotEqual', () async {
        final query = storage.query('users')
          ..whereNotEqual('status', 'inactive');
        final results = await query.get();

        expect(results.length, equals(3));
        expect(results.every((r) => r['status'] != 'inactive'), isTrue);
      });

      test('whereGreaterThan', () async {
        final query = storage.query('users')..whereGreaterThan('age', 25);
        final results = await query.get();

        expect(results.length, equals(2));
        expect(results.every((r) => (r['age'] as int) > 25), isTrue);
      });

      test('whereLessThan', () async {
        final query = storage.query('users')..whereLessThan('age', 30);
        final results = await query.get();

        expect(results.length, equals(2));
        expect(results.every((r) => (r['age'] as int) < 30), isTrue);
      });
    });

    group('Advanced WHERE Clauses', () {
      test('whereIn', () async {
        final query = storage.query('users')
          ..whereIn('role', ['admin', 'moderator']);
        final results = await query.get();

        expect(results.length, equals(2));
        expect(
          results.every((r) => ['admin', 'moderator'].contains(r['role'])),
          isTrue,
        );
      });

      test('whereNotIn', () async {
        final query = storage.query('users')
          ..whereNotIn('role', ['admin', 'moderator']);
        final results = await query.get();

        expect(results.length, equals(2));
        expect(results.every((r) => r['role'] == 'user'), isTrue);
      });

      test('whereBetween', () async {
        final query = storage.query('users')..whereBetween('age', 20, 30);
        final results = await query.get();

        expect(results.length, equals(3));
        expect(
          results.every(
            (r) => (r['age'] as int) >= 20 && (r['age'] as int) <= 30,
          ),
          isTrue,
        );
      });

      test('whereLike', () async {
        final query = storage.query('users')
          ..whereLike('email', '%example.com');
        final results = await query.get();

        expect(results.length, equals(4));
        expect(
          results.every((r) => (r['email'] as String).endsWith('example.com')),
          isTrue,
        );
      });

      test('whereNull', () async {
        // Insert user with null email
        await storage.insert('users', {
          'username': 'nulluser',
          'age': 40,
        });

        final query = storage.query('users')..whereNull('email');
        final results = await query.get();

        expect(results.length, greaterThanOrEqualTo(1));
      });

      test('whereNotNull', () async {
        final query = storage.query('users')..whereNotNull('email');
        final results = await query.get();

        expect(results.length, equals(4));
        expect(results.every((r) => r['email'] != null), isTrue);
      });
    });

    group('Logical Operators', () {
      test('multiple WHERE with implicit AND', () async {
        final query = storage.query('users')
          ..where('status', '=', 'active')
          ..where('age', '>', 25);
        final results = await query.get();

        expect(results.length, equals(2));
        expect(
          results.every(
            (r) =>
                (r['status'] as String?) == 'active' && (r['age'] as int) > 25,
          ),
          isTrue,
        );
      });

      test('OR operator', () async {
        final query = storage.query('users')
          ..where('role', '=', 'admin')
          ..or()
          ..where('role', '=', 'moderator');
        final results = await query.get();

        expect(results.length, equals(2));
      });

      test('complex AND/OR combination', () async {
        final query = storage.query('users')
          ..where('status', '=', 'active')
          ..where('age', '>', 20)
          ..or()
          ..where('role', '=', 'admin');
        final results = await query.get();

        expect(results.length, greaterThanOrEqualTo(1));
      });
    });

    group('Field Selection', () {
      test('select specific fields', () async {
        final query = storage.query('users')..select(['username', 'email']);
        final results = await query.get();

        expect(results.isNotEmpty, isTrue);
        expect(results.first.containsKey('username'), isTrue);
        expect(results.first.containsKey('email'), isTrue);
      });

      test('select all fields by default', () async {
        final query = storage.query('users');
        final results = await query.get();

        expect(results.isNotEmpty, isTrue);
        expect(results.first.containsKey('username'), isTrue);
        expect(results.first.containsKey('email'), isTrue);
        expect(results.first.containsKey('age'), isTrue);
      });
    });

    group('Ordering', () {
      test('orderBy ascending', () async {
        final query = storage.query('users')..orderBy('age');
        final results = await query.get();

        expect(results.length, equals(4));
        expect(results.first['age'], equals(20));
        expect(results.last['age'], equals(35));
      });

      test('orderByAsc shorthand', () async {
        final query = storage.query('users')..orderByAsc('username');
        final results = await query.get();

        expect(results.first['username'], equals('alice'));
      });

      test('orderByDesc', () async {
        final query = storage.query('users')..orderByDesc('age');
        final results = await query.get();

        expect(results.first['age'], equals(35));
        expect(results.last['age'], equals(20));
      });

      test('multiple orderBy clauses', () async {
        final query = storage.query('users')
          ..orderBy('status')
          ..orderBy('age', ascending: false);
        final results = await query.get();

        expect(results.isNotEmpty, isTrue);
      });
    });

    group('Pagination', () {
      test('limit results', () async {
        final query = storage.query('users')..limit = 2;
        final results = await query.get();

        expect(results.length, equals(2));
      });

      test('offset results', () async {
        final query = storage.query('users')
          ..orderByAsc('age')
          ..offset = 2;
        final results = await query.get();

        expect(results.length, equals(2));
        expect(results.first['age'], greaterThanOrEqualTo(25));
      });

      test('limit and offset together', () async {
        final query = storage.query('users')
          ..orderByAsc('age')
          ..limit = 2
          ..offset = 1;
        final results = await query.get();

        expect(results.length, equals(2));
      });
    });

    group('Execution Methods', () {
      test('get returns all matching records', () async {
        final query = storage.query('users');
        final results = await query.get();

        expect(results.length, equals(4));
        expect(results, isA<List<Map<String, dynamic>>>());
      });

      test('first returns only first record', () async {
        final query = storage.query('users')..orderByAsc('age');
        final result = await query.first();

        expect(result, isNotNull);
        expect(result!['age'], equals(20));
      });

      test('first returns null when no results', () async {
        final query = storage.query('users')
          ..where('username', '=', 'nonexistent');
        final result = await query.first();

        expect(result, isNull);
      });

      test('count returns number of matching records', () async {
        final query = storage.query('users')..where('status', '=', 'active');
        final count = await query.count();

        expect(count, equals(3));
      });

      test('count returns 0 when no results', () async {
        final query = storage.query('users')
          ..where('username', '=', 'nonexistent');
        final count = await query.count();

        expect(count, equals(0));
      });
    });

    group('Update and Delete with Conditions', () {
      test('update with WHERE condition', () async {
        final query = storage.query('users')..where('username', '=', 'john');
        await query.update({'age': 26});

        final updated = await storage.findById('users', 1);
        expect(updated!['age'], equals(26));
      });

      test('delete with WHERE condition', () async {
        final query = storage.query('users')..where('status', '=', 'inactive');
        await query.delete();

        final remaining = await storage.query('users').get();
        expect(remaining.length, equals(3));
        expect(remaining.every((r) => r['status'] != 'inactive'), isTrue);
      });
    });

    group('Stream Operations', () {
      test('stream yields records one by one', () async {
        final query = storage.query('users')..orderByAsc('age');

        final streamedRecords = <Map<String, dynamic>>[];
        await for (final record in query.stream()) {
          streamedRecords.add(record);
        }

        expect(streamedRecords.length, equals(4));
        expect(streamedRecords.first['age'], equals(20));
      });

      test('stream can be cancelled early', () async {
        final query = storage.query('users');

        var count = 0;
        await for (final _ in query.stream()) {
          count++;
          if (count >= 2) break;
        }

        expect(count, equals(2));
      });

      test('stream with WHERE conditions', () async {
        final query = storage.query('users')..where('status', '=', 'active');

        final streamedRecords = <Map<String, dynamic>>[];
        await for (final record in query.stream()) {
          streamedRecords.add(record);
        }

        expect(streamedRecords.length, equals(3));
        expect(
          streamedRecords.every((r) => r['status'] == 'active'),
          isTrue,
        );
      });
    });

    group('JOIN Operations', () {
      setUp(() async {
        // Insert posts data
        await storage.batchInsert('posts', [
          {
            'title': 'Post 1',
            'content': 'Content 1',
            'author_id': 1,
            'published': true,
          },
          {
            'title': 'Post 2',
            'content': 'Content 2',
            'author_id': 2,
            'published': true,
          },
          {
            'title': 'Post 3',
            'content': 'Content 3',
            'author_id': 1,
            'published': false,
          },
        ]);
      });

      test('join tables', () async {
        final query = storage.query('posts')
          ..join('users', 'posts.author_id', '=', 'users.id');
        final results = await query.get();

        expect(results.isNotEmpty, isTrue);
      });

      test('leftJoin', () async {
        final query = storage.query('posts')
          ..leftJoin('users', 'posts.author_id', '=', 'users.id');
        final results = await query.get();

        expect(results.isNotEmpty, isTrue);
      });

      test('join with WHERE conditions', () async {
        final query = storage.query('posts')
          ..join('users', 'posts.author_id', '=', 'users.id')
          ..where('posts.published', '=', true);
        final results = await query.get();

        expect(results.length, greaterThanOrEqualTo(1));
      });
    });

    group('Custom WHERE Clauses', () {
      test('whereCustom with custom SQL', () async {
        final query = storage.query('users')
          ..whereCustom('age > ? AND age < ?', [20, 35]);
        final results = await query.get();

        expect(results.length, greaterThanOrEqualTo(1));
        expect(
          results.every(
            (r) => (r['age'] as int) > 20 && (r['age'] as int) < 35,
          ),
          isTrue,
        );
      });
    });

    group('Nested Conditions', () {
      test('condition with QueryCondition', () async {
        final condition = QueryCondition()
          ..where('age', '>', 25)
          ..where('status', '=', 'active');

        final query = storage.query('users')..condition(condition);
        final results = await query.get();

        expect(results.isNotEmpty, isTrue);
      });

      test('orCondition', () async {
        final condition = QueryCondition()..where('role', '=', 'admin');

        final query = storage.query('users')
          ..where('age', '<', 25)
          ..orCondition(condition);
        final results = await query.get();

        expect(results.length, greaterThanOrEqualTo(1));
      });
    });
  });
}
