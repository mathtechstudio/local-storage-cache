#include "include/local_storage_cache_linux/local_storage_cache_linux_plugin.h"

#include <flutter_linux/flutter_linux.h>
#include <gtk/gtk.h>
#include <sys/utsname.h>

#include <cstring>
#include <memory>

#include "database_manager.h"

#define LOCAL_STORAGE_CACHE_LINUX_PLUGIN(obj) \
  (G_TYPE_CHECK_INSTANCE_CAST((obj), local_storage_cache_linux_plugin_get_type(), \
                               LocalStorageCacheLinuxPlugin))

struct _LocalStorageCacheLinuxPlugin {
  GObject parent_instance;
  std::unique_ptr<DatabaseManager> database_manager;
};

G_DEFINE_TYPE(LocalStorageCacheLinuxPlugin, local_storage_cache_linux_plugin, g_object_get_type())

// Method call handler
static FlMethodResponse* handle_method_call(
    LocalStorageCacheLinuxPlugin* self,
    FlMethodCall* method_call) {
  
  const gchar* method = fl_method_call_get_name(method_call);
  FlValue* args = fl_method_call_get_args(method_call);

  if (strcmp(method, "initialize") == 0) {
    FlValue* database_path_value = fl_value_lookup_string(args, "databasePath");
    if (database_path_value == nullptr) {
      return FL_METHOD_RESPONSE(fl_method_error_response_new(
          "INVALID_ARGS", "databasePath is required", nullptr));
    }
    
    const gchar* database_path = fl_value_get_string(database_path_value);
    self->database_manager = std::make_unique<DatabaseManager>(database_path);
    
    if (self->database_manager->Initialize()) {
      return FL_METHOD_RESPONSE(fl_method_success_response_new(nullptr));
    } else {
      return FL_METHOD_RESPONSE(fl_method_error_response_new(
          "INIT_ERROR", "Failed to initialize database", nullptr));
    }
  }
  else if (strcmp(method, "close") == 0) {
    if (self->database_manager) {
      self->database_manager->Close();
      self->database_manager.reset();
    }
    return FL_METHOD_RESPONSE(fl_method_success_response_new(nullptr));
  }
  else if (strcmp(method, "insert") == 0) {
    if (!self->database_manager) {
      return FL_METHOD_RESPONSE(fl_method_error_response_new(
          "NOT_INITIALIZED", "Database not initialized", nullptr));
    }
    
    FlValue* table_name_value = fl_value_lookup_string(args, "tableName");
    FlValue* data_value = fl_value_lookup_string(args, "data");
    FlValue* space_value = fl_value_lookup_string(args, "space");
    
    if (table_name_value == nullptr || data_value == nullptr) {
      return FL_METHOD_RESPONSE(fl_method_error_response_new(
          "INVALID_ARGS", "tableName and data are required", nullptr));
    }
    
    const gchar* table_name = fl_value_get_string(table_name_value);
    const gchar* space = space_value ? fl_value_get_string(space_value) : "default";
    
    int64_t id = self->database_manager->Insert(table_name, data_value, space);
    
    if (id >= 0) {
      g_autoptr(FlValue) result = fl_value_new_int(id);
      return FL_METHOD_RESPONSE(fl_method_success_response_new(result));
    } else {
      return FL_METHOD_RESPONSE(fl_method_error_response_new(
          "INSERT_ERROR", "Failed to insert data", nullptr));
    }
  }
  else if (strcmp(method, "query") == 0) {
    if (!self->database_manager) {
      return FL_METHOD_RESPONSE(fl_method_error_response_new(
          "NOT_INITIALIZED", "Database not initialized", nullptr));
    }
    
    FlValue* sql_value = fl_value_lookup_string(args, "sql");
    if (sql_value == nullptr) {
      return FL_METHOD_RESPONSE(fl_method_error_response_new(
          "INVALID_ARGS", "sql is required", nullptr));
    }
    
    const gchar* sql = fl_value_get_string(sql_value);
    FlValue* results = self->database_manager->Query(sql);
    
    return FL_METHOD_RESPONSE(fl_method_success_response_new(results));
  }
  else if (strcmp(method, "isBiometricAvailable") == 0) {
    // Linux doesn't have standard biometric API
    g_autoptr(FlValue) result = fl_value_new_bool(FALSE);
    return FL_METHOD_RESPONSE(fl_method_success_response_new(result));
  }

  return FL_METHOD_RESPONSE(fl_method_not_implemented_response_new());
}

static void local_storage_cache_linux_plugin_handle_method_call(
    LocalStorageCacheLinuxPlugin* self,
    FlMethodCall* method_call) {
  g_autoptr(FlMethodResponse) response = handle_method_call(self, method_call);
  fl_method_call_respond(method_call, response, nullptr);
}

static void local_storage_cache_linux_plugin_dispose(GObject* object) {
  G_OBJECT_CLASS(local_storage_cache_linux_plugin_parent_class)->dispose(object);
}

static void local_storage_cache_linux_plugin_class_init(
    LocalStorageCacheLinuxPluginClass* klass) {
  G_OBJECT_CLASS(klass)->dispose = local_storage_cache_linux_plugin_dispose;
}

static void local_storage_cache_linux_plugin_init(LocalStorageCacheLinuxPlugin* self) {}

static void method_call_cb(FlMethodChannel* channel, FlMethodCall* method_call,
                           gpointer user_data) {
  LocalStorageCacheLinuxPlugin* plugin = LOCAL_STORAGE_CACHE_LINUX_PLUGIN(user_data);
  local_storage_cache_linux_plugin_handle_method_call(plugin, method_call);
}

void local_storage_cache_linux_plugin_register_with_registrar(FlPluginRegistrar* registrar) {
  LocalStorageCacheLinuxPlugin* plugin = LOCAL_STORAGE_CACHE_LINUX_PLUGIN(
      g_object_new(local_storage_cache_linux_plugin_get_type(), nullptr));

  g_autoptr(FlStandardMethodCodec) codec = fl_standard_method_codec_new();
  g_autoptr(FlMethodChannel) channel =
      fl_method_channel_new(fl_plugin_registrar_get_messenger(registrar),
                            "local_storage_cache",
                            FL_METHOD_CODEC(codec));
  fl_method_channel_set_method_call_handler(channel, method_call_cb,
                                            g_object_ref(plugin),
                                            g_object_unref);

  g_object_unref(plugin);
}
