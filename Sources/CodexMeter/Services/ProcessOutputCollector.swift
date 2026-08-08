import Foundation

final class ProcessOutputCollector: @unchecked Sendable {
    private let lock = NSLock()
    private var data = Data()

    func append(_ chunk: Data) {
        lock.lock()
        data.append(chunk)
        lock.unlock()
    }

    func text() -> String {
        lock.lock()
        defer { lock.unlock() }
        return String(decoding: data, as: UTF8.self)
    }
}

final class AppServerResponseCollector: @unchecked Sendable {
    private let lock = NSLock()
    private var bufferedText = ""
    private var result: Result<UsageSnapshot, Error>?
    let signal = DispatchSemaphore(value: 0)

    func append(_ chunk: Data) {
        let chunkText = String(decoding: chunk, as: UTF8.self)
        lock.lock()
        bufferedText += chunkText
        let lines = bufferedText.components(separatedBy: .newlines)
        bufferedText = lines.last ?? ""

        for line in lines.dropLast() where result == nil {
            guard line.contains(#""id":2"#) else { continue }
            do {
                result = .success(try AppServerUsageParser.parseResponseLine(line))
            } catch {
                result = .failure(error)
            }
            signal.signal()
        }
        lock.unlock()
    }

    func takeResult() -> Result<UsageSnapshot, Error>? {
        lock.lock()
        defer { lock.unlock() }
        return result
    }
}
