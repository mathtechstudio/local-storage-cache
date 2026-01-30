/// Status of a schema migration.
enum MigrationState {
  /// Migration is pending and has not started.
  pending,

  /// Migration is currently in progress.
  inProgress,

  /// Migration has completed successfully.
  completed,

  /// Migration has failed.
  failed,
}

/// Status information for a migration task.
class MigrationStatus {
  /// Creates migration status with the specified details.
  const MigrationStatus({
    required this.taskId,
    required this.tableName,
    required this.state,
    required this.progressPercentage,
    this.startedAt,
    this.completedAt,
    this.errorMessage,
  });

  /// Unique migration task ID.
  final String taskId;

  /// Table name being migrated.
  final String tableName;

  /// Current migration state.
  final MigrationState state;

  /// Progress percentage (0.0 to 100.0).
  final double progressPercentage;

  /// When the migration started.
  final DateTime? startedAt;

  /// When the migration completed.
  final DateTime? completedAt;

  /// Error message if migration failed.
  final String? errorMessage;

  /// Whether the migration is complete.
  bool get isComplete => state == MigrationState.completed;

  /// Whether the migration failed.
  bool get isFailed => state == MigrationState.failed;

  /// Duration of the migration.
  Duration? get duration {
    if (startedAt == null) return null;
    final endTime = completedAt ?? DateTime.now();
    return endTime.difference(startedAt!);
  }

  /// Converts the status to a map representation.
  Map<String, dynamic> toMap() {
    return {
      'taskId': taskId,
      'tableName': tableName,
      'state': state.name,
      'progressPercentage': progressPercentage,
      'startedAt': startedAt?.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'errorMessage': errorMessage,
    };
  }
}
