import Foundation

@main
struct UsageServiceSmokeRunner {
    static func main() async throws {
        let usage = try await CodexUsageService().fetchUsage()
        let reset = usage.resetAt?.formatted(date: .numeric, time: .standard)
            ?? usage.resetDescription
            ?? "unknown"
        print("Usage fetch passed: \(usage.weeklyRemainingPercentage)% remaining, reset \(reset), source \(usage.source.rawValue)")
    }
}
