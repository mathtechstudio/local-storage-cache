#include "database_manager.h"
#include <sstream>

namespace local_storage_cache_windows {

DatabaseManager::DatabaseManager(const std::string& database_path)
    : database_path_(database_path), database_(nullptr) {}

DatabaseManager::~DatabaseManager() {
  Close();
}

bool DatabaseManager::Initialize() {
  int result = sqlite3_open(database_path_.c_str(), &database_);
  if (result != SQLITE_OK) {
    return false;
  }
  
  // Enable foreign keys
  sqlite3_exec(database_, "PRAGMA foreign_keys = ON", nullptr, nullptr, nullptr);
  
  return true;
}

void DatabaseManager::Close() {
  if (database_) {
    sqlite3_close(database_);
    database_ = nullptr;
  }
}

int64_t DatabaseManager::Insert(const std::string& table_name,
                                 const flutter::EncodableMap& data,
                                 const std::string& space) {
  if (!database_) return -1;
  
  std::string prefixed_table = GetPrefixedTableName(table_name, space);
  
  // Build INSERT statement
  std::ostringstream columns_stream, placeholders_stream;
  bool first = true;
  
  for (const auto& pair : data) {
    if (!first) {
      columns_stream << ", ";
      placeholders_stream << ", ";
    }
    first = false;
    
    const auto* key = std::get_if<std::string>(&pair.first);
    if (key) {
      columns_stream << *key;
      placeholders_stream << "?";
    }
  }
  
  std::string sql = "INSERT INTO " + prefixed_table + 
                    " (" + columns_stream.str() + ") VALUES (" + 
                    placeholders_stream.str() + ")";
  
  sqlite3_stmt* statement;
  if (sqlite3_prepare_v2(database_, sql.c_str(), -1, &statement, nullptr) != SQLITE_OK) {
    return -1;
  }
  
  // Bind values
  int index = 1;
  for (const auto& pair : data) {
    if (const auto* str_val = std::get_if<std::string>(&pair.second)) {
      sqlite3_bind_text(statement, index, str_val->c_str(), -1, SQLITE_TRANSIENT);
    } else if (const auto* int_val = std::get_if<int32_t>(&pair.second)) {
      sqlite3_bind_int(statement, index, *int_val);
    } else if (const auto* int64_val = std::get_if<int64_t>(&pair.second)) {
      sqlite3_bind_int64(statement, index, *int64_val);
    } else if (const auto* double_val = std::get_if<double>(&pair.second)) {
      sqlite3_bind_double(statement, index, *double_val);
    } else if (const auto* bool_val = std::get_if<bool>(&pair.second)) {
      sqlite3_bind_int(statement, index, *bool_val ? 1 : 0);
    } else {
      sqlite3_bind_null(statement, index);
    }
    index++;
  }
  
  int result = sqlite3_step(statement);
  sqlite3_finalize(statement);
  
  if (result != SQLITE_DONE) {
    return -1;
  }
  
  return sqlite3_last_insert_rowid(database_);
}

flutter::EncodableList DatabaseManager::Query(const std::string& sql) {
  flutter::EncodableList results;
  
  if (!database_) return results;
  
  sqlite3_stmt* statement;
  if (sqlite3_prepare_v2(database_, sql.c_str(), -1, &statement, nullptr) != SQLITE_OK) {
    return results;
  }
  
  while (sqlite3_step(statement) == SQLITE_ROW) {
    flutter::EncodableMap row;
    int column_count = sqlite3_column_count(statement);
    
    for (int i = 0; i < column_count; i++) {
      std::string column_name = sqlite3_column_name(statement, i);
      int column_type = sqlite3_column_type(statement, i);
      
      flutter::EncodableValue value;
      switch (column_type) {
        case SQLITE_INTEGER:
          value = flutter::EncodableValue(sqlite3_column_int64(statement, i));
          break;
        case SQLITE_FLOAT:
          value = flutter::EncodableValue(sqlite3_column_double(statement, i));
          break;
        case SQLITE_TEXT: {
          const char* text = reinterpret_cast<const char*>(
              sqlite3_column_text(statement, i));
          value = flutter::EncodableValue(std::string(text));
          break;
        }
        case SQLITE_NULL:
        default:
          value = flutter::EncodableValue();
          break;
      }
      
      row[flutter::EncodableValue(column_name)] = value;
    }
    
    results.push_back(flutter::EncodableValue(row));
  }
  
  sqlite3_finalize(statement);
  return results;
}

int DatabaseManager::Update(const std::string& sql, 
                            const flutter::EncodableList& arguments) {
  if (!database_) return 0;
  
  sqlite3_stmt* statement;
  if (sqlite3_prepare_v2(database_, sql.c_str(), -1, &statement, nullptr) != SQLITE_OK) {
    return 0;
  }
  
  // Bind arguments (simplified)
  sqlite3_step(statement);
  int changes = sqlite3_changes(database_);
  sqlite3_finalize(statement);
  
  return changes;
}

int DatabaseManager::Delete(const std::string& sql,
                            const flutter::EncodableList& arguments) {
  return Update(sql, arguments);
}

std::string DatabaseManager::GetPrefixedTableName(const std::string& table_name,
                                                   const std::string& space) {
  return space + "_" + table_name;
}

}  // namespace local_storage_cache_windows
