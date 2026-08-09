import Foundation

struct TokenUsageScanner: Sendable {
    private static let fractionalTimestampStyle = Date.ISO8601FormatStyle(includingFractionalSeconds: true)
    private static let timestampStyle = Date.ISO8601FormatStyle()

    private let sessionsDirectory: URL
    private let calendar: Calendar

    init(
        sessionsDirectory: URL = FileManager.default.homeDirectoryForCurrentUser
            .appending(path: ".codex/sessions", directoryHint: .isDirectory),
        calendar: Calendar = .current
    ) {
        self.sessionsDirectory = sessionsDirectory
        self.calendar = calendar
    }

    func scan(now: Date = Date(), trendDays: Int = 7) -> TokenUsageSummary? {
        guard trendDays > 0,
              FileManager.default.fileExists(atPath: sessionsDirectory.path),
              let enumerator = FileManager.default.enumerator(
                at: sessionsDirectory,
                includingPropertiesForKeys: [.isRegularFileKey],
                options: [.skipsHiddenFiles, .skipsPackageDescendants]
              ) else {
            return nil
        }

        var dailyTotals: [Date: Int64] = [:]
        var totalTokens: Int64 = 0
        var sourceFileCount = 0

        for case let fileURL as URL in enumerator where fileURL.pathExtension == "jsonl" {
            guard let fileTotal = scanFile(fileURL, dailyTotals: &dailyTotals) else { continue }
            totalTokens += fileTotal
            sourceFileCount += 1
        }

        guard sourceFileCount > 0 else { return nil }

        let startOfToday = calendar.startOfDay(for: now)
        let dailyUsage = (0..<trendDays).reversed().compactMap { dayOffset -> DailyTokenUsage? in
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: startOfToday) else {
                return nil
            }
            return DailyTokenUsage(date: date, tokenCount: dailyTotals[date, default: 0])
        }

        return TokenUsageSummary(
            totalTokens: totalTokens,
            dailyUsage: dailyUsage,
            sourceFileCount: sourceFileCount
        )
    }

    private func scanFile(_ fileURL: URL, dailyTotals: inout [Date: Int64]) -> Int64? {
        guard let contents = try? String(contentsOf: fileURL, encoding: .utf8) else { return nil }

        var fileTotal: Int64 = 0
        var previousCumulativeTotal: Int64?
        var foundUsage = false

        for line in contents.split(whereSeparator: \Character.isNewline) {
            guard let data = String(line).data(using: .utf8),
                  let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  root["type"] as? String == "event_msg",
                  let payload = root["payload"] as? [String: Any],
                  payload["type"] as? String == "token_count",
                  let info = payload["info"] as? [String: Any] else {
                continue
            }

            let cumulativeTotal = tokenCount(in: info["total_token_usage"])
            let incrementalTotal = tokenCount(in: info["last_token_usage"])
                ?? cumulativeTotal.map { max(0, $0 - (previousCumulativeTotal ?? 0)) }
            previousCumulativeTotal = cumulativeTotal ?? previousCumulativeTotal

            guard let incrementalTotal, incrementalTotal > 0 else { continue }
            foundUsage = true
            fileTotal += incrementalTotal

            if let timestamp = root["timestamp"] as? String,
               let date = Self.parseTimestamp(timestamp) {
                let day = calendar.startOfDay(for: date)
                dailyTotals[day, default: 0] += incrementalTotal
            }
        }

        return foundUsage ? fileTotal : nil
    }

    private func tokenCount(in value: Any?) -> Int64? {
        guard let usage = value as? [String: Any],
              let total = usage["total_tokens"] as? NSNumber else {
            return nil
        }
        return total.int64Value
    }

    private static func parseTimestamp(_ value: String) -> Date? {
        if let date = try? fractionalTimestampStyle.parse(value) {
            return date
        }
        return try? timestampStyle.parse(value)
    }
}
