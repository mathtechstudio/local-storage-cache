Pod::Spec.new do |s|
  s.name             = 'local_storage_cache_macos'
  s.version          = '2.0.0'
  s.summary          = 'macOS implementation of the local_storage_cache plugin.'
  s.description      = <<-DESC
macOS implementation of the local_storage_cache plugin with SQLite and Keychain support.
                       DESC
  s.homepage         = 'https://github.com/protheeuz/local-storage-cache'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Iqbal F' => 'github.com/protheeuz' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.dependency 'FlutterMacOS'
  s.platform = :osx, '10.14'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
  s.swift_version = '5.0'
  
  # SQLite library
  s.library = 'sqlite3'
end
