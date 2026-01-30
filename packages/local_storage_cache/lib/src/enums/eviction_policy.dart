/// Cache eviction policies.
enum EvictionPolicy {
  /// Least Recently Used - Evicts the least recently accessed items first
  lru,

  /// Least Frequently Used - Evicts the least frequently accessed items first
  lfu,

  /// First In First Out - Evicts the oldest items first
  fifo,
}
