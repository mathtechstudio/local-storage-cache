/// Represents a cached entry with metadata.
class CacheEntry<T> {
  /// Creates a cache entry.
  CacheEntry({
    required this.key,
    required this.value,
    required this.createdAt,
    this.ttl,
    this.accessCount = 0,
    DateTime? lastAccessedAt,
  }) : lastAccessedAt = lastAccessedAt ?? createdAt;

  /// Creates a cache entry from a map.
  factory CacheEntry.fromMap(Map<String, dynamic> map) {
    return CacheEntry<T>(
      key: map['key'] as String,
      value: map['value'] as T,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
      ttl:
          map['ttl'] != null ? Duration(milliseconds: map['ttl'] as int) : null,
      accessCount: map['accessCount'] as int? ?? 0,
      lastAccessedAt: map['lastAccessedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['lastAccessedAt'] as int)
          : null,
    );
  }

  /// Cache key.
  final String key;

  /// Cached value.
  final T value;

  /// When the entry was created.
  final DateTime createdAt;

  /// Time to live duration.
  final Duration? ttl;

  /// Number of times this entry has been accessed.
  int accessCount;

  /// When the entry was last accessed.
  DateTime lastAccessedAt;

  /// Expiration time (null if no TTL).
  DateTime? get expiresAt {
    if (ttl == null) return null;
    return createdAt.add(ttl!);
  }

  /// Whether this entry has expired.
  bool get isExpired {
    final expiration = expiresAt;
    if (expiration == null) return false;
    return DateTime.now().isAfter(expiration);
  }

  /// Time remaining until expiration (null if no TTL or already expired).
  Duration? get timeRemaining {
    final expiration = expiresAt;
    if (expiration == null) return null;
    final now = DateTime.now();
    if (now.isAfter(expiration)) return Duration.zero;
    return expiration.difference(now);
  }

  /// Updates the last accessed time and increments access count.
  void markAccessed() {
    lastAccessedAt = DateTime.now();
    accessCount++;
  }

  /// Converts the entry to a map representation.
  Map<String, dynamic> toMap() {
    return {
      'key': key,
      'value': value,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'ttl': ttl?.inMilliseconds,
      'accessCount': accessCount,
      'lastAccessedAt': lastAccessedAt.millisecondsSinceEpoch,
      'expiresAt': expiresAt?.millisecondsSinceEpoch,
      'isExpired': isExpired,
    };
  }
}
