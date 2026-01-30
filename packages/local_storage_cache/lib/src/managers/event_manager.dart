// Copyright (c) 2024-2026 local_storage_cache authors
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:local_storage_cache/src/models/storage_event.dart';

/// Manages storage events and event subscriptions.
///
/// The EventManager provides a centralized event system for monitoring
/// storage operations, data changes, cache events, and errors.
///
/// Example:
/// ```dart
/// final eventManager = EventManager();
///
/// // Listen to all events
/// eventManager.events.listen((event) {
///   print('Event: ${event.type}');
/// });
///
/// // Listen to specific event types
/// eventManager.eventsOfType(StorageEventType.dataInserted).listen((event) {
///   print('Data inserted: ${event.tableName}');
/// });
/// ```
class EventManager {
  final StreamController<StorageEvent> _eventController =
      StreamController<StorageEvent>.broadcast();

  /// Stream of all storage events.
  Stream<StorageEvent> get events => _eventController.stream;

  /// Emits an event.
  void emit(StorageEvent event) {
    if (!_eventController.isClosed) {
      _eventController.add(event);
    }
  }

  /// Gets a stream of events filtered by type.
  Stream<StorageEvent> eventsOfType(StorageEventType type) {
    return events.where((event) => event.type == type);
  }

  /// Gets a stream of data change events.
  Stream<DataChangeEvent> get dataChangeEvents {
    return events
        .where((event) => event is DataChangeEvent)
        .cast<DataChangeEvent>();
  }

  /// Gets a stream of cache events.
  Stream<CacheEvent> get cacheEvents {
    return events.where((event) => event is CacheEvent).cast<CacheEvent>();
  }

  /// Gets a stream of query events.
  Stream<QueryEvent> get queryEvents {
    return events.where((event) => event is QueryEvent).cast<QueryEvent>();
  }

  /// Gets a stream of error events.
  Stream<ErrorEvent> get errorEvents {
    return events.where((event) => event is ErrorEvent).cast<ErrorEvent>();
  }

  /// Gets a stream of backup/restore events.
  Stream<BackupRestoreEvent> get backupRestoreEvents {
    return events
        .where((event) => event is BackupRestoreEvent)
        .cast<BackupRestoreEvent>();
  }

  /// Disposes the event manager.
  void dispose() {
    _eventController.close();
  }
}
