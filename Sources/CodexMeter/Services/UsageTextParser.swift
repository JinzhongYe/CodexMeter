import Foundation

enum UsageTextParser {
    static func parse(_ rawText: String, now: Date = Date()) throws -> UsageSnapshot {
        let text = removingANSIEscapeSequences(from: rawText)
        let lines = text.components(separatedBy: .newlines)

        guard let weeklyIndex = lines.firstIndex(where: {
            $0.range(of: "weekly", options: .caseInsensitive) != nil &&
                $0.range(of: "limit", options: .caseInsensitive) != nil
        }) else {
            throw UsageError.invalidResponse
        }

        let contextEnd = min(lines.endIndex, weeklyIndex + 5)
        let weeklyContext = lines[weeklyIndex..<contextEnd].joined(separator: " ")
        guard let percentageMatch = firstMatch(
            pattern: #"(\d{1,3}(?:\.\d+)?)\s*%\s*(left|remaining|used)?"#,
            in: weeklyContext
        ), let numericValue = Double(percentageMatch[1]) else {
            throw UsageError.invalidResponse
        }

        let qualifier = percentageMatch.indices.contains(2) ? percentageMatch[2].lowercased() : "left"
        let remaining = qualifier == "used" ? 100 - Int(numericValue.rounded()) : Int(numericValue.rounded())
        let resetDescription = parseResetDescription(from: text, weeklyContext: weeklyContext)

        return UsageSnapshot(
            weeklyRemainingPercentage: remaining,
            resetDescription: resetDescription,
            fetchedAt: now,
            source: .textCommand
        )
    }

    private static func parseResetDescription(from text: String, weeklyContext: String) -> String? {
        if let inline = firstMatch(
            pattern: #"resets?\s+(?:at\s+)?([^\)\n]+)"#,
            in: weeklyContext
        )?.dropFirst().first {
            return inline.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        return firstMatch(
            pattern: #"^\s*Reset\s*:\s*(.+?)\s*$"#,
            in: text,
            options: [.caseInsensitive, .anchorsMatchLines]
        )?.dropFirst().first?.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func removingANSIEscapeSequences(from text: String) -> String {
        guard let expression = try? NSRegularExpression(pattern: "\u{001B}\\[[0-?]*[ -/]*[@-~]") else {
            return text
        }
        let range = NSRange(text.startIndex..., in: text)
        return expression.stringByReplacingMatches(in: text, range: range, withTemplate: "")
    }

    private static func firstMatch(
        pattern: String,
        in text: String,
        options: NSRegularExpression.Options = [.caseInsensitive]
    ) -> [String]? {
        guard let expression = try? NSRegularExpression(pattern: pattern, options: options) else {
            return nil
        }
        let fullRange = NSRange(text.startIndex..., in: text)
        guard let match = expression.firstMatch(in: text, range: fullRange) else {
            return nil
        }

        return (0..<match.numberOfRanges).map { index in
            let range = match.range(at: index)
            guard range.location != NSNotFound, let swiftRange = Range(range, in: text) else { return "" }
            return String(text[swiftRange])
        }
    }
}
