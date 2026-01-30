import 'package:flutter_test/flutter_test.dart';
import 'package:local_storage_cache/local_storage_cache.dart';

void main() {
  group('ValidationManager', () {
    late ValidationManager validationManager;
    late Map<String, List<Map<String, dynamic>>> mockDatabase;

    setUp(() {
      mockDatabase = {};

      Future<List<Map<String, dynamic>>> executeRawQuery(
        String sql, [
        List<dynamic>? arguments,
      ]) async {
        // Mock COUNT queries for unique and foreign key validation
        if (sql.contains('SELECT COUNT(*) as count')) {
          // Extract table name
          final match = RegExp(r'FROM (\w+)').firstMatch(sql);
          if (match != null) {
            final tableName = match.group(1)!;
            final table = mockDatabase[tableName] ?? [];

            if (sql.contains('WHERE')) {
              // Handle unique constraint check
              if (arguments != null && arguments.isNotEmpty) {
                final value = arguments[0];
                var count = 0;

                for (final row in table) {
                  // Check if any field matches the value
                  if (row.values.contains(value)) {
                    // If there's an id exclusion, check it
                    if (arguments.length > 1) {
                      final excludeId = arguments[1];
                      if (row['id'] != excludeId) {
                        count++;
                      }
                    } else {
                      count++;
                    }
                  }
                }

                return [
                  {'count': count},
                ];
              }
            }

            return [
              {'count': table.length},
            ];
          }
        }

        return [];
      }

      validationManager = ValidationManager(
        executeRawQuery: executeRawQuery,
      );
    });

    group('Schema Registration', () {
      test('should register a schema', () {
        final schema = TableSchema(
          name: 'users',
          fields: [
            FieldSchema.text(name: 'username'),
          ],
        );

        validationManager.registerSchema(schema);

        expect(validationManager.hasSchema('users'), isTrue);
      });

      test('should register multiple schemas', () {
        final schemas = [
          TableSchema(
            name: 'users',
            fields: [FieldSchema.text(name: 'username')],
          ),
          TableSchema(
            name: 'posts',
            fields: [FieldSchema.text(name: 'title')],
          ),
        ];

        validationManager.registerSchemas(schemas);

        expect(validationManager.hasSchema('users'), isTrue);
        expect(validationManager.hasSchema('posts'), isTrue);
      });

      test('should get registered schema', () {
        final schema = TableSchema(
          name: 'users',
          fields: [FieldSchema.text(name: 'username')],
        );

        validationManager.registerSchema(schema);

        final retrieved = validationManager.getSchema('users');
        expect(retrieved, isNotNull);
        expect(retrieved!.name, equals('users'));
      });

      test('should unregister schema', () {
        final schema = TableSchema(
          name: 'users',
          fields: [FieldSchema.text(name: 'username')],
        );

        validationManager
          ..registerSchema(schema)
          ..unregisterSchema('users');

        expect(validationManager.hasSchema('users'), isFalse);
      });

      test('should clear all schemas', () {
        validationManager
          ..registerSchemas([
            TableSchema(
              name: 'users',
              fields: [FieldSchema.text(name: 'username')],
            ),
            TableSchema(
              name: 'posts',
              fields: [FieldSchema.text(name: 'title')],
            ),
          ])
          ..clearSchemas();

        expect(validationManager.getRegisteredTables(), isEmpty);
      });

      test('should list registered tables', () {
        validationManager.registerSchemas([
          TableSchema(
            name: 'users',
            fields: [FieldSchema.text(name: 'username')],
          ),
          TableSchema(
            name: 'posts',
            fields: [FieldSchema.text(name: 'title')],
          ),
        ]);

        final tables = validationManager.getRegisteredTables();
        expect(tables, contains('users'));
        expect(tables, contains('posts'));
      });
    });

    group('Type Validation', () {
      test('should validate integer type', () async {
        final schema = TableSchema(
          name: 'users',
          fields: [
            FieldSchema.integer(name: 'age'),
          ],
        );

        validationManager.registerSchema(schema);

        final validResult = await validationManager.validate('users', {
          'age': 25,
        });

        expect(validResult.isValid, isTrue);

        final invalidResult = await validationManager.validate('users', {
          'age': 'twenty-five',
        });

        expect(invalidResult.isValid, isFalse);
        expect(invalidResult.errors.first.type, equals(ValidationType.type));
      });

      test('should validate text type', () async {
        final schema = TableSchema(
          name: 'users',
          fields: [
            FieldSchema.text(name: 'username'),
          ],
        );

        validationManager.registerSchema(schema);

        final validResult = await validationManager.validate('users', {
          'username': 'john_doe',
        });

        expect(validResult.isValid, isTrue);

        final invalidResult = await validationManager.validate('users', {
          'username': 123,
        });

        expect(invalidResult.isValid, isFalse);
      });

      test('should validate boolean type', () async {
        final schema = TableSchema(
          name: 'users',
          fields: [
            FieldSchema.boolean(name: 'active'),
          ],
        );

        validationManager.registerSchema(schema);

        final validResult = await validationManager.validate('users', {
          'active': true,
        });

        expect(validResult.isValid, isTrue);

        final invalidResult = await validationManager.validate('users', {
          'active': 'yes',
        });

        expect(invalidResult.isValid, isFalse);
      });
    });

    group('Required Field Validation', () {
      test('should validate required fields', () async {
        final schema = TableSchema(
          name: 'users',
          fields: [
            FieldSchema.text(name: 'username', nullable: false),
          ],
        );

        validationManager.registerSchema(schema);

        final validResult = await validationManager.validate('users', {
          'username': 'john_doe',
        });

        expect(validResult.isValid, isTrue);

        final invalidResult = await validationManager.validate('users', {});

        expect(invalidResult.isValid, isFalse);
        expect(
          invalidResult.errors.first.type,
          equals(ValidationType.required),
        );
      });

      test('should allow null for nullable fields', () async {
        final schema = TableSchema(
          name: 'users',
          fields: [
            FieldSchema.text(name: 'bio'),
          ],
        );

        validationManager.registerSchema(schema);

        final result = await validationManager.validate('users', {
          'bio': null,
        });

        expect(result.isValid, isTrue);
      });
    });

    group('Length Validation', () {
      test('should validate minimum length', () async {
        final schema = TableSchema(
          name: 'users',
          fields: [
            FieldSchema.text(name: 'username', minLength: 3),
          ],
        );

        validationManager.registerSchema(schema);

        final validResult = await validationManager.validate('users', {
          'username': 'john',
        });

        expect(validResult.isValid, isTrue);

        final invalidResult = await validationManager.validate('users', {
          'username': 'jo',
        });

        expect(invalidResult.isValid, isFalse);
        expect(invalidResult.errors.first.type, equals(ValidationType.length));
      });

      test('should validate maximum length', () async {
        final schema = TableSchema(
          name: 'users',
          fields: [
            FieldSchema.text(name: 'username', maxLength: 10),
          ],
        );

        validationManager.registerSchema(schema);

        final validResult = await validationManager.validate('users', {
          'username': 'john_doe',
        });

        expect(validResult.isValid, isTrue);

        final invalidResult = await validationManager.validate('users', {
          'username': 'very_long_username',
        });

        expect(invalidResult.isValid, isFalse);
        expect(invalidResult.errors.first.type, equals(ValidationType.length));
      });

      test('should validate both min and max length', () async {
        final schema = TableSchema(
          name: 'users',
          fields: [
            FieldSchema.text(name: 'username', minLength: 3, maxLength: 10),
          ],
        );

        validationManager.registerSchema(schema);

        final validResult = await validationManager.validate('users', {
          'username': 'john',
        });

        expect(validResult.isValid, isTrue);
      });
    });

    group('Pattern Validation', () {
      test('should validate regex pattern', () async {
        final schema = TableSchema(
          name: 'users',
          fields: [
            FieldSchema.text(
              name: 'email',
              pattern: r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
            ),
          ],
        );

        validationManager.registerSchema(schema);

        final validResult = await validationManager.validate('users', {
          'email': 'john@example.com',
        });

        expect(validResult.isValid, isTrue);

        final invalidResult = await validationManager.validate('users', {
          'email': 'invalid-email',
        });

        expect(invalidResult.isValid, isFalse);
        expect(
          invalidResult.errors.first.type,
          equals(ValidationType.pattern),
        );
      });
    });

    group('Unique Constraint Validation', () {
      test('should validate unique constraint', () async {
        final schema = TableSchema(
          name: 'users',
          fields: [
            FieldSchema.text(name: 'email', unique: true),
          ],
        );

        validationManager.registerSchema(schema);

        // Mock existing data
        mockDatabase['users'] = [
          {'id': 1, 'email': 'existing@example.com'},
        ];

        final validResult = await validationManager.validate('users', {
          'email': 'new@example.com',
        });

        expect(validResult.isValid, isTrue);

        final invalidResult = await validationManager.validate('users', {
          'email': 'existing@example.com',
        });

        expect(invalidResult.isValid, isFalse);
        expect(invalidResult.errors.first.type, equals(ValidationType.unique));
      });

      test('should allow same value when updating', () async {
        final schema = TableSchema(
          name: 'users',
          fields: [
            FieldSchema.text(name: 'email', unique: true),
          ],
        );

        validationManager.registerSchema(schema);

        mockDatabase['users'] = [
          {'id': 1, 'email': 'user@example.com'},
        ];

        final result = await validationManager.validate(
          'users',
          {'email': 'user@example.com'},
          isUpdate: true,
          existingId: 1,
        );

        expect(result.isValid, isTrue);
      });
    });

    group('Foreign Key Validation', () {
      test('should validate foreign key constraint', () async {
        final schema = TableSchema(
          name: 'posts',
          fields: [
            FieldSchema.text(name: 'title'),
            FieldSchema.integer(name: 'user_id'),
          ],
          foreignKeys: [
            const ForeignKeySchema(
              field: 'user_id',
              referenceTable: 'users',
              referenceField: 'id',
            ),
          ],
        );

        validationManager.registerSchema(schema);

        // Mock referenced table
        mockDatabase['users'] = [
          {'id': 1, 'username': 'john'},
        ];

        final validResult = await validationManager.validate('posts', {
          'title': 'My Post',
          'user_id': 1,
        });

        expect(validResult.isValid, isTrue);

        final invalidResult = await validationManager.validate('posts', {
          'title': 'My Post',
          'user_id': 999,
        });

        expect(invalidResult.isValid, isFalse);
        expect(
          invalidResult.errors.first.type,
          equals(ValidationType.foreignKey),
        );
      });
    });

    group('Custom Validation', () {
      test('should validate using custom validator', () async {
        final schema = TableSchema(
          name: 'users',
          fields: [
            FieldSchema(
              name: 'age',
              type: DataType.integer,
              validator: (value) async {
                if (value is int) {
                  return value >= 18;
                }
                return false;
              },
            ),
          ],
        );

        validationManager.registerSchema(schema);

        final validResult = await validationManager.validate('users', {
          'age': 25,
        });

        expect(validResult.isValid, isTrue);

        final invalidResult = await validationManager.validate('users', {
          'age': 15,
        });

        expect(invalidResult.isValid, isFalse);
        expect(invalidResult.errors.first.type, equals(ValidationType.custom));
      });
    });

    group('Batch Validation', () {
      test('should validate multiple records', () async {
        final schema = TableSchema(
          name: 'users',
          fields: [
            FieldSchema.text(name: 'username', nullable: false),
            FieldSchema.integer(name: 'age'),
          ],
        );

        validationManager.registerSchema(schema);

        final dataList = [
          {'username': 'john', 'age': 25},
          {'username': 'jane', 'age': 30},
          {'age': 20}, // Missing username
        ];

        final results =
            await validationManager.validateBatch('users', dataList);

        expect(results.length, equals(3));
        expect(results[0].isValid, isTrue);
        expect(results[1].isValid, isTrue);
        expect(results[2].isValid, isFalse);
      });
    });

    group('Multiple Errors', () {
      test('should report multiple validation errors', () async {
        final schema = TableSchema(
          name: 'users',
          fields: [
            FieldSchema.text(
              name: 'username',
              nullable: false,
              minLength: 3,
              maxLength: 10,
            ),
            FieldSchema.integer(name: 'age', nullable: false),
          ],
        );

        validationManager.registerSchema(schema);

        final result = await validationManager.validate('users', {
          'username': 'ab', // Too short
          // Missing age
        });

        expect(result.isValid, isFalse);
        expect(result.errors.length, equals(2));
      });
    });

    group('Error Handling', () {
      test('should handle missing schema', () async {
        final result = await validationManager.validate('nonexistent', {
          'field': 'value',
        });

        expect(result.isValid, isFalse);
        expect(result.errors.first.type, equals(ValidationType.custom));
      });
    });
  });
}
