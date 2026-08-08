#!/bin/zsh

set -euo pipefail

script_dir=${0:A:h}
project_dir=${script_dir:h}
app_dir="$project_dir/build/CodexMeter.app"

cd "$project_dir"
swift build -c release

mkdir -p "$app_dir/Contents/MacOS" "$app_dir/Contents/Resources"
cp ".build/release/CodexMeter" "$app_dir/Contents/MacOS/CodexMeter"
cp "Resources/Info.plist" "$app_dir/Contents/Info.plist"
chmod +x "$app_dir/Contents/MacOS/CodexMeter"
codesign --force --sign - "$app_dir"

print "Built $app_dir"
