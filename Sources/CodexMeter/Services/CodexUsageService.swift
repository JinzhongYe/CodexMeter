import Foundation

protocol UsageProviding: Sendable {
    func fetchUsage() async throws -> UsageSnapshot
}

struct CodexUsageService: UsageProviding, Sendable {
    private let locator: CodexExecutableLocator
    private let appServerTimeout: TimeInterval
    private let textCommandTimeout: TimeInterval

    init(
        locator: CodexExecutableLocator = CodexExecutableLocator(),
        appServerTimeout: TimeInterval = 15,
        textCommandTimeout: TimeInterval = 8
    ) {
        self.locator = locator
        self.appServerTimeout = appServerTimeout
        self.textCommandTimeout = textCommandTimeout
    }

    func fetchUsage() async throws -> UsageSnapshot {
        try await Task.detached(priority: .utility) {
            guard let executable = locator.locate() else {
                throw UsageError.codexNotFound
            }

            do {
                return try fetchFromAppServer(executable: executable)
            } catch {
                do {
                    return try fetchFromTextCommand(executable: executable)
                } catch let fallbackError {
                    let primaryMessage = error.localizedDescription
                    let fallbackMessage = fallbackError.localizedDescription
                    throw UsageError.allMethodsFailed("\(primaryMessage)；\(fallbackMessage)")
                }
            }
        }.value
    }

    private func fetchFromAppServer(executable: URL) throws -> UsageSnapshot {
        let process = Process()
        let standardInput = Pipe()
        let standardOutput = Pipe()
        let standardError = Pipe()
        let responseCollector = AppServerResponseCollector()
        let errorCollector = ProcessOutputCollector()

        process.executableURL = executable
        process.arguments = ["app-server", "--listen", "stdio://"]
        process.environment = commandEnvironment(for: executable)
        process.standardInput = standardInput
        process.standardOutput = standardOutput
        process.standardError = standardError

        standardOutput.fileHandleForReading.readabilityHandler = { handle in
            responseCollector.append(handle.availableData)
        }
        standardError.fileHandleForReading.readabilityHandler = { handle in
            errorCollector.append(handle.availableData)
        }

        do {
            try process.run()
        } catch {
            throw UsageError.launchFailed(error.localizedDescription)
        }

        let requests = [
            #"{"id":1,"method":"initialize","params":{"clientInfo":{"name":"CodexMeter","version":"1.0"}}}"#,
            #"{"method":"initialized"}"#,
            #"{"id":2,"method":"account/rateLimits/read","params":null}"#
        ].joined(separator: "\n") + "\n"

        do {
            try standardInput.fileHandleForWriting.write(contentsOf: Data(requests.utf8))
        } catch {
            stop(process, input: standardInput, output: standardOutput, error: standardError)
            throw UsageError.commandFailed(error.localizedDescription)
        }

        let waitResult = responseCollector.signal.wait(timeout: .now() + appServerTimeout)
        let parsedResult = responseCollector.takeResult()
        stop(process, input: standardInput, output: standardOutput, error: standardError)

        if let parsedResult {
            return try parsedResult.get()
        }
        if waitResult == .timedOut {
            throw UsageError.timeout
        }
        throw UsageError.commandFailed(errorCollector.text().trimmingCharacters(in: .whitespacesAndNewlines))
    }

    private func fetchFromTextCommand(executable: URL) throws -> UsageSnapshot {
        let process = Process()
        let standardInput = Pipe()
        let standardOutput = Pipe()
        let standardError = Pipe()
        let outputCollector = ProcessOutputCollector()
        let errorCollector = ProcessOutputCollector()
        let terminationSignal = DispatchSemaphore(value: 0)

        process.executableURL = executable
        process.arguments = ["/usage"]
        process.environment = commandEnvironment(for: executable)
        process.standardInput = standardInput
        process.standardOutput = standardOutput
        process.standardError = standardError
        process.terminationHandler = { _ in terminationSignal.signal() }

        standardOutput.fileHandleForReading.readabilityHandler = { handle in
            outputCollector.append(handle.availableData)
        }
        standardError.fileHandleForReading.readabilityHandler = { handle in
            errorCollector.append(handle.availableData)
        }

        do {
            try process.run()
            try? standardInput.fileHandleForWriting.close()
        } catch {
            throw UsageError.launchFailed(error.localizedDescription)
        }

        _ = terminationSignal.wait(timeout: .now() + textCommandTimeout)
        stop(process, input: standardInput, output: standardOutput, error: standardError)

        let combinedOutput = outputCollector.text() + "\n" + errorCollector.text()
        return try UsageTextParser.parse(combinedOutput)
    }

    private func stop(_ process: Process, input: Pipe, output: Pipe, error: Pipe) {
        output.fileHandleForReading.readabilityHandler = nil
        error.fileHandleForReading.readabilityHandler = nil
        try? input.fileHandleForWriting.close()
        if process.isRunning {
            process.terminate()
            process.waitUntilExit()
        }
    }

    private func commandEnvironment(for executable: URL) -> [String: String] {
        var environment = ProcessInfo.processInfo.environment
        let inheritedPaths = (environment["PATH"] ?? "")
            .split(separator: ":")
            .map(String.init)
        let requiredPaths = [
            executable.deletingLastPathComponent().path,
            "/opt/homebrew/bin",
            "/usr/local/bin",
            "/usr/bin",
            "/bin",
            "/usr/sbin",
            "/sbin"
        ]

        environment["PATH"] = (requiredPaths + inheritedPaths)
            .reduce(into: [String]()) { paths, path in
                if !path.isEmpty && !paths.contains(path) {
                    paths.append(path)
                }
            }
            .joined(separator: ":")
        return environment
    }
}
