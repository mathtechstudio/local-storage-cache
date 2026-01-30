/// Represents a single operation in a batch execution.
class BatchOperation {
  /// Creates a batch operation.
  const BatchOperation({
    required this.type,
    required this.tableName,
    this.sql,
    this.data,
    this.arguments,
  });

  /// Creates an insert batch operation.
  factory BatchOperation.insert(
    String tableName,
    Map<String, dynamic> data,
  ) {
    return BatchOperation(
      type: 'insert',
      tableName: tableName,
      data: data,
    );
  }

  /// Creates an update batch operation.
  factory BatchOperation.update(
    String tableName,
    String sql,
    List<dynamic> arguments,
  ) {
    return BatchOperation(
      type: 'update',
      tableName: tableName,
      sql: sql,
      arguments: arguments,
    );
  }

  /// Creates a delete batch operation.
  factory BatchOperation.delete(
    String tableName,
    String sql,
    List<dynamic> arguments,
  ) {
    return BatchOperation(
      type: 'delete',
      tableName: tableName,
      sql: sql,
      arguments: arguments,
    );
  }

  /// Creates a batch operation from a map.
  factory BatchOperation.fromMap(Map<String, dynamic> map) {
    return BatchOperation(
      type: map['type'] as String,
      tableName: map['tableName'] as String,
      sql: map['sql'] as String?,
      data: map['data'] as Map<String, dynamic>?,
      arguments: map['arguments'] as List<dynamic>?,
    );
  }

  /// The type of operation (insert, update, delete).
  final String type;

  /// The table name for the operation.
  final String tableName;

  /// The SQL query for the operation (for update/delete).
  final String? sql;

  /// The data for the operation (for insert/update).
  final Map<String, dynamic>? data;

  /// The arguments for the SQL query.
  final List<dynamic>? arguments;

  /// Converts this operation to a map for platform communication.
  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'tableName': tableName,
      if (sql != null) 'sql': sql,
      if (data != null) 'data': data,
      if (arguments != null) 'arguments': arguments,
    };
  }
}
