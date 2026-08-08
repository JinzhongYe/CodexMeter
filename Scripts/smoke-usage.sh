#!/bin/zsh

set -euo pipefail

script_dir=${0:A:h}
project_dir=${script_dir:h}
runner_path="$project_dir/.build/usage-service-smoke"

cd "$project_dir"
xcrun swiftc \
    -module-cache-path "$project_dir/.build/SmokeModuleCache" \
    Sources/CodexMeter/Models/UsageError.swift \
    Sources/CodexMeter/Models/UsageSnapshot.swift \
    Sources/CodexMeter/Services/AppServerUsageParser.swift \
    Sources/CodexMeter/Services/CodexExecutableLocator.swift \
    Sources/CodexMeter/Services/CodexUsageService.swift \
    Sources/CodexMeter/Services/ProcessOutputCollector.swift \
    Sources/CodexMeter/Services/UsageTextParser.swift \
    Tests/CLI/UsageServiceSmokeRunner.swift \
    -o "$runner_path"

"$runner_path"
