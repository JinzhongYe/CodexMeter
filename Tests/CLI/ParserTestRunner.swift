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
        print("All 5 parser tests passed.")
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

    private static func expect(_ condition: @autoclosure () -> Bool, _ message: String) throws {
        guard condition() else { throw ParserTestFailure.assertion(message) }
    }
}
