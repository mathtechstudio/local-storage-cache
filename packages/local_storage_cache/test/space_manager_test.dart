import 'package:flutter_test/flutter_test.dart';
import 'package:local_storage_cache/local_storage_cache.dart';

void main() {
  group('SpaceManager', () {
    late SpaceManager spaceManager;
    late Map<String, List<Map<String, dynamic>>> mockDatabase;
    late int nextId;

    setUp(() {
      mockDatabase = {};
      nextId = 1;

      // Mock database executor functions
      Future<List<Map<String, dynamic>>> executeRawQuery(
        String sql, [
        List<dynamic>? arguments,
      ]) async {
        String? tableName;

        if (sql.contains('CREATE TABLE IF NOT EXISTS')) {
          final match =
              RegExp(r'CREATE TABLE IF NOT EXISTS (\w+)').firstMatch(sql);
          if (match != null) {
            tableName = match.group(1);
            mockDatabase[tableName!] = [];
          }
          return [];
        } else if (sql.contains('SELECT')) {
          if (sql.contains('FROM')) {
            final match = RegExp(r'FROM (\w+)').firstMatch(sql);
            if (match != null) {
              tableName = match.group(1);
              final table = mockDatabase[tableName] ?? [];

              // Handle WHERE clauses
              if (arguments != null &&
                  arguments.isNotEmpty &&
                  sql.contains('WHERE')) {
                if (sql.contains('name = ?')) {
                  return table
                      .where((row) => row['name'] == arguments[0])
                      .toList();
                } else if (sql.contains('table_name = ?')) {
                  return table
                      .where((row) => row['table_name'] == arguments[0])
                      .toList();
                }
              }

              // Handle ORDER BY
              if (sql.contains('ORDER BY')) {
                return List.from(table);
              }

              // Filter out metadata tables for sqlite_master queries
              if (tableName == 'sqlite_master' && sql.contains('NOT LIKE')) {
                return table
                    .where((row) => !(row['name'] as String).startsWith('_'))
                    .toList();
              }

              return table;
            }
          }
          return [];
        } else if (sql.contains('DROP TABLE')) {
          final match = RegExp(r'DROP TABLE IF EXISTS (\w+)').firstMatch(sql);
          if (match != null) {
            tableName = match.group(1);
            mockDatabase.remove(tableName);
          }
          return [];
        }

        return [];
      }

      Future<int> executeRawInsert(
        String sql, [
        List<dynamic>? arguments,
      ]) async {
        String? tableName;

        if (sql.contains('INSERT INTO')) {
          final match = RegExp(r'INSERT INTO (\w+)').firstMatch(sql);
          if (match != null) {
            tableName = match.group(1);
            final table = mockDatabase[tableName] ?? [];

            final columnsMatch = RegExp(r'\(([^)]+)\) VALUES').firstMatch(sql);
            if (columnsMatch != null && arguments != null) {
              final columns = columnsMatch
                  .group(1)!
                  .split(',')
                  .map((c) => c.trim())
                  .toList();

              final row = <String, dynamic>{'id': nextId++};
              for (var i = 0; i < columns.length; i++) {
                if (i < arguments.length) {
                  row[columns[i]] = arguments[i];
                }
              }

              table.add(row);
              mockDatabase[tableName!] = table;
              return row['id'] as int;
            }
          }
        }

        return nextId++;
      }

      Future<int> executeRawUpdate(
        String sql, [
        List<dynamic>? arguments,
      ]) async {
        String? tableName;

        if (sql.contains('UPDATE')) {
          final match = RegExp(r'UPDATE (\w+)').firstMatch(sql);
          if (match != null) {
            tableName = match.group(1);
            final table = mockDatabase[tableName] ?? [];

            if (arguments != null && sql.contains('WHERE')) {
              final whereValue = arguments.last;

              for (final row in table) {
                if (sql.contains('name = ?') && row['name'] == whereValue) {
                  if (arguments.isNotEmpty) {
                    row['metadata'] = arguments[0];
                  }
                }
              }

              return 1;
            }
          }
        }

        return 0;
      }

      Future<int> executeRawDelete(
        String sql, [
        List<dynamic>? arguments,
      ]) async {
        String? tableName;

        if (sql.contains('DELETE FROM')) {
          final match = RegExp(r'DELETE FROM (\w+)').firstMatch(sql);
          if (match != null) {
            tableName = match.group(1);
            final table = mockDatabase[tableName] ?? [];

            if (arguments != null && sql.contains('WHERE')) {
              final whereValue = arguments[0];

              if (sql.contains('name = ?')) {
                table.removeWhere((row) => row['name'] == whereValue);
              } else if (sql.contains('table_name = ?')) {
                table.removeWhere((row) => row['table_name'] == whereValue);
              }

              return 1;
            }
          }
        }

        return 0;
      }

      spaceManager = SpaceManager(
        executeRawQuery: executeRawQuery,
        executeRawInsert: executeRawInsert,
        executeRawUpdate: executeRawUpdate,
        executeRawDelete: executeRawDelete,
      );
    });

    group('Initialization', () {
      test('should create metadata tables on initialize', () async {
        await spaceManager.initialize();

        expect(mockDatabase.containsKey('_spaces'), isTrue);
        expect(mockDatabase.containsKey('_global_tables'), isTrue);
      });

      test('should create default space on initialize', () async {
        await spaceManager.initialize();

        final spaces = mockDatabase['_spaces']!;
        expect(spaces.any((s) => s['name'] == 'default'), isTrue);
      });

      test('should set current space to default', () async {
        await spaceManager.initialize();

        expect(spaceManager.currentSpace, equals('default'));
      });
    });

    group('Space Creation', () {
      test('should create a new space', () async {
        await spaceManager.initialize();

        await spaceManager.createSpace('user1');

        final spaces = mockDatabase['_spaces']!;
        expect(spaces.any((s) => s['name'] == 'user1'), isTrue);
      });

      test('should create space with metadata', () async {
        await spaceManager.initialize();

        await spaceManager.createSpace('user1', metadata: {'userId': '123'});

        final spaces = mockDatabase['_spaces']!;
        final space = spaces.firstWhere((s) => s['name'] == 'user1');
        expect(space['metadata'], isNotNull);
      });

      test('should throw if space already exists', () async {
        await spaceManager.initialize();

        await spaceManager.createSpace('user1');

        expect(
          () => spaceManager.createSpace('user1'),
          throwsStateError,
        );
      });

      test('should validate space name', () async {
        await spaceManager.initialize();

        expect(
          () => spaceManager.createSpace(''),
          throwsArgumentError,
        );

        expect(
          () => spaceManager.createSpace('user_1'),
          throwsArgumentError,
        );

        expect(
          () => spaceManager.createSpace('user@1'),
          throwsArgumentError,
        );
      });
    });

    group('Space Deletion', () {
      test('should delete a space', () async {
        await spaceManager.initialize();
        await spaceManager.createSpace('user1');

        await spaceManager.deleteSpace('user1');

        final spaces = mockDatabase['_spaces']!;
        expect(spaces.any((s) => s['name'] == 'user1'), isFalse);
      });

      test('should not delete default space', () async {
        await spaceManager.initialize();

        expect(
          () => spaceManager.deleteSpace('default'),
          throwsStateError,
        );
      });

      test('should not delete current space', () async {
        await spaceManager.initialize();
        await spaceManager.createSpace('user1');
        await spaceManager.switchSpace('user1');

        expect(
          () => spaceManager.deleteSpace('user1'),
          throwsStateError,
        );
      });

      test('should delete space tables', () async {
        await spaceManager.initialize();
        await spaceManager.createSpace('user1');

        // Create mock tables for the space
        mockDatabase['user1_posts'] = [];
        mockDatabase['user1_comments'] = [];
        mockDatabase['sqlite_master'] = [
          {'name': 'user1_posts', 'type': 'table'},
          {'name': 'user1_comments', 'type': 'table'},
        ];

        await spaceManager.deleteSpace('user1');

        expect(mockDatabase.containsKey('user1_posts'), isFalse);
        expect(mockDatabase.containsKey('user1_comments'), isFalse);
      });
    });

    group('Space Switching', () {
      test('should switch to existing space', () async {
        await spaceManager.initialize();
        await spaceManager.createSpace('user1');

        await spaceManager.switchSpace('user1');

        expect(spaceManager.currentSpace, equals('user1'));
      });

      test('should create space if it does not exist', () async {
        await spaceManager.initialize();

        await spaceManager.switchSpace('user1');

        expect(spaceManager.currentSpace, equals('user1'));
        final spaces = mockDatabase['_spaces']!;
        expect(spaces.any((s) => s['name'] == 'user1'), isTrue);
      });
    });

    group('Global Tables', () {
      test('should register a global table', () async {
        await spaceManager.initialize();

        await spaceManager.registerGlobalTable('settings');

        expect(spaceManager.isGlobalTable('settings'), isTrue);
        final globalTables = mockDatabase['_global_tables']!;
        expect(globalTables.any((t) => t['table_name'] == 'settings'), isTrue);
      });

      test('should not duplicate global table registration', () async {
        await spaceManager.initialize();

        await spaceManager.registerGlobalTable('settings');
        await spaceManager.registerGlobalTable('settings');

        final globalTables = mockDatabase['_global_tables']!;
        final count =
            globalTables.where((t) => t['table_name'] == 'settings').length;
        expect(count, equals(1));
      });

      test('should unregister a global table', () async {
        await spaceManager.initialize();
        await spaceManager.registerGlobalTable('settings');

        await spaceManager.unregisterGlobalTable('settings');

        expect(spaceManager.isGlobalTable('settings'), isFalse);
      });

      test('should register global tables from schemas', () async {
        await spaceManager.initialize();

        final schemas = [
          TableSchema(
            name: 'settings',
            fields: [FieldSchema.text(name: 'key')],
            isGlobal: true,
          ),
          TableSchema(
            name: 'users',
            fields: [FieldSchema.text(name: 'name')],
          ),
        ];

        await spaceManager.registerGlobalTablesFromSchemas(schemas);

        expect(spaceManager.isGlobalTable('settings'), isTrue);
        expect(spaceManager.isGlobalTable('users'), isFalse);
      });
    });

    group('Table Name Prefixing', () {
      test('should prefix table names with space', () async {
        await spaceManager.initialize();
        await spaceManager.switchSpace('user1');

        final prefixed = spaceManager.getPrefixedTableName('posts');

        expect(prefixed, equals('user1_posts'));
      });

      test('should not prefix global tables', () async {
        await spaceManager.initialize();
        await spaceManager.registerGlobalTable('settings');
        await spaceManager.switchSpace('user1');

        final prefixed = spaceManager.getPrefixedTableName('settings');

        expect(prefixed, equals('settings'));
      });

      test('should not prefix metadata tables', () async {
        await spaceManager.initialize();

        final prefixed = spaceManager.getPrefixedTableName('_spaces');

        expect(prefixed, equals('_spaces'));
      });

      test('should unprefix table names', () async {
        await spaceManager.initialize();
        await spaceManager.switchSpace('user1');

        final unprefixed = spaceManager.getUnprefixedTableName('user1_posts');

        expect(unprefixed, equals('posts'));
      });

      test('should not unprefix global tables', () async {
        await spaceManager.initialize();
        await spaceManager.registerGlobalTable('settings');

        final unprefixed = spaceManager.getUnprefixedTableName('settings');

        expect(unprefixed, equals('settings'));
      });
    });

    group('Space Listing', () {
      test('should list all spaces', () async {
        await spaceManager.initialize();
        await spaceManager.createSpace('user1');
        await spaceManager.createSpace('user2');

        final spaces = await spaceManager.listSpaces();

        expect(spaces, contains('default'));
        expect(spaces, contains('user1'));
        expect(spaces, contains('user2'));
      });
    });

    group('Space Metadata', () {
      test('should get space metadata', () async {
        await spaceManager.initialize();
        await spaceManager.createSpace('user1', metadata: {'userId': '123'});

        final metadata = await spaceManager.getSpaceMetadata('user1');

        expect(metadata, isNotNull);
      });

      test('should return null for non-existent space', () async {
        await spaceManager.initialize();

        final metadata = await spaceManager.getSpaceMetadata('nonexistent');

        expect(metadata, isNull);
      });

      test('should update space metadata', () async {
        await spaceManager.initialize();
        await spaceManager.createSpace('user1');

        await spaceManager.updateSpaceMetadata('user1', {'userId': '123'});

        final spaces = mockDatabase['_spaces']!;
        final space = spaces.firstWhere((s) => s['name'] == 'user1');
        expect(space['metadata'], isNotNull);
      });
    });

    group('Space Statistics', () {
      test('should get space statistics', () async {
        await spaceManager.initialize();
        await spaceManager.createSpace('user1');

        // Create mock tables with data
        mockDatabase['user1_posts'] = [
          {'id': 1, 'title': 'Post 1'},
          {'id': 2, 'title': 'Post 2'},
        ];
        mockDatabase['sqlite_master'] = [
          {'name': 'user1_posts', 'type': 'table'},
        ];

        final stats = await spaceManager.getSpaceStats('user1');

        expect(stats.tableCount, equals(1));
        expect(stats.recordCount, greaterThanOrEqualTo(0));
      });
    });

    group('Space Existence', () {
      test('should check if space exists', () async {
        await spaceManager.initialize();
        await spaceManager.createSpace('user1');

        final exists = await spaceManager.spaceExists('user1');
        final notExists = await spaceManager.spaceExists('user2');

        expect(exists, isTrue);
        expect(notExists, isFalse);
      });
    });

    group('Global Tables Loading', () {
      test('should load global tables from database', () async {
        await spaceManager.initialize();

        // Manually add global tables to database
        mockDatabase['_global_tables'] = [
          {
            'id': 1,
            'table_name': 'settings',
            'registered_at': DateTime.now().toIso8601String(),
          },
          {
            'id': 2,
            'table_name': 'config',
            'registered_at': DateTime.now().toIso8601String(),
          },
        ];

        await spaceManager.loadGlobalTables();

        expect(spaceManager.isGlobalTable('settings'), isTrue);
        expect(spaceManager.isGlobalTable('config'), isTrue);
      });
    });

    group('Thread Safety', () {
      test('should handle concurrent operations', () async {
        await spaceManager.initialize();

        // Execute multiple operations concurrently
        await Future.wait([
          spaceManager.createSpace('user1'),
          spaceManager.createSpace('user2'),
          spaceManager.createSpace('user3'),
        ]);

        final spaces = await spaceManager.listSpaces();
        expect(spaces.length, greaterThanOrEqualTo(4)); // default + 3 new
      });
    });
  });
}
