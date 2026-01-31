#!/bin/bash
# Script to prepare packages for publishing to pub.dev
# This converts workspace dependencies to hosted dependencies

set -e

echo "🔄 Preparing packages for publishing..."

# Function to update pubspec.yaml for publishing
update_pubspec() {
  local package=$1
  local pubspec="packages/$package/pubspec.yaml"
  
  echo "  📦 Updating $package..."
  
  # Remove 'resolution: workspace' line
  sed -i.bak '/^resolution: workspace$/d' "$pubspec"
  
  # Remove 'publish_to: none' line if exists
  sed -i.bak '/^publish_to: none$/d' "$pubspec"
  
  # Replace path dependency with hosted
  sed -i.bak 's|local_storage_cache_platform_interface:$|local_storage_cache_platform_interface: ^2.0.0|' "$pubspec"
  sed -i.bak '/path: \.\.\/local_storage_cache_platform_interface/d' "$pubspec"
  
  # Remove backup file
  rm -f "$pubspec.bak"
}

# Update all platform packages
update_pubspec "local_storage_cache_android"
update_pubspec "local_storage_cache_ios"
update_pubspec "local_storage_cache_macos"
update_pubspec "local_storage_cache_windows"
update_pubspec "local_storage_cache_linux"
update_pubspec "local_storage_cache_web"

# Update main package
echo "  📦 Updating local_storage_cache..."
sed -i.bak '/^resolution: workspace$/d' "packages/local_storage_cache/pubspec.yaml"
sed -i.bak '/^publish_to: none$/d' "packages/local_storage_cache/pubspec.yaml"
sed -i.bak 's|local_storage_cache_platform_interface:$|local_storage_cache_platform_interface: ^2.0.0|' "packages/local_storage_cache/pubspec.yaml"
sed -i.bak '/path: \.\.\/local_storage_cache_platform_interface/d' "packages/local_storage_cache/pubspec.yaml"
rm -f "packages/local_storage_cache/pubspec.yaml.bak"

# Update platform interface
echo "  📦 Updating local_storage_cache_platform_interface..."
sed -i.bak '/^resolution: workspace$/d' "packages/local_storage_cache_platform_interface/pubspec.yaml"
sed -i.bak '/^publish_to: none$/d' "packages/local_storage_cache_platform_interface/pubspec.yaml"
rm -f "packages/local_storage_cache_platform_interface/pubspec.yaml.bak"

echo "✅ All packages prepared for publishing!"
echo ""
echo "📋 Next steps:"
echo "  1. Review changes: git diff"
echo "  2. Publish platform_interface first"
echo "  3. Publish platform implementations"
echo "  4. Publish main package last"
echo ""
echo "⚠️  Remember to restore workspace mode after publishing!"
echo "   Run: git checkout packages/*/pubspec.yaml"
