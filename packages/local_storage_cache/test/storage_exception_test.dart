import 'package:flutter_test/flutter_test.dart';
import 'package:local_storage_cache/src/enums/error_code.dart';
import 'package:local_storage_cache/src/exceptions/storage_exception.dart';

void main() {
  group('StorageException', () {
    test('DatabaseException includes message and code', () {
      final exception = DatabaseException(
        'Database connection failed',
        code: ErrorCode.connectionFailed.code,
      );

      expect(exception.message, equals('Database connection failed'));
      expect(exception.code, equals(ErrorCode.connectionFailed.code));
      expect(
        exception.toString(),
        contains('DatabaseException: Database connection failed'),
      );
      expect(exception.toString(), contains('CONNECTION_FAILED'));
    });

    test('DatabaseException with details', () {
      final exception = DatabaseException(
        'Query failed',
        code: ErrorCode.queryFailed.code,
        details: {'sql': 'SELECT * FROM users', 'error': 'Syntax error'},
      );

      expect(exception.details, isA<Map<dynamic, dynamic>>());
      expect(exception.details['sql'], equals('SELECT * FROM users'));
    });

    test('EncryptionException includes message and code', () {
      final exception = EncryptionException(
        'Encryption key is invalid',
        code: ErrorCode.invalidEncryptionKey.code,
      );

      expect(exception.message, equals('Encryption key is invalid'));
      expect(exception.code, equals(ErrorCode.invalidEncryptionKey.code));
      expect(
        exception.toString(),
        contains('EncryptionException: Encryption key is invalid'),
      );
    });

    test('ValidationException includes errors list', () {
      final errors = [
        {'field': 'username', 'message': 'Required field missing'},
        {'field': 'email', 'message': 'Invalid email format'},
      ];

      final exception = ValidationException(
        'Validation failed',
        errors,
        code: ErrorCode.validationFailed.code,
      );

      expect(exception.message, equals('Validation failed'));
      expect(exception.errors, equals(errors));
      expect(exception.errors.length, equals(2));
      expect(exception.toString(), contains('2 errors'));
    });

    test('MigrationException includes message and code', () {
      final exception = MigrationException(
        'Migration failed',
        code: ErrorCode.migrationFailed.code,
        details: {'version': 2, 'error': 'Column already exists'},
      );

      expect(exception.message, equals('Migration failed'));
      expect(exception.code, equals(ErrorCode.migrationFailed.code));
      expect(exception.details['version'], equals(2));
    });

    test('SpaceException includes message and code', () {
      final exception = SpaceException(
        'Space not found',
        code: ErrorCode.spaceNotFound.code,
        details: {'spaceName': 'user_123'},
      );

      expect(exception.message, equals('Space not found'));
      expect(exception.code, equals(ErrorCode.spaceNotFound.code));
      expect(exception.details['spaceName'], equals('user_123'));
    });

    test('QueryException includes message and code', () {
      final exception = QueryException(
        'Invalid query syntax',
        code: ErrorCode.invalidQuerySyntax.code,
        details: {'sql': 'SELCT * FROM users'},
      );

      expect(exception.message, equals('Invalid query syntax'));
      expect(exception.code, equals(ErrorCode.invalidQuerySyntax.code));
    });

    test('exception without code', () {
      final exception = DatabaseException('Simple error');

      expect(exception.code, isNull);
      expect(exception.toString(), equals('DatabaseException: Simple error'));
    });

    test('exception without details', () {
      final exception = DatabaseException(
        'Error message',
        code: ErrorCode.queryFailed.code,
      );

      expect(exception.details, isNull);
    });
  });

  group('ErrorCode', () {
    test('has correct string representation', () {
      expect(ErrorCode.databaseLocked.code, equals('DB_LOCKED'));
      expect(ErrorCode.databaseLocked.toString(), equals('DB_LOCKED'));
    });

    test('has correct numeric code', () {
      expect(ErrorCode.databaseLocked.numericCode, equals(1002));
      expect(ErrorCode.encryptionFailed.numericCode, equals(2002));
      expect(ErrorCode.validationFailed.numericCode, equals(3001));
    });

    test('database error codes are in 1xxx range', () {
      expect(
          ErrorCode.databaseInitFailed.numericCode, greaterThanOrEqualTo(1000));
      expect(ErrorCode.databaseInitFailed.numericCode, lessThan(2000));
      expect(
          ErrorCode.connectionFailed.numericCode, greaterThanOrEqualTo(1000));
      expect(ErrorCode.connectionFailed.numericCode, lessThan(2000));
    });

    test('encryption error codes are in 2xxx range', () {
      expect(ErrorCode.invalidEncryptionKey.numericCode,
          greaterThanOrEqualTo(2000));
      expect(ErrorCode.invalidEncryptionKey.numericCode, lessThan(3000));
      expect(
          ErrorCode.decryptionFailed.numericCode, greaterThanOrEqualTo(2000));
      expect(ErrorCode.decryptionFailed.numericCode, lessThan(3000));
    });

    test('validation error codes are in 3xxx range', () {
      expect(
          ErrorCode.validationFailed.numericCode, greaterThanOrEqualTo(3000));
      expect(ErrorCode.validationFailed.numericCode, lessThan(4000));
      expect(ErrorCode.uniqueConstraintViolated.numericCode,
          greaterThanOrEqualTo(3000));
      expect(ErrorCode.uniqueConstraintViolated.numericCode, lessThan(4000));
    });

    test('migration error codes are in 4xxx range', () {
      expect(ErrorCode.migrationFailed.numericCode, greaterThanOrEqualTo(4000));
      expect(ErrorCode.migrationFailed.numericCode, lessThan(5000));
    });

    test('space error codes are in 5xxx range', () {
      expect(ErrorCode.spaceNotFound.numericCode, greaterThanOrEqualTo(5000));
      expect(ErrorCode.spaceNotFound.numericCode, lessThan(6000));
    });

    test('storage error codes are in 6xxx range', () {
      expect(ErrorCode.diskFull.numericCode, greaterThanOrEqualTo(6000));
      expect(ErrorCode.diskFull.numericCode, lessThan(7000));
      expect(
          ErrorCode.permissionDenied.numericCode, greaterThanOrEqualTo(6000));
      expect(ErrorCode.permissionDenied.numericCode, lessThan(7000));
    });

    test('cache error codes are in 7xxx range', () {
      expect(ErrorCode.cacheOperationFailed.numericCode,
          greaterThanOrEqualTo(7000));
      expect(ErrorCode.cacheOperationFailed.numericCode, lessThan(8000));
    });

    test('query error codes are in 8xxx range', () {
      expect(
          ErrorCode.invalidQuerySyntax.numericCode, greaterThanOrEqualTo(8000));
      expect(ErrorCode.invalidQuerySyntax.numericCode, lessThan(9000));
    });
  });
}
