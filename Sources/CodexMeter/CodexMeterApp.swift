import SwiftUI

@main
struct CodexMeterApp: App {
    @StateObject private var viewModel = UsageViewModel()
    @AppStorage("menuBarPrefix") private var menuBarPrefix = "Codex"

    var body: some Scene {
        MenuBarExtra {
            UsageView(viewModel: viewModel)
        } label: {
            Text(menuBarTitle)
                .monospacedDigit()
                .accessibilityLabel("Codex 周额度剩余 \(menuBarTitle)")
        }
        .menuBarExtraStyle(.window)
    }

    private var menuBarTitle: String {
        let quota = viewModel.usage.map { "\($0.weeklyRemainingPercentage)%" } ?? "--%"
        let prefix = menuBarPrefix.trimmingCharacters(in: .whitespacesAndNewlines)
        return prefix.isEmpty ? quota : "\(prefix) \(quota)"
    }
}
