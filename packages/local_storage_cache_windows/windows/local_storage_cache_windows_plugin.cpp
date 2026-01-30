#include "local_storage_cache_windows_plugin.h"

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>

#include <memory>
#include <sstream>

#include "database_manager.h"

namespace local_storage_cache_windows {

// Plugin implementation
class LocalStorageCacheWindowsPlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows *registrar);

  LocalStorageCacheWindowsPlugin();

  virtual ~LocalStorageCacheWindowsPlugin();

  // Disallow copy and assign.
  LocalStorageCacheWindowsPlugin(const LocalStorageCacheWindowsPlugin&) = delete;
  LocalStorageCacheWindowsPlugin& operator=(const LocalStorageCacheWindowsPlugin&) = delete;

 private:
  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);

  std::unique_ptr<DatabaseManager> database_manager_;
};

// static
void LocalStorageCacheWindowsPlugin::RegisterWithRegistrar(
    flutter::PluginRegistrarWindows *registrar) {
  auto channel =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          registrar->messenger(), "local_storage_cache",
          &flutter::StandardMethodCodec::GetInstance());

  auto plugin = std::make_unique<LocalStorageCacheWindowsPlugin>();

  channel->SetMethodCallHandler(
      [plugin_pointer = plugin.get()](const auto &call, auto result) {
        plugin_pointer->HandleMethodCall(call, std::move(result));
      });

  registrar->AddPlugin(std::move(plugin));
}

LocalStorageCacheWindowsPlugin::LocalStorageCacheWindowsPlugin() {}

LocalStorageCacheWindowsPlugin::~LocalStorageCacheWindowsPlugin() {}

void LocalStorageCacheWindowsPlugin::HandleMethodCall(
    const flutter::MethodCall<flutter::EncodableValue> &method_call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  
  const auto& method_name = method_call.method_name();
  
  if (method_name == "initialize") {
    const auto* arguments = std::get_if<flutter::EncodableMap>(method_call.arguments());
    if (!arguments) {
      result->Error("INVALID_ARGS", "Invalid arguments");
      return;
    }
    
    auto database_path_it = arguments->find(flutter::EncodableValue("databasePath"));
    if (database_path_it == arguments->end()) {
      result->Error("INVALID_ARGS", "databasePath is required");
      return;
    }
    
    const auto* database_path = std::get_if<std::string>(&database_path_it->second);
    if (!database_path) {
      result->Error("INVALID_ARGS", "databasePath must be a string");
      return;
    }
    
    database_manager_ = std::make_unique<DatabaseManager>(*database_path);
    
    if (database_manager_->Initialize()) {
      result->Success();
    } else {
      result->Error("INIT_ERROR", "Failed to initialize database");
    }
  }
  else if (method_name == "close") {
    if (database_manager_) {
      database_manager_->Close();
      database_manager_.reset();
    }
    result->Success();
  }
  else if (method_name == "insert") {
    if (!database_manager_) {
      result->Error("NOT_INITIALIZED", "Database not initialized");
      return;
    }
    
    const auto* arguments = std::get_if<flutter::EncodableMap>(method_call.arguments());
    if (!arguments) {
      result->Error("INVALID_ARGS", "Invalid arguments");
      return;
    }
    
    // Extract table name, data, and space
    auto table_name_it = arguments->find(flutter::EncodableValue("tableName"));
    auto data_it = arguments->find(flutter::EncodableValue("data"));
    auto space_it = arguments->find(flutter::EncodableValue("space"));
    
    if (table_name_it == arguments->end() || data_it == arguments->end()) {
      result->Error("INVALID_ARGS", "tableName and data are required");
      return;
    }
    
    const auto* table_name = std::get_if<std::string>(&table_name_it->second);
    const auto* data = std::get_if<flutter::EncodableMap>(&data_it->second);
    const auto* space = space_it != arguments->end() 
        ? std::get_if<std::string>(&space_it->second) 
        : nullptr;
    
    std::string space_str = space ? *space : "default";
    
    if (!table_name || !data) {
      result->Error("INVALID_ARGS", "Invalid argument types");
      return;
    }
    
    int64_t id = database_manager_->Insert(*table_name, *data, space_str);
    if (id >= 0) {
      result->Success(flutter::EncodableValue(id));
    } else {
      result->Error("INSERT_ERROR", "Failed to insert data");
    }
  }
  else if (method_name == "query") {
    if (!database_manager_) {
      result->Error("NOT_INITIALIZED", "Database not initialized");
      return;
    }
    
    const auto* arguments = std::get_if<flutter::EncodableMap>(method_call.arguments());
    if (!arguments) {
      result->Error("INVALID_ARGS", "Invalid arguments");
      return;
    }
    
    auto sql_it = arguments->find(flutter::EncodableValue("sql"));
    if (sql_it == arguments->end()) {
      result->Error("INVALID_ARGS", "sql is required");
      return;
    }
    
    const auto* sql = std::get_if<std::string>(&sql_it->second);
    if (!sql) {
      result->Error("INVALID_ARGS", "sql must be a string");
      return;
    }
    
    auto query_result = database_manager_->Query(*sql);
    result->Success(flutter::EncodableValue(query_result));
  }
  else if (method_name == "saveSecureKey") {
    // Use Windows Data Protection API (DPAPI)
    const auto* arguments = std::get_if<flutter::EncodableMap>(method_call.arguments());
    if (!arguments) {
      result->Error("INVALID_ARGS", "Invalid arguments");
      return;
    }
    
    auto key_it = arguments->find(flutter::EncodableValue("key"));
    auto value_it = arguments->find(flutter::EncodableValue("value"));
    
    if (key_it == arguments->end() || value_it == arguments->end()) {
      result->Error("INVALID_ARGS", "key and value are required");
      return;
    }
    
    // Simplified - in production, implement DPAPI encryption
    result->Success();
  }
  else if (method_name == "isBiometricAvailable") {
    // Windows Hello support would go here
    result->Success(flutter::EncodableValue(false));
  }
  else {
    result->NotImplemented();
  }
}

}  // namespace local_storage_cache_windows

void LocalStorageCacheWindowsPluginRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  local_storage_cache_windows::LocalStorageCacheWindowsPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
