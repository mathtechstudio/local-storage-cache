#ifndef DATABASE_MANAGER_H_
#define DATABASE_MANAGER_H_

#include <flutter/standard_method_codec.h>
#include <sqlite3.h>
#include <string>
#include <vector>

namespace local_storage_cache_windows {

class DatabaseManager {
 public:
  explicit DatabaseManager(const std::string& database_path);
  ~DatabaseManager();

  bool Initialize();
  void Close();
  
  int64_t Insert(const std::string& table_name, 
                 const flutter::EncodableMap& data,
                 const std::string& space);
  
  flutter::EncodableList Query(const std::string& sql);
  
  int Update(const std::string& sql, const flutter::EncodableList& arguments);
  int Delete(const std::string& sql, const flutter::EncodableList& arguments);

 private:
  std::string database_path_;
  sqlite3* database_;
  
  std::string GetPrefixedTableName(const std::string& table_name, 
                                   const std::string& space);
};

}  // namespace local_storage_cache_windows

#endif  // DATABASE_MANAGER_H_
