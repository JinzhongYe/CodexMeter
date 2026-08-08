import Foundation

struct CodexExecutableLocator: Sendable {
    func locate() -> URL? {
        let fileManager = FileManager.default
        let environment = ProcessInfo.processInfo.environment
        let homeDirectory = fileManager.homeDirectoryForCurrentUser.path
        let pathCandidates = (environment["PATH"] ?? "")
            .split(separator: ":")
            .map { String($0) + "/codex" }

        let knownCandidates = [
            "/opt/homebrew/bin/codex",
            "/usr/local/bin/codex",
            homeDirectory + "/.local/bin/codex",
            "/Applications/Codex.app/Contents/Resources/codex"
        ]

        return (pathCandidates + knownCandidates)
            .first(where: fileManager.isExecutableFile(atPath:))
            .map(URL.init(fileURLWithPath:))
    }
}
