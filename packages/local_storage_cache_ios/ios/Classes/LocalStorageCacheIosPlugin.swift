import Flutter
import UIKit
import LocalAuthentication

/**
 * LocalStorageCacheIosPlugin
 * 
 * iOS implementation of the local_storage_cache plugin.
 * Provides native SQLite operations with Keychain integration.
 */
public class LocalStorageCacheIosPlugin: NSObject, FlutterPlugin {
    private var databaseManager: DatabaseManager?
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: "local_storage_cache",
            binaryMessenger: registrar.messenger()
        )
        let instance = LocalStorageCacheIosPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "initialize":
            initialize(call: call, result: result)
        case "close":
            close(result: result)
        case "insert":
            insert(call: call, result: result)
        case "query":
            query(call: call, result: result)
        case "update":
            update(call: call, result: result)
        case "delete":
            delete(call: call, result: result)
        case "executeBatch":
            executeBatch(call: call, result: result)
        case "beginTransaction":
            beginTransaction(call: call, result: result)
        case "commitTransaction":
            commitTransaction(call: call, result: result)
        case "rollbackTransaction":
            rollbackTransaction(call: call, result: result)
        case "encrypt":
            encrypt(call: call, result: result)
        case "decrypt":
            decrypt(call: call, result: result)
        case "setEncryptionKey":
            setEncryptionKey(call: call, result: result)
        case "saveSecureKey":
            saveSecureKey(call: call, result: result)
        case "getSecureKey":
            getSecureKey(call: call, result: result)
        case "deleteSecureKey":
            deleteSecureKey(call: call, result: result)
        case "isBiometricAvailable":
            isBiometricAvailable(result: result)
        case "authenticateWithBiometric":
            authenticateWithBiometric(call: call, result: result)
        case "exportDatabase":
            exportDatabase(call: call, result: result)
        case "importDatabase":
            importDatabase(call: call, result: result)
        case "vacuum":
            vacuum(result: result)
        case "getStorageInfo":
            getStorageInfo(result: result)
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    private func initialize(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let databasePath = args["databasePath"] as? String else {
            result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments", details: nil))
            return
        }
        
        let config = args["config"] as? [String: Any] ?? [:]
        databaseManager = DatabaseManager(databasePath: databasePath, config: config)
        result(nil)
    }
    
    private func close(result: @escaping FlutterResult) {
        databaseManager?.close()
        databaseManager = nil
        result(nil)
    }
    
    private func insert(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let tableName = args["tableName"] as? String,
              let data = args["data"] as? [String: Any],
              let space = args["space"] as? String else {
            result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments", details: nil))
            return
        }
        
        do {
            let id = try databaseManager?.insert(tableName: tableName, data: data, space: space)
            result(id)
        } catch {
            result(FlutterError(code: "INSERT_ERROR", message: error.localizedDescription, details: nil))
        }
    }
    
    private func query(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let sql = args["sql"] as? String,
              let arguments = args["arguments"] as? [Any],
              let space = args["space"] as? String else {
            result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments", details: nil))
            return
        }
        
        do {
            let results = try databaseManager?.query(sql: sql, arguments: arguments, space: space)
            result(results)
        } catch {
            result(FlutterError(code: "QUERY_ERROR", message: error.localizedDescription, details: nil))
        }
    }
    
    private func update(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let sql = args["sql"] as? String,
              let arguments = args["arguments"] as? [Any],
              let space = args["space"] as? String else {
            result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments", details: nil))
            return
        }
        
        do {
            let rowsAffected = try databaseManager?.update(sql: sql, arguments: arguments, space: space)
            result(rowsAffected)
        } catch {
            result(FlutterError(code: "UPDATE_ERROR", message: error.localizedDescription, details: nil))
        }
    }
    
    private func delete(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let sql = args["sql"] as? String,
              let arguments = args["arguments"] as? [Any],
              let space = args["space"] as? String else {
            result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments", details: nil))
            return
        }
        
        do {
            let rowsDeleted = try databaseManager?.delete(sql: sql, arguments: arguments, space: space)
            result(rowsDeleted)
        } catch {
            result(FlutterError(code: "DELETE_ERROR", message: error.localizedDescription, details: nil))
        }
    }
    
    private func executeBatch(call: FlutterMethodCall, result: @escaping FlutterResult) {
        // Implementation will be added in Phase 2
        result(FlutterMethodNotImplemented)
    }
    
    private func beginTransaction(call: FlutterMethodCall, result: @escaping FlutterResult) {
        // Implementation will be added in Phase 2
        result(FlutterMethodNotImplemented)
    }
    
    private func commitTransaction(call: FlutterMethodCall, result: @escaping FlutterResult) {
        // Implementation will be added in Phase 2
        result(FlutterMethodNotImplemented)
    }
    
    private func rollbackTransaction(call: FlutterMethodCall, result: @escaping FlutterResult) {
        // Implementation will be added in Phase 2
        result(FlutterMethodNotImplemented)
    }
    
    private func encrypt(call: FlutterMethodCall, result: @escaping FlutterResult) {
        // Implementation will be added in Phase 2
        result(FlutterMethodNotImplemented)
    }
    
    private func decrypt(call: FlutterMethodCall, result: @escaping FlutterResult) {
        // Implementation will be added in Phase 2
        result(FlutterMethodNotImplemented)
    }
    
    private func setEncryptionKey(call: FlutterMethodCall, result: @escaping FlutterResult) {
        // Implementation will be added in Phase 2
        result(FlutterMethodNotImplemented)
    }
    
    private func saveSecureKey(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let key = args["key"] as? String,
              let value = args["value"] as? String else {
            result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments", details: nil))
            return
        }
        
        let keychainHelper = KeychainHelper()
        do {
            try keychainHelper.save(key: key, value: value)
            result(nil)
        } catch {
            result(FlutterError(code: "KEYCHAIN_ERROR", message: error.localizedDescription, details: nil))
        }
    }
    
    private func getSecureKey(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let key = args["key"] as? String else {
            result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments", details: nil))
            return
        }
        
        let keychainHelper = KeychainHelper()
        do {
            let value = try keychainHelper.get(key: key)
            result(value)
        } catch {
            result(nil)
        }
    }
    
    private func deleteSecureKey(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let key = args["key"] as? String else {
            result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments", details: nil))
            return
        }
        
        let keychainHelper = KeychainHelper()
        do {
            try keychainHelper.delete(key: key)
            result(nil)
        } catch {
            result(FlutterError(code: "KEYCHAIN_ERROR", message: error.localizedDescription, details: nil))
        }
    }
    
    private func isBiometricAvailable(result: @escaping FlutterResult) {
        let context = LAContext()
        var error: NSError?
        
        let available = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
        result(available)
    }
    
    private func authenticateWithBiometric(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let reason = args["reason"] as? String else {
            result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments", details: nil))
            return
        }
        
        let context = LAContext()
        var error: NSError?
        
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: reason
            ) { success, error in
                DispatchQueue.main.async {
                    if success {
                        result(true)
                    } else {
                        result(false)
                    }
                }
            }
        } else {
            result(FlutterError(
                code: "BIOMETRIC_UNAVAILABLE",
                message: error?.localizedDescription ?? "Biometric not available",
                details: nil
            ))
        }
    }
    
    private func exportDatabase(call: FlutterMethodCall, result: @escaping FlutterResult) {
        // Implementation will be added in Phase 2
        result(FlutterMethodNotImplemented)
    }
    
    private func importDatabase(call: FlutterMethodCall, result: @escaping FlutterResult) {
        // Implementation will be added in Phase 2
        result(FlutterMethodNotImplemented)
    }
    
    private func vacuum(result: @escaping FlutterResult) {
        // Implementation will be added in Phase 2
        result(FlutterMethodNotImplemented)
    }
    
    private func getStorageInfo(result: @escaping FlutterResult) {
        // Implementation will be added in Phase 2
        result(FlutterMethodNotImplemented)
    }
}
