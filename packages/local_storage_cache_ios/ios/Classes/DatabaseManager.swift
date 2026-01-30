import Foundation
import SQLite3

/**
 * DatabaseManager
 * 
 * Manages SQLite database operations for iOS.
 */
class DatabaseManager {
    private var database: OpaquePointer?
    private let databasePath: String
    private let config: [String: Any]
    private var encryptionKey: String?
    
    init(databasePath: String, config: [String: Any]) {
        self.databasePath = databasePath
        self.config = config
        self.encryptionKey = config["encryptionKey"] as? String
    }
    
    /**
     * Opens the database connection.
     */
    func openDatabase() throws {
        if database != nil {
            return // Already open
        }
        
        let result = sqlite3_open(databasePath, &database)
        guard result == SQLITE_OK else {
            throw DatabaseError.openFailed("Failed to open database: \(result)")
        }
        
        // Enable foreign keys
        try execute(sql: "PRAGMA foreign_keys = ON")
    }
    
    /**
     * Inserts data into a table.
     */
    func insert(tableName: String, data: [String: Any], space: String) throws -> Int64 {
        try openDatabase()
        
        let prefixedTableName = getPrefixedTableName(tableName: tableName, space: space)
        let columns = data.keys.joined(separator: ", ")
        let placeholders = data.keys.map { _ in "?" }.joined(separator: ", ")
        let sql = "INSERT INTO \(prefixedTableName) (\(columns)) VALUES (\(placeholders))"
        
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(database, sql, -1, &statement, nil) == SQLITE_OK else {
            throw DatabaseError.executionFailed("Failed to prepare insert statement")
        }
        
        defer { sqlite3_finalize(statement) }
        
        // Bind values
        var index: Int32 = 1
        for (_, value) in data {
            try bindValue(statement: statement, index: index, value: value)
            index += 1
        }
        
        guard sqlite3_step(statement) == SQLITE_DONE else {
            throw DatabaseError.executionFailed("Failed to execute insert")
        }
        
        return sqlite3_last_insert_rowid(database)
    }
    
    /**
     * Executes a query and returns results.
     */
    func query(sql: String, arguments: [Any], space: String) throws -> [[String: Any]] {
        try openDatabase()
        
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(database, sql, -1, &statement, nil) == SQLITE_OK else {
            throw DatabaseError.executionFailed("Failed to prepare query")
        }
        
        defer { sqlite3_finalize(statement) }
        
        // Bind arguments
        for (index, value) in arguments.enumerated() {
            try bindValue(statement: statement, index: Int32(index + 1), value: value)
        }
        
        // Fetch results
        var results: [[String: Any]] = []
        while sqlite3_step(statement) == SQLITE_ROW {
            var row: [String: Any] = [:]
            let columnCount = sqlite3_column_count(statement)
            
            for i in 0..<columnCount {
                let columnName = String(cString: sqlite3_column_name(statement, i))
                let columnType = sqlite3_column_type(statement, i)
                
                let value: Any?
                switch columnType {
                case SQLITE_INTEGER:
                    value = sqlite3_column_int64(statement, i)
                case SQLITE_FLOAT:
                    value = sqlite3_column_double(statement, i)
                case SQLITE_TEXT:
                    value = String(cString: sqlite3_column_text(statement, i))
                case SQLITE_BLOB:
                    let data = sqlite3_column_blob(statement, i)
                    let size = sqlite3_column_bytes(statement, i)
                    value = Data(bytes: data!, count: Int(size))
                case SQLITE_NULL:
                    value = nil
                default:
                    value = nil
                }
                
                row[columnName] = value
            }
            
            results.append(row)
        }
        
        return results
    }
    
    /**
     * Executes an update query.
     */
    func update(sql: String, arguments: [Any], space: String) throws -> Int {
        try openDatabase()
        
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(database, sql, -1, &statement, nil) == SQLITE_OK else {
            throw DatabaseError.executionFailed("Failed to prepare update")
        }
        
        defer { sqlite3_finalize(statement) }
        
        // Bind arguments
        for (index, value) in arguments.enumerated() {
            try bindValue(statement: statement, index: Int32(index + 1), value: value)
        }
        
        guard sqlite3_step(statement) == SQLITE_DONE else {
            throw DatabaseError.executionFailed("Failed to execute update")
        }
        
        return Int(sqlite3_changes(database))
    }
    
    /**
     * Executes a delete query.
     */
    func delete(sql: String, arguments: [Any], space: String) throws -> Int {
        try openDatabase()
        
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(database, sql, -1, &statement, nil) == SQLITE_OK else {
            throw DatabaseError.executionFailed("Failed to prepare delete")
        }
        
        defer { sqlite3_finalize(statement) }
        
        // Bind arguments
        for (index, value) in arguments.enumerated() {
            try bindValue(statement: statement, index: Int32(index + 1), value: value)
        }
        
        guard sqlite3_step(statement) == SQLITE_DONE else {
            throw DatabaseError.executionFailed("Failed to execute delete")
        }
        
        return Int(sqlite3_changes(database))
    }
    
    /**
     * Executes a SQL statement.
     */
    private func execute(sql: String) throws {
        guard sqlite3_exec(database, sql, nil, nil, nil) == SQLITE_OK else {
            throw DatabaseError.executionFailed("Failed to execute SQL")
        }
    }
    
    /**
     * Binds a value to a statement.
     */
    private func bindValue(statement: OpaquePointer?, index: Int32, value: Any) throws {
        if let stringValue = value as? String {
            sqlite3_bind_text(statement, index, stringValue, -1, nil)
        } else if let intValue = value as? Int {
            sqlite3_bind_int64(statement, index, Int64(intValue))
        } else if let int64Value = value as? Int64 {
            sqlite3_bind_int64(statement, index, int64Value)
        } else if let doubleValue = value as? Double {
            sqlite3_bind_double(statement, index, doubleValue)
        } else if let boolValue = value as? Bool {
            sqlite3_bind_int(statement, index, boolValue ? 1 : 0)
        } else if let dataValue = value as? Data {
            dataValue.withUnsafeBytes { bytes in
                sqlite3_bind_blob(statement, index, bytes.baseAddress, Int32(dataValue.count), nil)
            }
        } else {
            sqlite3_bind_null(statement, index)
        }
    }
    
    /**
     * Gets prefixed table name for space isolation.
     */
    private func getPrefixedTableName(tableName: String, space: String) -> String {
        return "\(space)_\(tableName)"
    }
    
    /**
     * Closes the database connection.
     */
    func close() {
        if let db = database {
            sqlite3_close(db)
            database = nil
        }
    }
}

/**
 * Database errors
 */
enum DatabaseError: Error {
    case openFailed(String)
    case executionFailed(String)
    case notInitialized
}
