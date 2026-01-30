import 'package:flutter_test/flutter_test.dart';
import 'package:local_storage_cache/src/managers/event_manager.dart';
import 'package:local_storage_cache/src/models/storage_event.dart';

void main() {
  group('EventManager', () {
    late EventManager eventManager;

    setUp(() {
      eventManager = EventManager();
    });

    tearDown(() {
      eventManager.dispose();
    });

    test('emits events to all listeners', () async {
      final receivedEvents = <StorageEvent>[];

      eventManager.events.listen((event) {
        receivedEvents.add(event);
      });

      final event = DataChangeEvent(
        type: StorageEventType.dataInserted,
        timestamp: DateTime.now(),
        tableName: 'users',
        space: 'default',
        recordId: 1,
      );

      eventManager.emit(event);

      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(receivedEvents.length, equals(1));
      expect(receivedEvents.first, equals(event));
    });

    test('filters events by type', () async {
      final insertEvents = <StorageEvent>[];

      eventManager.eventsOfType(StorageEventType.dataInserted).listen((event) {
        insertEvents.add(event);
      });

      // Emit insert event
      eventManager.emit(
        DataChangeEvent(
          type: StorageEventType.dataInserted,
          timestamp: DateTime.now(),
          tableName: 'users',
          space: 'default',
          recordId: 1,
        ),
      );

      // Emit update event (should not be captured)
      eventManager.emit(
        DataChangeEvent(
          type: StorageEventType.dataUpdated,
          timestamp: DateTime.now(),
          tableName: 'users',
          space: 'default',
        ),
      );

      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(insertEvents.length, equals(1));
      expect(insertEvents.first.type, equals(StorageEventType.dataInserted));
    });

    test('provides filtered stream for data change events', () async {
      final dataChangeEvents = <DataChangeEvent>[];

      eventManager.dataChangeEvents.listen((event) {
        dataChangeEvents.add(event);
      });

      // Emit data change event
      eventManager.emit(
        DataChangeEvent(
          type: StorageEventType.dataInserted,
          timestamp: DateTime.now(),
          tableName: 'users',
          space: 'default',
          recordId: 1,
        ),
      );

      // Emit query event (should not be captured)
      eventManager.emit(
        QueryEvent(
          timestamp: DateTime.now(),
          sql: 'SELECT * FROM users',
          executionTimeMs: 10,
        ),
      );

      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(dataChangeEvents.length, equals(1));
      expect(dataChangeEvents.first, isA<DataChangeEvent>());
    });

    test('provides filtered stream for cache events', () async {
      final cacheEvents = <CacheEvent>[];

      eventManager.cacheEvents.listen((event) {
        cacheEvents.add(event);
      });

      eventManager.emit(
        CacheEvent(
          type: StorageEventType.cacheExpired,
          timestamp: DateTime.now(),
          key: 'user_123',
          reason: 'TTL expired',
        ),
      );

      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(cacheEvents.length, equals(1));
      expect(cacheEvents.first, isA<CacheEvent>());
    });

    test('provides filtered stream for query events', () async {
      final queryEvents = <QueryEvent>[];

      eventManager.queryEvents.listen((event) {
        queryEvents.add(event);
      });

      eventManager.emit(
        QueryEvent(
          timestamp: DateTime.now(),
          sql: 'SELECT * FROM users',
          executionTimeMs: 25,
          resultCount: 10,
        ),
      );

      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(queryEvents.length, equals(1));
      expect(queryEvents.first, isA<QueryEvent>());
      expect(queryEvents.first.executionTimeMs, equals(25));
    });

    test('provides filtered stream for error events', () async {
      final errorEvents = <ErrorEvent>[];

      eventManager.errorEvents.listen((event) {
        errorEvents.add(event);
      });

      eventManager.emit(
        ErrorEvent(
          timestamp: DateTime.now(),
          error: Exception('Test error'),
          stackTrace: StackTrace.current,
        ),
      );

      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(errorEvents.length, equals(1));
      expect(errorEvents.first, isA<ErrorEvent>());
    });

    test('provides filtered stream for backup/restore events', () async {
      final backupEvents = <BackupRestoreEvent>[];

      eventManager.backupRestoreEvents.listen((event) {
        backupEvents.add(event);
      });

      eventManager.emit(
        BackupRestoreEvent(
          type: StorageEventType.backupCompleted,
          timestamp: DateTime.now(),
          filePath: '/path/to/backup.json',
          success: true,
        ),
      );

      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(backupEvents.length, equals(1));
      expect(backupEvents.first, isA<BackupRestoreEvent>());
    });

    test('handles multiple listeners', () async {
      final listener1Events = <StorageEvent>[];
      final listener2Events = <StorageEvent>[];

      eventManager.events.listen((event) {
        listener1Events.add(event);
      });

      eventManager.events.listen((event) {
        listener2Events.add(event);
      });

      final event = DataChangeEvent(
        type: StorageEventType.dataInserted,
        timestamp: DateTime.now(),
        tableName: 'users',
        space: 'default',
        recordId: 1,
      );

      eventManager.emit(event);

      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(listener1Events.length, equals(1));
      expect(listener2Events.length, equals(1));
    });

    test('does not emit after dispose', () {
      eventManager.dispose();

      expect(
        () => eventManager.emit(
          DataChangeEvent(
            type: StorageEventType.dataInserted,
            timestamp: DateTime.now(),
            tableName: 'users',
            space: 'default',
            recordId: 1,
          ),
        ),
        returnsNormally,
      );
    });
  });
}
