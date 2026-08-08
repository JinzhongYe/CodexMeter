import Foundation

enum UsageError: LocalizedError, Sendable {
    case codexNotFound
    case launchFailed(String)
    case timeout
    case invalidResponse
    case commandFailed(String)
    case allMethodsFailed(String)

    var errorDescription: String? {
        switch self {
        case .codexNotFound:
            return "找不到 codex 命令。请先安装 Codex CLI，并确认它位于 PATH、/opt/homebrew/bin 或 /usr/local/bin。"
        case .launchFailed(let message):
            return "无法启动 Codex CLI：\(message)"
        case .timeout:
            return "读取 Codex 用量超时。"
        case .invalidResponse:
            return "Codex CLI 返回了无法识别的用量数据。"
        case .commandFailed(let message):
            return message.isEmpty ? "Codex CLI 用量查询失败。" : "Codex CLI 用量查询失败：\(message)"
        case .allMethodsFailed(let message):
            return "无法读取 Codex 用量：\(message)"
        }
    }
}
