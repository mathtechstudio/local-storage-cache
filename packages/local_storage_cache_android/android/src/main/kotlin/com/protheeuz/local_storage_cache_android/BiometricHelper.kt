package com.protheeuz.local_storage_cache_android

import android.content.Context
import androidx.biometric.BiometricManager
import androidx.biometric.BiometricPrompt
import androidx.core.content.ContextCompat
import androidx.fragment.app.FragmentActivity

/**
 * BiometricHelper
 * 
 * Provides biometric authentication support.
 */
class BiometricHelper(private val context: Context) {
    
    /**
     * Checks if biometric authentication is available.
     */
    fun isBiometricAvailable(): Boolean {
        val biometricManager = BiometricManager.from(context)
        return when (biometricManager.canAuthenticate(BiometricManager.Authenticators.BIOMETRIC_STRONG)) {
            BiometricManager.BIOMETRIC_SUCCESS -> true
            else -> false
        }
    }
    
    /**
     * Authenticates using biometric.
     * 
     * Note: This requires an Activity context. In a plugin context, this is simplified.
     * For production use, you would need to handle the Activity lifecycle properly.
     */
    fun authenticate(reason: String, callback: (Boolean, String?) -> Unit) {
        if (context !is FragmentActivity) {
            callback(false, "Biometric authentication requires Activity context")
            return
        }
        
        val executor = ContextCompat.getMainExecutor(context)
        val biometricPrompt = BiometricPrompt(
            context,
            executor,
            object : BiometricPrompt.AuthenticationCallback() {
                override fun onAuthenticationSucceeded(result: BiometricPrompt.AuthenticationResult) {
                    super.onAuthenticationSucceeded(result)
                    callback(true, null)
                }
                
                override fun onAuthenticationFailed() {
                    super.onAuthenticationFailed()
                    callback(false, "Authentication failed")
                }
                
                override fun onAuthenticationError(errorCode: Int, errString: CharSequence) {
                    super.onAuthenticationError(errorCode, errString)
                    callback(false, errString.toString())
                }
            }
        )
        
        val promptInfo = BiometricPrompt.PromptInfo.Builder()
            .setTitle(reason)
            .setSubtitle("Authenticate to continue")
            .setNegativeButtonText("Cancel")
            .build()
        
        biometricPrompt.authenticate(promptInfo)
    }
}
