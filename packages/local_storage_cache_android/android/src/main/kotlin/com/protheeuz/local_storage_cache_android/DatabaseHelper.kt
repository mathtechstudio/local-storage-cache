package com.protheeuz.local_storage_cache_android

import android.content.ContentValues
import android.content.Context
import net.sqlcipher.database.SQLiteDatabase
import net.sqlcipher.database.SQLiteOpenHelper
import java.io.File
import javax.crypto.Cipher
import javax.crypto.KeyGenerator
import javax.crypto.SecretKey
import javax.crypto.spec.GCMParameterSpec
import javax.crypto.spec.SecretKeySpec
import android.util.Base64

/**
 * DatabaseHelper
 * 
 * Manages SQLite database with optional encryption via SQLCipher.
 * Provides CRUD operations, transactions, and encryption support.
 */
class DatabaseHelper(
    private val context: Context,
    private val databasePath: String,
    private val config: Map<String, Any>
) : SQLiteOpenHelper(context, databasePath, null, 1) {

    private var database: SQLiteDatabase? = null
    private var encryptionKey: String? = null

    init {
        // Load SQLCipher native libraries
        SQLiteDatabase.loadLibs(context)
        encryptionKey = config["encryptionKey"] as? String
    }

    override fun onCreate(db: SQLiteDatabase?) {
        // Database creation will be handled by schema manager
    }

    override fun onUpgrade(db: SQLiteDatabase?, oldVersion: Int, newVersion: Int) {
        // Database upgrades will be handled by migration manager
    }

    /**
     * Opens the database with optional encryption.
     */
    fun openDatabase(): SQLiteDatabase {
        if (database == null || !database!!.isOpen) {
            database = if (encryptionKey != null) {
                // Open encrypted database
                getWritableDatabase(encryptionKey)
            } else {
                // Open unencrypted database
                getWritableDatabase("")
            }
        }
        return database!!
    }

    /**
     * Inserts data into a table.
     */
    fun insert(tableName: String, data: Map<String, Any>, space: String): Long {
        val db = openDatabase()
        val prefixedTableName = getPrefixedTableName(tableName, space)
        
        val values = ContentValues()
        data.forEach { (key, value) ->
            when (value) {
                is String -> values.put(key, value)
                is Int -> values.put(key, value)
                is Long -> values.put(key, value)
                is Double -> values.put(key, value)
                is Float -> values.put(key, value)
                is Boolean -> values.put(key, if (value) 1 else 0)
                is ByteArray -> values.put(key, value)
                null -> values.putNull(key)
            }
        }
        
        return db.insert(prefixedTableName, null, values)
    }

    /**
     * Executes a query and returns results.
     */
    fun query(sql: String, arguments: List<Any>, space: String): List<Map<String, Any?>> {
        val db = openDatabase()
        val args = arguments.map { it.toString() }.toTypedArray()
        
        val cursor = db.rawQuery(sql, args)
        val results = mutableListOf<Map<String, Any?>>()
        
        try {
            while (cursor.moveToNext()) {
                val row = mutableMapOf<String, Any?>()
                for (i in 0 until cursor.columnCount) {
                    val columnName = cursor.getColumnName(i)
                    val value = when (cursor.getType(i)) {
                        android.database.Cursor.FIELD_TYPE_NULL -> null
                        android.database.Cursor.FIELD_TYPE_INTEGER -> cursor.getLong(i)
                        android.database.Cursor.FIELD_TYPE_FLOAT -> cursor.getDouble(i)
                        android.database.Cursor.FIELD_TYPE_STRING -> cursor.getString(i)
                        android.database.Cursor.FIELD_TYPE_BLOB -> cursor.getBlob(i)
                        else -> cursor.getString(i)
                    }
                    row[columnName] = value
                }
                results.add(row)
            }
        } finally {
            cursor.close()
        }
        
        return results
    }

    /**
     * Executes an update query.
     */
    fun update(sql: String, arguments: List<Any>, space: String): Int {
        val db = openDatabase()
        val args = arguments.map { it.toString() }.toTypedArray()
        
        db.execSQL(sql, args)
        return db.changes()
    }

    /**
     * Executes a delete query.
     */
    fun delete(sql: String, arguments: List<Any>, space: String): Int {
        val db = openDatabase()
        val args = arguments.map { it.toString() }.toTypedArray()
        
        db.execSQL(sql, args)
        return db.changes()
    }

    /**
     * Executes a batch of operations.
     */
    fun executeBatch(operations: List<Map<String, Any>>, space: String) {
        val db = openDatabase()
        db.beginTransaction()
        
        try {
            operations.forEach { operation ->
                val type = operation["type"] as String
                val tableName = operation["tableName"] as String
                
                when (type) {
                    "insert" -> {
                        val data = operation["data"] as Map<String, Any>
                        insert(tableName, data, space)
                    }
                    "update" -> {
                        val sql = operation["sql"] as String
                        val arguments = operation["arguments"] as? List<Any> ?: emptyList()
                        update(sql, arguments, space)
                    }
                    "delete" -> {
                        val sql = operation["sql"] as String
                        val arguments = operation["arguments"] as? List<Any> ?: emptyList()
                        delete(sql, arguments, space)
                    }
                }
            }
            
            db.setTransactionSuccessful()
        } finally {
            db.endTransaction()
        }
    }

    /**
     * Begins a transaction.
     */
    fun beginTransaction(space: String) {
        val db = openDatabase()
        db.beginTransaction()
    }

    /**
     * Commits a transaction.
     */
    fun commitTransaction(space: String) {
        val db = openDatabase()
        db.setTransactionSuccessful()
        db.endTransaction()
    }

    /**
     * Rolls back a transaction.
     */
    fun rollbackTransaction(space: String) {
        val db = openDatabase()
        db.endTransaction()
    }

    /**
     * Encrypts data using AES-GCM.
     */
    fun encrypt(data: String, algorithm: String): String {
        val key = getOrCreateEncryptionKey()
        val cipher = Cipher.getInstance("AES/GCM/NoPadding")
        cipher.init(Cipher.ENCRYPT_MODE, key)
        
        val iv = cipher.iv
        val encrypted = cipher.doFinal(data.toByteArray(Charsets.UTF_8))
        
        // Combine IV and encrypted data
        val combined = iv + encrypted
        return Base64.encodeToString(combined, Base64.NO_WRAP)
    }

    /**
     * Decrypts data using AES-GCM.
     */
    fun decrypt(encryptedData: String, algorithm: String): String {
        val key = getOrCreateEncryptionKey()
        val combined = Base64.decode(encryptedData, Base64.NO_WRAP)
        
        // Extract IV and encrypted data
        val iv = combined.copyOfRange(0, 12)
        val encrypted = combined.copyOfRange(12, combined.size)
        
        val cipher = Cipher.getInstance("AES/GCM/NoPadding")
        val spec = GCMParameterSpec(128, iv)
        cipher.init(Cipher.DECRYPT_MODE, key, spec)
        
        val decrypted = cipher.doFinal(encrypted)
        return String(decrypted, Charsets.UTF_8)
    }

    /**
     * Sets the encryption key.
     */
    fun setEncryptionKey(key: String) {
        encryptionKey = key
    }

    /**
     * Exports the database to a file.
     */
    fun exportDatabase(sourcePath: String, destinationPath: String) {
        val sourceFile = File(sourcePath)
        val destFile = File(destinationPath)
        
        sourceFile.copyTo(destFile, overwrite = true)
    }

    /**
     * Imports a database from a file.
     */
    fun importDatabase(sourcePath: String, destinationPath: String) {
        val sourceFile = File(sourcePath)
        val destFile = File(destinationPath)
        
        sourceFile.copyTo(destFile, overwrite = true)
    }

    /**
     * Performs VACUUM operation.
     */
    fun vacuum() {
        val db = openDatabase()
        db.execSQL("VACUUM")
    }

    /**
     * Gets storage information.
     */
    fun getStorageInfo(): Map<String, Any> {
        val db = openDatabase()
        val dbFile = File(databasePath)
        
        return mapOf(
            "databaseSize" to dbFile.length(),
            "pageSize" to db.pageSize,
            "version" to db.version
        )
    }

    /**
     * Gets prefixed table name for space isolation.
     */
    private fun getPrefixedTableName(tableName: String, space: String): String {
        return "${space}_$tableName"
    }

    /**
     * Gets or creates an encryption key.
     */
    private fun getOrCreateEncryptionKey(): SecretKey {
        return if (encryptionKey != null) {
            SecretKeySpec(encryptionKey!!.toByteArray(), "AES")
        } else {
            val keyGen = KeyGenerator.getInstance("AES")
            keyGen.init(256)
            keyGen.generateKey()
        }
    }

    /**
     * Closes the database connection.
     */
    override fun close() {
        database?.close()
        database = null
        super.close()
    }
}
