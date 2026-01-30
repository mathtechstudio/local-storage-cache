#ifndef DATABASE_MANAGER_H_
#define DATABASE_MANAGER_H_

#include <flutter_linux/flutter_linux.h>
#include <sqlite3.h>
#include <string>

class DatabaseManager {
 public:
  explicit DatabaseManager(const std::string& database_path);
  ~DatabaseManager();

  bool Initialize();
  void Close();
  
  int64_t Insert(const std::string& table_name, 
                 FlValue* data,
                 const std::string& space);
  
  FlValue* Query(const std::string& sql);
  
  int Update(const std::string& sql, FlValue* arguments);
  int Delete(const std::string& sql, FlValue* arguments);

 private:
  std::string database_path_;
  sqlite3* database_;
  
  std::string GetPrefixedTableName(const std::string& table_name, 
                                   const std::string& space);
};

#endif  // DATABASE_MANAGER_H_
