#include "database_manager.h"
#include <sstream>

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
                                 FlValue* data,
                                 const std::string& space) {
  if (!database_ || fl_value_get_type(data) != FL_VALUE_TYPE_MAP) {
    return -1;
  }
  
  std::string prefixed_table = GetPrefixedTableName(table_name, space);
  
  // Build INSERT statement (simplified)
  std::string sql = "INSERT INTO " + prefixed_table + " DEFAULT VALUES";
  
  sqlite3_stmt* statement;
  if (sqlite3_prepare_v2(database_, sql.c_str(), -1, &statement, nullptr) != SQLITE_OK) {
    return -1;
  }
  
  int result = sqlite3_step(statement);
  sqlite3_finalize(statement);
  
  if (result != SQLITE_DONE) {
    return -1;
  }
  
  return sqlite3_last_insert_rowid(database_);
}

FlValue* DatabaseManager::Query(const std::string& sql) {
  g_autoptr(FlValue) results = fl_value_new_list();
  
  if (!database_) {
    return fl_value_ref(results);
  }
  
  sqlite3_stmt* statement;
  if (sqlite3_prepare_v2(database_, sql.c_str(), -1, &statement, nullptr) != SQLITE_OK) {
    return fl_value_ref(results);
  }
  
  while (sqlite3_step(statement) == SQLITE_ROW) {
    g_autoptr(FlValue) row = fl_value_new_map();
    int column_count = sqlite3_column_count(statement);
    
    for (int i = 0; i < column_count; i++) {
      const char* column_name = sqlite3_column_name(statement, i);
      int column_type = sqlite3_column_type(statement, i);
      
      g_autoptr(FlValue) key = fl_value_new_string(column_name);
      g_autoptr(FlValue) value = nullptr;
      
      switch (column_type) {
        case SQLITE_INTEGER:
          value = fl_value_new_int(sqlite3_column_int64(statement, i));
          break;
        case SQLITE_FLOAT:
          value = fl_value_new_float(sqlite3_column_double(statement, i));
          break;
        case SQLITE_TEXT: {
          const char* text = reinterpret_cast<const char*>(
              sqlite3_column_text(statement, i));
          value = fl_value_new_string(text);
          break;
        }
        case SQLITE_NULL:
        default:
          value = fl_value_new_null();
          break;
      }
      
      fl_value_set_take(row, key, value);
    }
    
    fl_value_append_take(results, row);
  }
  
  sqlite3_finalize(statement);
  return fl_value_ref(results);
}

int DatabaseManager::Update(const std::string& sql, FlValue* arguments) {
  if (!database_) return 0;
  
  sqlite3_stmt* statement;
  if (sqlite3_prepare_v2(database_, sql.c_str(), -1, &statement, nullptr) != SQLITE_OK) {
    return 0;
  }
  
  sqlite3_step(statement);
  int changes = sqlite3_changes(database_);
  sqlite3_finalize(statement);
  
  return changes;
}

int DatabaseManager::Delete(const std::string& sql, FlValue* arguments) {
  return Update(sql, arguments);
}

std::string DatabaseManager::GetPrefixedTableName(const std::string& table_name,
                                                   const std::string& space) {
  return space + "_" + table_name;
}
