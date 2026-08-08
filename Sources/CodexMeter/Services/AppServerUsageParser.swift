import Foundation

enum AppServerUsageParser {
    static func parseResponseLine(_ line: String, now: Date = Date()) throws -> UsageSnapshot {
        guard let data = line.data(using: .utf8),
              let root = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              (root["id"] as? NSNumber)?.intValue == 2,
              let result = root["result"] as? [String: Any] else {
            throw UsageError.invalidResponse
        }

        let rateLimits: [String: Any]?
        if let buckets = result["rateLimitsByLimitId"] as? [String: Any],
           let codexBucket = buckets["codex"] as? [String: Any] {
            rateLimits = codexBucket
        } else {
            rateLimits = result["rateLimits"] as? [String: Any]
        }

        guard let rateLimits else { throw UsageError.invalidResponse }
        let windows = [rateLimits["primary"], rateLimits["secondary"]]
            .compactMap { $0 as? [String: Any] }
        guard let weeklyWindow = windows.max(by: { windowDuration($0) < windowDuration($1) }),
              let usedPercent = (weeklyWindow["usedPercent"] as? NSNumber)?.intValue else {
            throw UsageError.invalidResponse
        }

        let resetAt = (weeklyWindow["resetsAt"] as? NSNumber)
            .map { Date(timeIntervalSince1970: $0.doubleValue) }

        return UsageSnapshot(
            weeklyRemainingPercentage: 100 - usedPercent,
            resetAt: resetAt,
            fetchedAt: now,
            source: .appServer
        )
    }

    private static func windowDuration(_ window: [String: Any]) -> Int {
        (window["windowDurationMins"] as? NSNumber)?.intValue ?? 0
    }
}
