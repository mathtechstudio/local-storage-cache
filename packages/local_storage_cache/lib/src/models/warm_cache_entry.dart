/// Entry for cache warming configuration.
class WarmCacheEntry {
  /// Creates a warm cache entry.
  const WarmCacheEntry({
    required this.key,
    required this.loader,
    this.ttl,
  });

  /// Cache key.
  final String key;

  /// Function to load the value.
  final Future<dynamic> Function() loader;

  /// Time to live for this entry.
  final Duration? ttl;
}
