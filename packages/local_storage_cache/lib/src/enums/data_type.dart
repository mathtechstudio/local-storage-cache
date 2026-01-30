/// Supported data types for table fields.
enum DataType {
  /// Text/String data type
  text,

  /// Integer data type
  integer,

  /// Real/Double data type
  real,

  /// Boolean data type
  boolean,

  /// DateTime data type
  datetime,

  /// Binary large object (BLOB) data type
  blob,

  /// JSON data type (stored as text)
  json,

  /// Vector data type for AI/ML applications (stored as blob)
  vector,
}

/// Extension methods for [DataType].
extension DataTypeExtension on DataType {
  /// Converts the data type to SQL type string.
  String toSqlType() {
    switch (this) {
      case DataType.text:
      case DataType.json:
        return 'TEXT';
      case DataType.integer:
      case DataType.boolean:
      case DataType.datetime:
        return 'INTEGER';
      case DataType.real:
        return 'REAL';
      case DataType.blob:
      case DataType.vector:
        return 'BLOB';
    }
  }

  /// Checks if the data type is numeric.
  bool get isNumeric {
    return this == DataType.integer || this == DataType.real;
  }

  /// Checks if the data type is textual.
  bool get isTextual {
    return this == DataType.text || this == DataType.json;
  }
}
