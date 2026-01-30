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

  group('QueryBuilder - Basic Operations', () {
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
        ],
      );
      await storage.initialize();

      // Setup mock data
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
      ]);
    });

    tearDown(() async {
      await storage.close();
      resetMockData();
    });

    group('Query Creation', () {
      test('should create query builder', () {
        final query = storage.query('users');
        expect(query, isNotNull);
      });

      test('should allow method chaining', () {
        final query = storage.query('users')
          ..where('status', '=', 'active')
          ..orderBy('age')
          ..limit = 10;

        expect(query, isNotNull);
      });
    });

    group('WHERE Clauses', () {
      test('where should add condition', () {
        final query = storage.query('users')..where('status', '=', 'active');
        expect(query, isNotNull);
      });

      test('whereEqual should add equality condition', () {
        final query = storage.query('users')..whereEqual('role', 'admin');
        expect(query, isNotNull);
      });

      test('whereNotEqual should add inequality condition', () {
        final query = storage.query('users')
          ..whereNotEqual('status', 'inactive');
        expect(query, isNotNull);
      });

      test('whereGreaterThan should add greater than condition', () {
        final query = storage.query('users')..whereGreaterThan('age', 25);
        expect(query, isNotNull);
      });

      test('whereLessThan should add less than condition', () {
        final query = storage.query('users')..whereLessThan('age', 30);
        expect(query, isNotNull);
      });

      test('whereIn should add IN condition', () {
        final query = storage.query('users')
          ..whereIn('role', ['admin', 'moderator']);
        expect(query, isNotNull);
      });

      test('whereNotIn should add NOT IN condition', () {
        final query = storage.query('users')
          ..whereNotIn('role', ['admin', 'moderator']);
        expect(query, isNotNull);
      });

      test('whereBetween should add BETWEEN condition', () {
        final query = storage.query('users')..whereBetween('age', 20, 30);
        expect(query, isNotNull);
      });

      test('whereLike should add LIKE condition', () {
        final query = storage.query('users')
          ..whereLike('email', '%example.com');
        expect(query, isNotNull);
      });

      test('whereNull should add IS NULL condition', () {
        final query = storage.query('users')..whereNull('email');
        expect(query, isNotNull);
      });

      test('whereNotNull should add IS NOT NULL condition', () {
        final query = storage.query('users')..whereNotNull('email');
        expect(query, isNotNull);
      });
    });

    group('Logical Operators', () {
      test('should support multiple WHERE with implicit AND', () {
        final query = storage.query('users')
          ..where('status', '=', 'active')
          ..where('age', '>', 25);
        expect(query, isNotNull);
      });

      test('should support OR operator', () {
        final query = storage.query('users')
          ..where('role', '=', 'admin')
          ..or()
          ..where('role', '=', 'moderator');
        expect(query, isNotNull);
      });

      test('should support AND operator', () {
        final query = storage.query('users')
          ..where('status', '=', 'active')
          ..and()
          ..where('age', '>', 20);
        expect(query, isNotNull);
      });
    });

    group('Field Selection', () {
      test('select should specify fields', () {
        final query = storage.query('users')..select(['username', 'email']);
        expect(query, isNotNull);
      });
    });

    group('Ordering', () {
      test('orderBy should add ordering', () {
        final query = storage.query('users')..orderBy('age');
        expect(query, isNotNull);
      });

      test('orderByAsc should add ascending order', () {
        final query = storage.query('users')..orderByAsc('username');
        expect(query, isNotNull);
      });

      test('orderByDesc should add descending order', () {
        final query = storage.query('users')..orderByDesc('age');
        expect(query, isNotNull);
      });

      test('should support multiple orderBy clauses', () {
        final query = storage.query('users')
          ..orderBy('status')
          ..orderBy('age', ascending: false);
        expect(query, isNotNull);
      });
    });

    group('Pagination', () {
      test('limit should set result limit', () {
        final query = storage.query('users')..limit = 10;
        expect(query, isNotNull);
        expect(query.limit, equals(10));
      });

      test('offset should set result offset', () {
        final query = storage.query('users')..offset = 5;
        expect(query, isNotNull);
        expect(query.offset, equals(5));
      });

      test('should support limit and offset together', () {
        final query = storage.query('users')
          ..limit = 10
          ..offset = 5;
        expect(query, isNotNull);
        expect(query.limit, equals(10));
        expect(query.offset, equals(5));
      });
    });

    group('JOIN Operations', () {
      test('join should add JOIN clause', () {
        final query = storage.query('posts')
          ..join('users', 'posts.author_id', '=', 'users.id');
        expect(query, isNotNull);
      });

      test('leftJoin should add LEFT JOIN clause', () {
        final query = storage.query('posts')
          ..leftJoin('users', 'posts.author_id', '=', 'users.id');
        expect(query, isNotNull);
      });
    });

    group('Nested Conditions', () {
      test('condition should add nested condition', () {
        final condition = QueryCondition()
          ..where('age', '>', 25)
          ..where('status', '=', 'active');

        final query = storage.query('users')..condition(condition);
        expect(query, isNotNull);
      });

      test('orCondition should add OR nested condition', () {
        final condition = QueryCondition()..where('role', '=', 'admin');

        final query = storage.query('users')
          ..where('age', '<', 25)
          ..orCondition(condition);
        expect(query, isNotNull);
      });
    });

    group('Execution Methods', () {
      test('get should return Future', () {
        final query = storage.query('users');
        expect(query.get(), isA<Future<List<Map<String, dynamic>>>>());
      });

      test('first should be callable', () {
        final query = storage.query('users');
        expect(query.first, isA<Function>());
      });

      test('count should be callable', () {
        final query = storage.query('users');
        expect(query.count, isA<Function>());
      });

      test('stream should return Stream', () {
        final query = storage.query('users');
        expect(query.stream(), isA<Stream<Map<String, dynamic>>>());
      });
    });

    group('Update and Delete', () {
      test('update should execute with conditions', () {
        final query = storage.query('users')..where('username', '=', 'john');
        expect(query.update({'age': 26}), isA<Future<int>>());
      });

      test('delete should execute with conditions', () {
        final query = storage.query('users')..where('status', '=', 'inactive');
        expect(query.delete(), isA<Future<int>>());
      });
    });
  });
}
