/// Cache storage levels.
enum CacheLevel {
  /// Memory cache (fastest, volatile)
  memory,

  /// Disk cache (persistent, slower than memory)
  disk,

  /// Both memory and disk cache
  both,
}
