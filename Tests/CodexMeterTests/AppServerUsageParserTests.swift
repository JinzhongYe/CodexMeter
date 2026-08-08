import XCTest
@testable import CodexMeter

final class AppServerUsageParserTests: XCTestCase {
    func testSelectsLongestWindowAsWeeklyLimit() throws {
        let response = #"{"id":2,"result":{"rateLimits":{"primary":{"usedPercent":10,"windowDurationMins":300,"resetsAt":1800000000},"secondary":{"usedPercent":56,"windowDurationMins":10080,"resetsAt":1800100000}}}}"#

        let usage = try AppServerUsageParser.parseResponseLine(response)

        XCTAssertEqual(usage.weeklyRemainingPercentage, 44)
        XCTAssertEqual(usage.resetAt, Date(timeIntervalSince1970: 1_800_100_000))
        XCTAssertEqual(usage.source, .appServer)
    }

    func testUsesCodexBucketWhenMultiBucketResponseIsAvailable() throws {
        let response = #"{"id":2,"result":{"rateLimits":{"primary":{"usedPercent":99,"windowDurationMins":10080}},"rateLimitsByLimitId":{"codex":{"primary":{"usedPercent":20,"windowDurationMins":10080,"resetsAt":1800000000}}}}}"#

        let usage = try AppServerUsageParser.parseResponseLine(response)

        XCTAssertEqual(usage.weeklyRemainingPercentage, 80)
    }

    func testRejectsWrongResponseIdentifier() {
        let response = #"{"id":1,"result":{}}"#
        XCTAssertThrowsError(try AppServerUsageParser.parseResponseLine(response))
    }
}
