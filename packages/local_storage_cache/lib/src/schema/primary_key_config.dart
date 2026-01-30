/// Primary key types.
enum PrimaryKeyType {
  /// Auto-incrementing integer primary key.
  autoIncrement,

  /// Sequential ID with configurable step.
  sequential,

  /// Timestamp-based ID.
  timestampBased,

  /// Date-prefixed ID (e.g., 20250130123456789).
  datePrefixed,

  /// Short code ID (e.g., 9eXrF0qeXZ).
  shortCode,

  /// UUID v4.
  uuid,
}

/// Configuration for sequential ID generation.
class SequentialIdConfig {
  /// Creates a sequential ID configuration with the specified settings.
  const SequentialIdConfig({
    this.initialValue = 1,
    this.increment = 1,
    this.useRandomIncrement = false,
  });

  /// Initial value for the sequence.
  final int initialValue;

  /// Increment step.
  final int increment;

  /// Whether to use random increment to hide business scale.
  final bool useRandomIncrement;
}

/// Configuration for primary keys.
class PrimaryKeyConfig {
  /// Creates a primary key configuration with the specified settings.
  const PrimaryKeyConfig({
    this.name = 'id',
    this.type = PrimaryKeyType.autoIncrement,
    this.sequentialConfig,
  });

  /// Creates a configuration for auto-increment primary key.
  factory PrimaryKeyConfig.autoIncrement({String name = 'id'}) {
    return PrimaryKeyConfig(name: name);
  }

  /// Creates a configuration for UUID primary key.
  factory PrimaryKeyConfig.uuid({String name = 'id'}) {
    return PrimaryKeyConfig(name: name, type: PrimaryKeyType.uuid);
  }

  /// Creates a configuration for timestamp-based primary key.
  factory PrimaryKeyConfig.timestampBased({String name = 'id'}) {
    return PrimaryKeyConfig(name: name, type: PrimaryKeyType.timestampBased);
  }

  /// Name of the primary key field.
  final String name;

  /// Type of primary key.
  final PrimaryKeyType type;

  /// Configuration for sequential IDs.
  final SequentialIdConfig? sequentialConfig;

  /// Converts the primary key configuration to a map representation.
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'type': type.name,
      if (sequentialConfig != null)
        'sequentialConfig': {
          'initialValue': sequentialConfig!.initialValue,
          'increment': sequentialConfig!.increment,
          'useRandomIncrement': sequentialConfig!.useRandomIncrement,
        },
    };
  }
}
