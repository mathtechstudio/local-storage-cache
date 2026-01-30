/// Event emitted when a cache entry expires.
class CacheExpirationEvent {
  /// Creates a cache expiration event.
  const CacheExpirationEvent({
    required this.key,
    required this.expiredAt,
  });

  /// The key of the expired entry.
  final String key;

  /// When the entry expired.
  final DateTime expiredAt;

  @override
  String toString() => 'CacheExpirationEvent(key: $key, expiredAt: $expiredAt)';
}
