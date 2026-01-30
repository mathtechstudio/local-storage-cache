package com.protheeuz.local_storage_cache_android

import android.content.Context
import android.content.SharedPreferences
import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyProperties
import android.util.Base64
import java.security.KeyStore
import javax.crypto.Cipher
import javax.crypto.KeyGenerator
import javax.crypto.SecretKey
import javax.crypto.spec.GCMParameterSpec

/**
 * SecureStorageHelper
 * 
 * Provides secure storage using Android Keystore.
 */
class SecureStorageHelper(private val context: Context) {
    
    private val keyStore: KeyStore = KeyStore.getInstance("AndroidKeyStore").apply {
        load(null)
    }
    
    private val prefs: SharedPreferences = context.getSharedPreferences(
        "secure_storage",
        Context.MODE_PRIVATE
    )
    
    companion object {
        private const val KEY_ALIAS = "local_storage_cache_key"
        private const val TRANSFORMATION = "AES/GCM/NoPadding"
        private const val IV_SEPARATOR = "]"
    }
    
    /**
     * Saves a key-value pair securely.
     */
    fun saveKey(key: String, value: String) {
        val secretKey = getOrCreateSecretKey()
        val cipher = Cipher.getInstance(TRANSFORMATION)
        cipher.init(Cipher.ENCRYPT_MODE, secretKey)
        
        val iv = cipher.iv
        val encrypted = cipher.doFinal(value.toByteArray(Charsets.UTF_8))
        
        // Store IV and encrypted data together
        val combined = Base64.encodeToString(iv, Base64.NO_WRAP) + 
                      IV_SEPARATOR + 
                      Base64.encodeToString(encrypted, Base64.NO_WRAP)
        
        prefs.edit().putString(key, combined).apply()
    }
    
    /**
     * Retrieves a value by key.
     */
    fun getKey(key: String): String? {
        val combined = prefs.getString(key, null) ?: return null
        
        try {
            val parts = combined.split(IV_SEPARATOR)
            if (parts.size != 2) return null
            
            val iv = Base64.decode(parts[0], Base64.NO_WRAP)
            val encrypted = Base64.decode(parts[1], Base64.NO_WRAP)
            
            val secretKey = getOrCreateSecretKey()
            val cipher = Cipher.getInstance(TRANSFORMATION)
            val spec = GCMParameterSpec(128, iv)
            cipher.init(Cipher.DECRYPT_MODE, secretKey, spec)
            
            val decrypted = cipher.doFinal(encrypted)
            return String(decrypted, Charsets.UTF_8)
        } catch (e: Exception) {
            return null
        }
    }
    
    /**
     * Deletes a key.
     */
    fun deleteKey(key: String) {
        prefs.edit().remove(key).apply()
    }
    
    /**
     * Gets or creates a secret key in Android Keystore.
     */
    private fun getOrCreateSecretKey(): SecretKey {
        if (!keyStore.containsAlias(KEY_ALIAS)) {
            val keyGenerator = KeyGenerator.getInstance(
                KeyProperties.KEY_ALGORITHM_AES,
                "AndroidKeyStore"
            )
            
            val keyGenParameterSpec = KeyGenParameterSpec.Builder(
                KEY_ALIAS,
                KeyProperties.PURPOSE_ENCRYPT or KeyProperties.PURPOSE_DECRYPT
            )
                .setBlockModes(KeyProperties.BLOCK_MODE_GCM)
                .setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_NONE)
                .setKeySize(256)
                .build()
            
            keyGenerator.init(keyGenParameterSpec)
            keyGenerator.generateKey()
        }
        
        return keyStore.getKey(KEY_ALIAS, null) as SecretKey
    }
}
