import 'package:local_storage_cache_platform_interface/src/method_channel_local_storage_cache.dart';
import 'package:local_storage_cache_platform_interface/src/models/batch_operation.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

/// The interface that platform-specific implementations of local_storage_cache must extend.
///
/// Platform implementations should extend this class rather than implement it,
/// as `implements` does not consider newly added methods to be breaking changes.
abstract class LocalStorageCachePlatform extends PlatformInterface {
  /// Constructs a LocalStorageCachePlatform.
  LocalStorageCachePlatform() : super(token: _token);

  static final Object _token = Object();

  static LocalStorageCachePlatform _instance = MethodChannelLocalStorageCache();

  /// The default instance of [LocalStorageCachePlatform] to use.
  ///
  /// Defaults to [MethodChannelLocalStorageCache].
  static LocalStorageCachePlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [LocalStorageCachePlatform] when
  /// they register themselves.
  static set instance(LocalStorageCachePlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  // Database operations

  /// Initializes the database with the given [databasePath] and [config].
  Future<void> initialize(String databasePath, Map<String, dynamic> config) {
    throw UnimplementedError('initialize() has not been implemented.');
  }

  /// Closes the database connection.
  Future<void> close() {
    throw UnimplementedError('close() has not been implemented.');
  }

  // CRUD operations

  /// Inserts [data] into [tableName] in the specified [space].
  ///
  /// Returns the ID of the inserted record.
  Future<dynamic> insert(
    String tableName,
    Map<String, dynamic> data,
    String space,
  ) {
    throw UnimplementedError('insert() has not been implemented.');
  }

  /// Executes a query with the given [sql] and [arguments] in the specified [space].
  ///
  /// Returns a list of records matching the query.
  Future<List<Map<String, dynamic>>> query(
    String sql,
    List<dynamic> arguments,
    String space,
  ) {
    throw UnimplementedError('query() has not been implemented.');
  }

  /// Executes an update with the given [sql] and [arguments] in the specified [space].
  ///
  /// Returns the number of rows affected.
  Future<int> update(
    String sql,
    List<dynamic> arguments,
    String space,
  ) {
    throw UnimplementedError('update() has not been implemented.');
  }

  /// Executes a delete with the given [sql] and [arguments] in the specified [space].
  ///
  /// Returns the number of rows deleted.
  Future<int> delete(
    String sql,
    List<dynamic> arguments,
    String space,
  ) {
    throw UnimplementedError('delete() has not been implemented.');
  }

  // Batch operations

  /// Executes a batch of [operations] in the specified [space].
  Future<void> executeBatch(
    List<BatchOperation> operations,
    String space,
  ) {
    throw UnimplementedError('executeBatch() has not been implemented.');
  }

  // Transaction

  /// Executes [action] within a transaction in the specified [space].
  Future<T> transaction<T>(
    Future<T> Function() action,
    String space,
  ) {
    throw UnimplementedError('transaction() has not been implemented.');
  }

  // Encryption

  /// Encrypts [data] using the specified [algorithm].
  Future<String> encrypt(String data, String algorithm) {
    throw UnimplementedError('encrypt() has not been implemented.');
  }

  /// Decrypts [encryptedData] using the specified [algorithm].
  Future<String> decrypt(String encryptedData, String algorithm) {
    throw UnimplementedError('decrypt() has not been implemented.');
  }

  /// Sets the encryption [key] for the database.
  Future<void> setEncryptionKey(String key) {
    throw UnimplementedError('setEncryptionKey() has not been implemented.');
  }

  // Secure storage (for keys)

  /// Saves a secure [key]-[value] pair to platform-specific secure storage.
  Future<void> saveSecureKey(String key, String value) {
    throw UnimplementedError('saveSecureKey() has not been implemented.');
  }

  /// Retrieves a secure value for the given [key] from platform-specific secure storage.
  Future<String?> getSecureKey(String key) {
    throw UnimplementedError('getSecureKey() has not been implemented.');
  }

  /// Deletes a secure value for the given [key] from platform-specific secure storage.
  Future<void> deleteSecureKey(String key) {
    throw UnimplementedError('deleteSecureKey() has not been implemented.');
  }

  // Biometric authentication

  /// Checks if biometric authentication is available on the device.
  Future<bool> isBiometricAvailable() {
    throw UnimplementedError(
      'isBiometricAvailable() has not been implemented.',
    );
  }

  /// Authenticates the user with biometric authentication.
  ///
  /// [reason] is displayed to the user explaining why authentication is required.
  Future<bool> authenticateWithBiometric(String reason) {
    throw UnimplementedError(
      'authenticateWithBiometric() has not been implemented.',
    );
  }

  // File operations

  /// Exports the database from [sourcePath] to [destinationPath].
  Future<void> exportDatabase(String sourcePath, String destinationPath) {
    throw UnimplementedError('exportDatabase() has not been implemented.');
  }

  /// Imports the database from [sourcePath] to [destinationPath].
  Future<void> importDatabase(String sourcePath, String destinationPath) {
    throw UnimplementedError('importDatabase() has not been implemented.');
  }

  // Platform-specific optimizations

  /// Performs a VACUUM operation on the database to reclaim unused space.
  Future<void> vacuum() {
    throw UnimplementedError('vacuum() has not been implemented.');
  }

  /// Gets storage information including size, record count, etc.
  Future<Map<String, dynamic>> getStorageInfo() {
    throw UnimplementedError('getStorageInfo() has not been implemented.');
  }
}
