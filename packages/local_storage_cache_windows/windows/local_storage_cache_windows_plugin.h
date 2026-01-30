#ifndef FLUTTER_PLUGIN_LOCAL_STORAGE_CACHE_WINDOWS_PLUGIN_H_
#define FLUTTER_PLUGIN_LOCAL_STORAGE_CACHE_WINDOWS_PLUGIN_H_

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>

#include <memory>

namespace local_storage_cache_windows {

class LocalStorageCacheWindowsPlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows *registrar);

  LocalStorageCacheWindowsPlugin();

  virtual ~LocalStorageCacheWindowsPlugin();

  // Disallow copy and assign.
  LocalStorageCacheWindowsPlugin(const LocalStorageCacheWindowsPlugin&) = delete;
  LocalStorageCacheWindowsPlugin& operator=(const LocalStorageCacheWindowsPlugin&) = delete;
};

}  // namespace local_storage_cache_windows

#endif  // FLUTTER_PLUGIN_LOCAL_STORAGE_CACHE_WINDOWS_PLUGIN_H_
