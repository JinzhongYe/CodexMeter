import Combine
import Foundation

@MainActor
final class UsageViewModel: ObservableObject {
    @Published private(set) var usage: UsageSnapshot?
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?

    private let provider: any UsageProviding
    private let refreshInterval: Duration
    private var refreshLoop: Task<Void, Never>?

    init(
        provider: any UsageProviding = CodexUsageService(),
        refreshInterval: Duration = .seconds(300)
    ) {
        self.provider = provider
        self.refreshInterval = refreshInterval
    }

    func start() {
        guard refreshLoop == nil else { return }
        refreshLoop = Task { [weak self] in
            guard let self else { return }
            await refresh()
            while !Task.isCancelled {
                do {
                    try await Task.sleep(for: refreshInterval)
                } catch {
                    return
                }
                await refresh()
            }
        }
    }

    func refresh() async {
        guard !isLoading else { return }
        isLoading = true
        defer { isLoading = false }

        do {
            usage = try await provider.fetchUsage()
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    deinit {
        refreshLoop?.cancel()
    }
}
