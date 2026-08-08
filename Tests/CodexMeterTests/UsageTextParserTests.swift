import XCTest
@testable import CodexMeter

final class UsageTextParserTests: XCTestCase {
    func testParsesDocumentedWeeklyLimitFormat() throws {
        let output = """
        Weekly limit:
        ████████░░ 80% left

        Reset:
        Monday at 10:00
        """

        let usage = try UsageTextParser.parse(output)

        XCTAssertEqual(usage.weeklyRemainingPercentage, 80)
        XCTAssertEqual(usage.resetDescription, "Monday at 10:00")
        XCTAssertEqual(usage.source, .textCommand)
    }

    func testParsesUsedPercentageAndInlineReset() throws {
        let output = """
        \u{001B}[32mWeekly limit:\u{001B}[0m 72% used (resets at Aug 12, 09:30)
        """

        let usage = try UsageTextParser.parse(output)

        XCTAssertEqual(usage.weeklyRemainingPercentage, 28)
        XCTAssertEqual(usage.resetDescription, "Aug 12, 09:30")
    }

    func testRejectsUnrelatedOutput() {
        XCTAssertThrowsError(try UsageTextParser.parse("Codex CLI help"))
    }
}
