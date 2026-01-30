cmake_minimum_required(VERSION 3.14)
set(PROJECT_NAME "local_storage_cache_windows")
project(${PROJECT_NAME} LANGUAGES CXX)

# This value is used when generating builds using this plugin, so it must
# not be changed
set(PLUGIN_NAME "local_storage_cache_windows_plugin")

add_library(${PLUGIN_NAME} SHARED
  "local_storage_cache_windows_plugin.cpp"
  "database_manager.cpp"
)

apply_standard_settings(${PLUGIN_NAME})
set_target_properties(${PLUGIN_NAME} PROPERTIES
  CXX_VISIBILITY_PRESET hidden)
target_compile_definitions(${PLUGIN_NAME} PRIVATE FLUTTER_PLUGIN_IMPL)
target_include_directories(${PLUGIN_NAME} INTERFACE
  "${CMAKE_CURRENT_SOURCE_DIR}/include")
target_link_libraries(${PLUGIN_NAME} PRIVATE flutter flutter_wrapper_plugin)

# SQLite3
find_package(unofficial-sqlite3 CONFIG REQUIRED)
target_link_libraries(${PLUGIN_NAME} PRIVATE unofficial::sqlite3::sqlite3)

# Windows Data Protection API
target_link_libraries(${PLUGIN_NAME} PRIVATE crypt32)

# List of absolute paths to libraries that should be bundled with the plugin
set(local_storage_cache_windows_bundled_libraries
  ""
  PARENT_SCOPE
)
