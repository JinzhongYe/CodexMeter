#!/bin/zsh

set -euo pipefail

script_dir=${0:A:h}
project_dir=${script_dir:h}
runner_path="$project_dir/.build/parser-tests"

cd "$project_dir"
xcrun swiftc \
    -module-cache-path "$project_dir/.build/ParserModuleCache" \
    Sources/CodexMeter/Models/UsageError.swift \
    Sources/CodexMeter/Models/UsageSnapshot.swift \
    Sources/CodexMeter/Services/UsageTextParser.swift \
    Sources/CodexMeter/Services/AppServerUsageParser.swift \
    Tests/CLI/ParserTestRunner.swift \
    -o "$runner_path"

"$runner_path"
