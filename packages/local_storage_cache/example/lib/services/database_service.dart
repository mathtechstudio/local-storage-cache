import 'package:local_storage_cache/local_storage_cache.dart';

/// Database service singleton for managing storage engine.
class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();

  /// Factory constructor returns singleton instance.
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  StorageEngine? _storage;

  /// Gets the storage engine instance.
  Future<StorageEngine> get storage async {
    if (_storage == null) {
      _storage = StorageEngine(
        config: StorageConfig(
          databaseName: 'example_app.db',
          logging: LogConfig(
            level: LogLevel.debug,
            logQueries: true,
          ),
        ),
        schemas: [_userSchema, _productSchema, _orderSchema],
      );
      await _storage!.initialize();
    }
    return _storage!;
  }

  static final _userSchema = TableSchema(
    name: 'users',
    fields: [
      FieldSchema(
        name: 'id',
        type: DataType.integer,
        nullable: false,
      ),
      FieldSchema(
        name: 'username',
        type: DataType.text,
        nullable: false,
        unique: true,
      ),
      FieldSchema(
        name: 'email',
        type: DataType.text,
        nullable: false,
      ),
      FieldSchema(
        name: 'age',
        type: DataType.integer,
        nullable: true,
      ),
      FieldSchema(
        name: 'created_at',
        type: DataType.datetime,
        nullable: false,
      ),
    ],
    primaryKeyConfig: PrimaryKeyConfig(
      name: 'id',
      type: PrimaryKeyType.autoIncrement,
    ),
    indexes: [
      IndexSchema(name: 'idx_username', fields: ['username']),
      IndexSchema(name: 'idx_email', fields: ['email']),
    ],
  );

  static final _productSchema = TableSchema(
    name: 'products',
    fields: [
      FieldSchema(
        name: 'id',
        type: DataType.integer,
        nullable: false,
      ),
      FieldSchema(
        name: 'name',
        type: DataType.text,
        nullable: false,
      ),
      FieldSchema(
        name: 'price',
        type: DataType.real,
        nullable: false,
      ),
      FieldSchema(
        name: 'stock',
        type: DataType.integer,
        defaultValue: 0,
      ),
      FieldSchema(
        name: 'category',
        type: DataType.text,
        nullable: false,
      ),
    ],
    primaryKeyConfig: PrimaryKeyConfig(
      name: 'id',
      type: PrimaryKeyType.autoIncrement,
    ),
    indexes: [
      IndexSchema(name: 'idx_category', fields: ['category']),
      IndexSchema(name: 'idx_price', fields: ['price']),
    ],
  );

  static final _orderSchema = TableSchema(
    name: 'orders',
    fields: [
      FieldSchema(
        name: 'id',
        type: DataType.integer,
        nullable: false,
      ),
      FieldSchema(
        name: 'user_id',
        type: DataType.integer,
        nullable: false,
      ),
      FieldSchema(
        name: 'product_id',
        type: DataType.integer,
        nullable: false,
      ),
      FieldSchema(
        name: 'quantity',
        type: DataType.integer,
        nullable: false,
      ),
      FieldSchema(
        name: 'total',
        type: DataType.real,
        nullable: false,
      ),
      FieldSchema(
        name: 'status',
        type: DataType.text,
        nullable: false,
      ),
      FieldSchema(
        name: 'created_at',
        type: DataType.datetime,
        nullable: false,
      ),
    ],
    primaryKeyConfig: PrimaryKeyConfig(
      name: 'id',
      type: PrimaryKeyType.autoIncrement,
    ),
  );

  /// Closes the storage engine.
  Future<void> close() async {
    await _storage?.close();
    _storage = null;
  }
}
