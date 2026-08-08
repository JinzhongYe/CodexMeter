import Foundation

enum UsageSource: String, Sendable {
    case appServer
    case textCommand
}

struct UsageSnapshot: Equatable, Sendable {
    let weeklyRemainingPercentage: Int
    let resetAt: Date?
    let resetDescription: String?
    let fetchedAt: Date
    let source: UsageSource

    init(
        weeklyRemainingPercentage: Int,
        resetAt: Date? = nil,
        resetDescription: String? = nil,
        fetchedAt: Date = Date(),
        source: UsageSource
    ) {
        self.weeklyRemainingPercentage = min(max(weeklyRemainingPercentage, 0), 100)
        self.resetAt = resetAt
        self.resetDescription = resetDescription
        self.fetchedAt = fetchedAt
        self.source = source
    }
}
