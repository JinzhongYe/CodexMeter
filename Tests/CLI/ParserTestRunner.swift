import Foundation

enum ParserTestFailure: Error, CustomStringConvertible {
    case assertion(String)

    var description: String {
        switch self {
        case .assertion(let message): return message
        }
    }
}

@main
struct ParserTestRunner {
    static func main() throws {
        try testDocumentedTextFormat()
        try testUsedPercentageAndANSIText()
        try testStructuredRateLimits()
        try testMultiBucketPreference()
        try testInvalidResponses()
        try testTokenUsageAggregation()
        print("All 6 parser and usage tests passed.")
    }

    private static func testDocumentedTextFormat() throws {
        let output = """
        Weekly limit:
        ████████░░ 80% left

        Reset:
        Monday at 10:00
        """
        let usage = try UsageTextParser.parse(output)
        try expect(usage.weeklyRemainingPercentage == 80, "Expected 80% remaining")
        try expect(usage.resetDescription == "Monday at 10:00", "Expected Reset line to be parsed")
    }

    private static func testUsedPercentageAndANSIText() throws {
        let output = "\u{001B}[32mWeekly limit:\u{001B}[0m 72% used (resets at Aug 12, 09:30)"
        let usage = try UsageTextParser.parse(output)
        try expect(usage.weeklyRemainingPercentage == 28, "Expected used percentage to be inverted")
        try expect(usage.resetDescription == "Aug 12, 09:30", "Expected inline reset to be parsed")
    }

    private static func testStructuredRateLimits() throws {
        let response = #"{"id":2,"result":{"rateLimits":{"primary":{"usedPercent":10,"windowDurationMins":300,"resetsAt":1800000000},"secondary":{"usedPercent":56,"windowDurationMins":10080,"resetsAt":1800100000}}}}"#
        let usage = try AppServerUsageParser.parseResponseLine(response)
        try expect(usage.weeklyRemainingPercentage == 44, "Expected the longest window to be selected")
        try expect(usage.resetAt == Date(timeIntervalSince1970: 1_800_100_000), "Expected Unix reset time")
    }

    private static func testMultiBucketPreference() throws {
        let response = #"{"id":2,"result":{"rateLimits":{"primary":{"usedPercent":99,"windowDurationMins":10080}},"rateLimitsByLimitId":{"codex":{"primary":{"usedPercent":20,"windowDurationMins":10080}}}}}"#
        let usage = try AppServerUsageParser.parseResponseLine(response)
        try expect(usage.weeklyRemainingPercentage == 80, "Expected the Codex bucket to take precedence")
    }

    private static func testInvalidResponses() throws {
        do {
            _ = try UsageTextParser.parse("Codex CLI help")
            throw ParserTestFailure.assertion("Expected unrelated text to fail")
        } catch is UsageError {
            // Expected.
        }

        do {
            _ = try AppServerUsageParser.parseResponseLine(#"{"id":1,"result":{}}"#)
            throw ParserTestFailure.assertion("Expected the wrong response identifier to fail")
        } catch is UsageError {
            // Expected.
        }
    }

    private static func testTokenUsageAggregation() throws {
        let temporaryDirectory = FileManager.default.temporaryDirectory
            .appending(path: "CodexMeterTests-\(UUID().uuidString)", directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: temporaryDirectory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: temporaryDirectory) }

        try expect(
            TokenUsageScanner(sessionsDirectory: temporaryDirectory).scan() == nil,
            "Expected an empty sessions directory to have no summary"
        )

        let fixture = """
        {"timestamp":"2026-08-08T10:00:00.000Z","type":"event_msg","payload":{"type":"token_count","info":{"last_token_usage":{"total_tokens":1200},"total_token_usage":{"total_tokens":1200}}}}
        {"timestamp":"2026-08-09T10:00:00.000Z","type":"event_msg","payload":{"type":"token_count","info":{"last_token_usage":{"total_tokens":800},"total_token_usage":{"total_tokens":2000}}}}
        """
        try fixture.write(
            to: temporaryDirectory.appending(path: "rollout.jsonl"),
            atomically: true,
            encoding: .utf8
        )

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let now = ISO8601DateFormatter().date(from: "2026-08-09T12:00:00Z")!
        let summary = TokenUsageScanner(sessionsDirectory: temporaryDirectory, calendar: calendar)
            .scan(now: now, trendDays: 2)

        try expect(summary?.totalTokens == 2_000, "Expected token increments to be summed")
        try expect(summary?.dailyUsage.map(\.tokenCount) == [1_200, 800], "Expected daily token totals")
        try expect(summary?.sourceFileCount == 1, "Expected one source file")
    }

    private static func expect(_ condition: @autoclosure () -> Bool, _ message: String) throws {
        guard condition() else { throw ParserTestFailure.assertion(message) }
    }
}
