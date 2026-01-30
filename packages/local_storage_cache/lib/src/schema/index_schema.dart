/// Index types.
enum IndexType {
  /// Standard B-tree index.
  standard,

  /// Vector index for similarity search.
  vector,
}

/// Configuration for vector indexes.
class VectorIndexConfig {
  /// Creates a vector index configuration with the specified settings.
  const VectorIndexConfig({
    required this.indexType,
    required this.distanceMetric,
    this.parameters = const {},
  });

  /// Type of vector index algorithm.
  final VectorIndexType indexType;

  /// Distance metric for similarity calculations.
  final VectorDistanceMetric distanceMetric;

  /// Additional algorithm-specific parameters.
  final Map<String, dynamic> parameters;
}

/// Vector index algorithm types.
enum VectorIndexType {
  /// Hierarchical Navigable Small World graph index.
  hnsw,

  /// Inverted File with Flat compression index.
  ivfFlat,
}

/// Distance metrics for vector similarity.
enum VectorDistanceMetric {
  /// Cosine similarity distance.
  cosine,

  /// Euclidean (L2) distance.
  euclidean,

  /// Dot product distance.
  dotProduct,
}

/// Schema definition for an index.
class IndexSchema {
  /// Creates an index schema with the specified configuration.
  const IndexSchema({
    required this.fields,
    this.type = IndexType.standard,
    this.unique = false,
    this.name,
    this.vectorConfig,
  });

  /// Type of index.
  final IndexType type;

  /// Fields included in the index.
  final List<String> fields;

  /// Whether the index enforces uniqueness.
  final bool unique;

  /// Optional custom name for the index.
  final String? name;

  /// Vector index configuration (for vector type).
  final VectorIndexConfig? vectorConfig;

  /// Converts the index schema to a map representation.
  Map<String, dynamic> toMap() {
    return {
      'type': type.name,
      'fields': fields,
      'unique': unique,
      if (name != null) 'name': name,
    };
  }
}
