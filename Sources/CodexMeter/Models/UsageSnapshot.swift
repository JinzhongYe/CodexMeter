import Foundation

enum UsageSource: String, Sendable {
    case appServer
    case textCommand
}

struct DailyTokenUsage: Identifiable, Equatable, Sendable {
    let date: Date
    let tokenCount: Int64

    var id: Date { date }
}

struct TokenUsageSummary: Equatable, Sendable {
    let totalTokens: Int64
    let dailyUsage: [DailyTokenUsage]
    let sourceFileCount: Int
}

struct UsageSnapshot: Equatable, Sendable {
    let weeklyRemainingPercentage: Int
    let resetAt: Date?
    let resetDescription: String?
    let fetchedAt: Date
    let source: UsageSource
    let tokenUsage: TokenUsageSummary?

    init(
        weeklyRemainingPercentage: Int,
        resetAt: Date? = nil,
        resetDescription: String? = nil,
        fetchedAt: Date = Date(),
        source: UsageSource,
        tokenUsage: TokenUsageSummary? = nil
    ) {
        self.weeklyRemainingPercentage = min(max(weeklyRemainingPercentage, 0), 100)
        self.resetAt = resetAt
        self.resetDescription = resetDescription
        self.fetchedAt = fetchedAt
        self.source = source
        self.tokenUsage = tokenUsage
    }

    func addingTokenUsage(_ tokenUsage: TokenUsageSummary?) -> UsageSnapshot {
        UsageSnapshot(
            weeklyRemainingPercentage: weeklyRemainingPercentage,
            resetAt: resetAt,
            resetDescription: resetDescription,
            fetchedAt: fetchedAt,
            source: source,
            tokenUsage: tokenUsage
        )
    }
}
