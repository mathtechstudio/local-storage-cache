import 'dart:convert';
import 'dart:io';

import 'package:local_storage_cache/src/enums/eviction_policy.dart';
import 'package:local_storage_cache/src/models/cache_entry.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

// ignore_for_file: avoid_slow_async_io

/// Disk-based persistent cache.
class DiskCache {
  /// Creates a disk cache.
  DiskCache({
    required this.maxSize,
    this.cacheDirectory = 'cache',
    this.evictionPolicy = EvictionPolicy.lru,
  });

  /// Maximum number of entries.
  final int maxSize;

  /// Cache directory name.
  final String cacheDirectory;

  /// Eviction policy.
  final EvictionPolicy evictionPolicy;

  /// Cache directory path.
  late final Directory _cacheDir;

  /// Whether the cache is initialized.
  bool _initialized = false;

  /// Initializes the disk cache.
  Future<void> initialize() async {
    if (_initialized) return;

    final appDir = await getApplicationDocumentsDirectory();
    _cacheDir = Directory(path.join(appDir.path, cacheDirectory));

    if (!_cacheDir.existsSync()) {
      _cacheDir.createSync(recursive: true);
    }

    _initialized = true;
  }

  /// Gets a value from disk cache.
  Future<T?> get<T>(String key) async {
    _ensureInitialized();

    final file = _getFile(key);
    if (!await file.exists()) return null;

    try {
      final content = await file.readAsString();
      final map = jsonDecode(content) as Map<String, dynamic>;
      final entry = CacheEntry<T>.fromMap(map);

      // Check expiration
      if (entry.isExpired) {
        await remove(key);
        return null;
      }

      // Update access metadata
      entry.markAccessed();

      // Save updated metadata
      await _saveEntry(entry);

      return entry.value;
    } catch (e) {
      // If file is corrupted, remove it
      await remove(key);
      return null;
    }
  }

  /// Puts a value into disk cache.
  Future<void> put(String key, dynamic value, {Duration? ttl}) async {
    _ensureInitialized();

    // Enforce max size
    final currentSize = await size;
    if (currentSize >= maxSize) {
      await _evictOldest();
    }

    final entry = CacheEntry<dynamic>(
      key: key,
      value: value,
      createdAt: DateTime.now(),
      ttl: ttl,
    );

    await _saveEntry(entry);
  }

  /// Removes a value from disk cache.
  Future<bool> remove(String key) async {
    _ensureInitialized();

    final file = _getFile(key);
    if (await file.exists()) {
      await file.delete();
      return true;
    }
    return false;
  }

  /// Clears all entries.
  Future<void> clear() async {
    _ensureInitialized();

    if (await _cacheDir.exists()) {
      await for (final entity in _cacheDir.list()) {
        if (entity is File) {
          await entity.delete();
        }
      }
    }
  }

  /// Checks if a key exists.
  Future<bool> containsKey(String key) async {
    _ensureInitialized();

    final file = _getFile(key);
    if (!await file.exists()) return false;

    // Check if expired
    try {
      final content = await file.readAsString();
      final map = jsonDecode(content) as Map<String, dynamic>;
      final entry = CacheEntry<dynamic>.fromMap(map);

      if (entry.isExpired) {
        await remove(key);
        return false;
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Gets all keys.
  Future<List<String>> get keys async {
    _ensureInitialized();

    final keys = <String>[];

    if (await _cacheDir.exists()) {
      await for (final entity in _cacheDir.list()) {
        if (entity is File) {
          final filename = path.basename(entity.path);
          if (filename.endsWith('.cache')) {
            keys.add(filename.replaceAll('.cache', ''));
          }
        }
      }
    }

    return keys;
  }

  /// Gets current size.
  Future<int> get size async {
    _ensureInitialized();

    var count = 0;

    if (await _cacheDir.exists()) {
      await for (final entity in _cacheDir.list()) {
        if (entity is File && entity.path.endsWith('.cache')) {
          count++;
        }
      }
    }

    return count;
  }

  /// Removes expired entries.
  Future<int> clearExpired() async {
    _ensureInitialized();

    var removed = 0;

    if (await _cacheDir.exists()) {
      await for (final entity in _cacheDir.list()) {
        if (entity is File && entity.path.endsWith('.cache')) {
          try {
            final content = await entity.readAsString();
            final map = jsonDecode(content) as Map<String, dynamic>;
            final entry = CacheEntry<dynamic>.fromMap(map);

            if (entry.isExpired) {
              await entity.delete();
              removed++;
            }
          } catch (e) {
            // If file is corrupted, remove it
            await entity.delete();
            removed++;
          }
        }
      }
    }

    return removed;
  }

  /// Gets all entries.
  Future<List<CacheEntry<dynamic>>> get entries async {
    _ensureInitialized();

    final entries = <CacheEntry<dynamic>>[];

    if (await _cacheDir.exists()) {
      await for (final entity in _cacheDir.list()) {
        if (entity is File && entity.path.endsWith('.cache')) {
          try {
            final content = await entity.readAsString();
            final map = jsonDecode(content) as Map<String, dynamic>;
            final entry = CacheEntry<dynamic>.fromMap(map);

            if (!entry.isExpired) {
              entries.add(entry);
            }
          } catch (e) {
            // Skip corrupted files
          }
        }
      }
    }

    return entries;
  }

  /// Gets the file for a cache key.
  File _getFile(String key) {
    final sanitizedKey = _sanitizeKey(key);
    return File(path.join(_cacheDir.path, '$sanitizedKey.cache'));
  }

  /// Sanitizes a cache key for use as a filename.
  String _sanitizeKey(String key) {
    return key.replaceAll(RegExp(r'[^\w\-]'), '_');
  }

  /// Saves a cache entry to disk.
  Future<void> _saveEntry(CacheEntry<dynamic> entry) async {
    final file = _getFile(entry.key);
    final json = jsonEncode(entry.toMap());
    await file.writeAsString(json);
  }

  /// Evicts an entry based on the eviction policy.
  Future<void> _evictOldest() async {
    final allEntries = await entries;

    if (allEntries.isEmpty) return;

    CacheEntry<dynamic>? entryToEvict;

    switch (evictionPolicy) {
      case EvictionPolicy.lru:
        // Evict least recently used
        allEntries.sort((a, b) => a.lastAccessedAt.compareTo(b.lastAccessedAt));
        entryToEvict = allEntries.first;

      case EvictionPolicy.lfu:
        // Evict least frequently used
        allEntries.sort((a, b) => a.accessCount.compareTo(b.accessCount));
        entryToEvict = allEntries.first;

      case EvictionPolicy.fifo:
        // Evict first in (oldest by creation time)
        allEntries.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        entryToEvict = allEntries.first;
    }

    await remove(entryToEvict.key);
  }

  /// Ensures the cache is initialized.
  void _ensureInitialized() {
    if (!_initialized) {
      throw StateError('DiskCache not initialized. Call initialize() first.');
    }
  }
}
