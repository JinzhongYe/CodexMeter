#!/bin/zsh

set -euo pipefail

script_dir=${0:A:h}
project_dir=${script_dir:h}
app_dir="$project_dir/build/CodexMeter.app"
clang_module_cache="$project_dir/.build/ClangModuleCache"
swiftpm_module_cache="$project_dir/.build/SwiftPMModuleCache"
build_arguments=(-c release --disable-sandbox)

cd "$project_dir"
env \
    CLANG_MODULE_CACHE_PATH="$clang_module_cache" \
    SWIFTPM_MODULECACHE_OVERRIDE="$swiftpm_module_cache" \
    swift build "${build_arguments[@]}"
binary_dir=$(env \
    CLANG_MODULE_CACHE_PATH="$clang_module_cache" \
    SWIFTPM_MODULECACHE_OVERRIDE="$swiftpm_module_cache" \
    swift build "${build_arguments[@]}" --show-bin-path)

mkdir -p "$app_dir/Contents/MacOS" "$app_dir/Contents/Resources"
cp "$binary_dir/CodexMeter" "$app_dir/Contents/MacOS/CodexMeter"
cp "Resources/Info.plist" "$app_dir/Contents/Info.plist"
cp "Resources/AppIcon.icns" "$app_dir/Contents/Resources/AppIcon.icns"
chmod +x "$app_dir/Contents/MacOS/CodexMeter"
codesign --force --sign - "$app_dir"

print "Built $app_dir"
