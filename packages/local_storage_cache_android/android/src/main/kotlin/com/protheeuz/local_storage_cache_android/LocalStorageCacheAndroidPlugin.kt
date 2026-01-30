package com.protheeuz.local_storage_cache_android

import android.content.Context
import androidx.annotation.NonNull
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

/**
 * LocalStorageCacheAndroidPlugin
 * 
 * Android implementation of the local_storage_cache plugin.
 * Provides native SQLite operations with encryption support via SQLCipher.
 */
class LocalStorageCacheAndroidPlugin : FlutterPlugin, MethodCallHandler {
    private lateinit var channel: MethodChannel
    private lateinit var context: Context
    private var databaseHelper: DatabaseHelper? = null

    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "local_storage_cache")
        channel.setMethodCallHandler(this)
        context = flutterPluginBinding.applicationContext
    }

    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
        when (call.method) {
            "initialize" -> initialize(call, result)
            "close" -> close(result)
            "insert" -> insert(call, result)
            "query" -> query(call, result)
            "update" -> update(call, result)
            "delete" -> delete(call, result)
            "executeBatch" -> executeBatch(call, result)
            "beginTransaction" -> beginTransaction(call, result)
            "commitTransaction" -> commitTransaction(call, result)
            "rollbackTransaction" -> rollbackTransaction(call, result)
            "encrypt" -> encrypt(call, result)
            "decrypt" -> decrypt(call, result)
            "setEncryptionKey" -> setEncryptionKey(call, result)
            "saveSecureKey" -> saveSecureKey(call, result)
            "getSecureKey" -> getSecureKey(call, result)
            "deleteSecureKey" -> deleteSecureKey(call, result)
            "isBiometricAvailable" -> isBiometricAvailable(result)
            "authenticateWithBiometric" -> authenticateWithBiometric(call, result)
            "exportDatabase" -> exportDatabase(call, result)
            "importDatabase" -> importDatabase(call, result)
            "vacuum" -> vacuum(result)
            "getStorageInfo" -> getStorageInfo(result)
            else -> result.notImplemented()
        }
    }

    private fun initialize(call: MethodCall, result: Result) {
        try {
            val databasePath = call.argument<String>("databasePath")
                ?: throw IllegalArgumentException("databasePath is required")
            val config = call.argument<Map<String, Any>>("config")
                ?: emptyMap()

            databaseHelper = DatabaseHelper(context, databasePath, config)
            result.success(null)
        } catch (e: Exception) {
            result.error("INIT_ERROR", "Failed to initialize database: ${e.message}", null)
        }
    }

    private fun close(result: Result) {
        try {
            databaseHelper?.close()
            databaseHelper = null
            result.success(null)
        } catch (e: Exception) {
            result.error("CLOSE_ERROR", "Failed to close database: ${e.message}", null)
        }
    }

    private fun insert(call: MethodCall, result: Result) {
        try {
            val tableName = call.argument<String>("tableName")
                ?: throw IllegalArgumentException("tableName is required")
            val data = call.argument<Map<String, Any>>("data")
                ?: throw IllegalArgumentException("data is required")
            val space = call.argument<String>("space") ?: "default"

            val id = databaseHelper?.insert(tableName, data, space)
            result.success(id)
        } catch (e: Exception) {
            result.error("INSERT_ERROR", "Failed to insert: ${e.message}", null)
        }
    }

    private fun query(call: MethodCall, result: Result) {
        try {
            val sql = call.argument<String>("sql")
                ?: throw IllegalArgumentException("sql is required")
            val arguments = call.argument<List<Any>>("arguments") ?: emptyList()
            val space = call.argument<String>("space") ?: "default"

            val results = databaseHelper?.query(sql, arguments, space)
            result.success(results)
        } catch (e: Exception) {
            result.error("QUERY_ERROR", "Failed to query: ${e.message}", null)
        }
    }

    private fun update(call: MethodCall, result: Result) {
        try {
            val sql = call.argument<String>("sql")
                ?: throw IllegalArgumentException("sql is required")
            val arguments = call.argument<List<Any>>("arguments") ?: emptyList()
            val space = call.argument<String>("space") ?: "default"

            val rowsAffected = databaseHelper?.update(sql, arguments, space)
            result.success(rowsAffected)
        } catch (e: Exception) {
            result.error("UPDATE_ERROR", "Failed to update: ${e.message}", null)
        }
    }

    private fun delete(call: MethodCall, result: Result) {
        try {
            val sql = call.argument<String>("sql")
                ?: throw IllegalArgumentException("sql is required")
            val arguments = call.argument<List<Any>>("arguments") ?: emptyList()
            val space = call.argument<String>("space") ?: "default"

            val rowsDeleted = databaseHelper?.delete(sql, arguments, space)
            result.success(rowsDeleted)
        } catch (e: Exception) {
            result.error("DELETE_ERROR", "Failed to delete: ${e.message}", null)
        }
    }

    private fun executeBatch(call: MethodCall, result: Result) {
        try {
            val operations = call.argument<List<Map<String, Any>>>("operations")
                ?: throw IllegalArgumentException("operations is required")
            val space = call.argument<String>("space") ?: "default"

            databaseHelper?.executeBatch(operations, space)
            result.success(null)
        } catch (e: Exception) {
            result.error("BATCH_ERROR", "Failed to execute batch: ${e.message}", null)
        }
    }

    private fun beginTransaction(call: MethodCall, result: Result) {
        try {
            val space = call.argument<String>("space") ?: "default"
            databaseHelper?.beginTransaction(space)
            result.success(null)
        } catch (e: Exception) {
            result.error("TRANSACTION_ERROR", "Failed to begin transaction: ${e.message}", null)
        }
    }

    private fun commitTransaction(call: MethodCall, result: Result) {
        try {
            val space = call.argument<String>("space") ?: "default"
            databaseHelper?.commitTransaction(space)
            result.success(null)
        } catch (e: Exception) {
            result.error("TRANSACTION_ERROR", "Failed to commit transaction: ${e.message}", null)
        }
    }

    private fun rollbackTransaction(call: MethodCall, result: Result) {
        try {
            val space = call.argument<String>("space") ?: "default"
            databaseHelper?.rollbackTransaction(space)
            result.success(null)
        } catch (e: Exception) {
            result.error("TRANSACTION_ERROR", "Failed to rollback transaction: ${e.message}", null)
        }
    }

    private fun encrypt(call: MethodCall, result: Result) {
        try {
            val data = call.argument<String>("data")
                ?: throw IllegalArgumentException("data is required")
            val algorithm = call.argument<String>("algorithm") ?: "AES-256-GCM"

            val encrypted = databaseHelper?.encrypt(data, algorithm)
            result.success(encrypted)
        } catch (e: Exception) {
            result.error("ENCRYPTION_ERROR", "Failed to encrypt: ${e.message}", null)
        }
    }

    private fun decrypt(call: MethodCall, result: Result) {
        try {
            val encryptedData = call.argument<String>("encryptedData")
                ?: throw IllegalArgumentException("encryptedData is required")
            val algorithm = call.argument<String>("algorithm") ?: "AES-256-GCM"

            val decrypted = databaseHelper?.decrypt(encryptedData, algorithm)
            result.success(decrypted)
        } catch (e: Exception) {
            result.error("DECRYPTION_ERROR", "Failed to decrypt: ${e.message}", null)
        }
    }

    private fun setEncryptionKey(call: MethodCall, result: Result) {
        try {
            val key = call.argument<String>("key")
                ?: throw IllegalArgumentException("key is required")

            databaseHelper?.setEncryptionKey(key)
            result.success(null)
        } catch (e: Exception) {
            result.error("KEY_ERROR", "Failed to set encryption key: ${e.message}", null)
        }
    }

    private fun saveSecureKey(call: MethodCall, result: Result) {
        try {
            val key = call.argument<String>("key")
                ?: throw IllegalArgumentException("key is required")
            val value = call.argument<String>("value")
                ?: throw IllegalArgumentException("value is required")

            val secureStorage = SecureStorageHelper(context)
            secureStorage.saveKey(key, value)
            result.success(null)
        } catch (e: Exception) {
            result.error("SECURE_STORAGE_ERROR", "Failed to save secure key: ${e.message}", null)
        }
    }

    private fun getSecureKey(call: MethodCall, result: Result) {
        try {
            val key = call.argument<String>("key")
                ?: throw IllegalArgumentException("key is required")

            val secureStorage = SecureStorageHelper(context)
            val value = secureStorage.getKey(key)
            result.success(value)
        } catch (e: Exception) {
            result.error("SECURE_STORAGE_ERROR", "Failed to get secure key: ${e.message}", null)
        }
    }

    private fun deleteSecureKey(call: MethodCall, result: Result) {
        try {
            val key = call.argument<String>("key")
                ?: throw IllegalArgumentException("key is required")

            val secureStorage = SecureStorageHelper(context)
            secureStorage.deleteKey(key)
            result.success(null)
        } catch (e: Exception) {
            result.error("SECURE_STORAGE_ERROR", "Failed to delete secure key: ${e.message}", null)
        }
    }

    private fun isBiometricAvailable(result: Result) {
        try {
            val biometricHelper = BiometricHelper(context)
            val available = biometricHelper.isBiometricAvailable()
            result.success(available)
        } catch (e: Exception) {
            result.error("BIOMETRIC_ERROR", "Failed to check biometric: ${e.message}", null)
        }
    }

    private fun authenticateWithBiometric(call: MethodCall, result: Result) {
        try {
            val reason = call.argument<String>("reason") ?: "Authenticate"
            
            val biometricHelper = BiometricHelper(context)
            biometricHelper.authenticate(reason) { success, error ->
                if (success) {
                    result.success(true)
                } else {
                    result.error("BIOMETRIC_ERROR", error ?: "Authentication failed", null)
                }
            }
        } catch (e: Exception) {
            result.error("BIOMETRIC_ERROR", "Failed to authenticate: ${e.message}", null)
        }
    }

    private fun exportDatabase(call: MethodCall, result: Result) {
        try {
            val sourcePath = call.argument<String>("sourcePath")
                ?: throw IllegalArgumentException("sourcePath is required")
            val destinationPath = call.argument<String>("destinationPath")
                ?: throw IllegalArgumentException("destinationPath is required")

            databaseHelper?.exportDatabase(sourcePath, destinationPath)
            result.success(null)
        } catch (e: Exception) {
            result.error("EXPORT_ERROR", "Failed to export database: ${e.message}", null)
        }
    }

    private fun importDatabase(call: MethodCall, result: Result) {
        try {
            val sourcePath = call.argument<String>("sourcePath")
                ?: throw IllegalArgumentException("sourcePath is required")
            val destinationPath = call.argument<String>("destinationPath")
                ?: throw IllegalArgumentException("destinationPath is required")

            databaseHelper?.importDatabase(sourcePath, destinationPath)
            result.success(null)
        } catch (e: Exception) {
            result.error("IMPORT_ERROR", "Failed to import database: ${e.message}", null)
        }
    }

    private fun vacuum(result: Result) {
        try {
            databaseHelper?.vacuum()
            result.success(null)
        } catch (e: Exception) {
            result.error("VACUUM_ERROR", "Failed to vacuum: ${e.message}", null)
        }
    }

    private fun getStorageInfo(result: Result) {
        try {
            val info = databaseHelper?.getStorageInfo()
            result.success(info)
        } catch (e: Exception) {
            result.error("INFO_ERROR", "Failed to get storage info: ${e.message}", null)
        }
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        databaseHelper?.close()
    }
}
