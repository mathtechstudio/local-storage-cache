Pod::Spec.new do |s|
  s.name             = 'local_storage_cache_ios'
  s.version          = '2.0.0'
  s.summary          = 'iOS implementation of the local_storage_cache plugin.'
  s.description      = <<-DESC
iOS implementation of the local_storage_cache plugin with SQLite and Keychain support.
                       DESC
  s.homepage         = 'https://github.com/protheeuz/local-storage-cache'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Iqbal F' => 'github.com/protheeuz' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.dependency 'Flutter'
  s.platform = :ios, '12.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'
  
  # SQLite library
  s.library = 'sqlite3'
end
