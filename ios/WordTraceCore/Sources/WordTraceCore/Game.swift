import Foundation

public struct Progress: Codable, Equatable {
    public var found: [String]
    public var misses: [[Int]]
    public var hints: [String: Int]
    public var missCount: Int
    public var elapsedMs: Double
    public var completed: Bool

    public init(
        found: [String] = [],
        misses: [[Int]] = [],
        hints: [String: Int] = [:],
        missCount: Int = 0,
        elapsedMs: Double = 0,
        completed: Bool = false
    ) {
        self.found = found
        self.misses = misses
        self.hints = hints
        self.missCount = missCount
        self.elapsedMs = elapsedMs
        self.completed = completed
    }

    public static func empty() -> Progress { Progress() }
}

public enum TraceResult: Equatable {
    case found(PuzzleWord)
    case alreadyFound(PuzzleWord)
    case wrongTiles(String)
    case notAWord(String)
    case tooShort
}

func samePath(_ a: [Int], _ b: [Int]) -> Bool {
    a.count == b.count && zip(a, b).allSatisfy { $0 == $1 }
}

public func spell(_ puzzle: Puzzle, path: [Int]) -> String {
    path.map { index in
        guard let letter = puzzle.cells[index] else { return "" }
        return String(letter)
    }.joined()
}

public func evaluateTrace(puzzle: Puzzle, progress: Progress, path: [Int]) -> TraceResult {
    if path.count < 3 { return .tooShort }
    let text = spell(puzzle, path: path)
    let reversed = Array(path.reversed())

    for word in puzzle.words {
        let matches = samePath(word.path, path) || (isPalindrome(word.text) && samePath(word.path, reversed))
        if !matches { continue }
        return progress.found.contains(word.key) ? .alreadyFound(word) : .found(word)
    }

    let remaining = puzzle.words.filter { !progress.found.contains($0.key) }
    if remaining.contains(where: { $0.text == text }) { return .wrongTiles(text) }
    return .notAWord(text)
}

public func lockedCells(puzzle: Puzzle, progress: Progress) -> [Int: PuzzleWord] {
    var map: [Int: PuzzleWord] = [:]
    for key in progress.found {
        guard let word = puzzle.words.first(where: { $0.key == key }) else { continue }
        for cell in word.path { map[cell] = word }
    }
    return map
}

/// Reveals one more letter of the shortest unfound word that is still partly hidden.
/// Words that already have a hint are continued before a new word is started.
public func nextHint(puzzle: Puzzle, progress: Progress) -> [String: Int]? {
    let candidates = puzzle.words
        .filter { !progress.found.contains($0.key) }
        .filter { (progress.hints[$0.key] ?? 0) < $0.text.count - 1 }
        .sorted { a, b in
            let aStarted = (progress.hints[a.key] ?? 0) > 0
            let bStarted = (progress.hints[b.key] ?? 0) > 0
            if aStarted != bStarted { return aStarted }
            if a.text.count != b.text.count { return a.text.count < b.text.count }
            return a.key < b.key
        }
    guard let target = candidates.first else { return nil }
    var hints = progress.hints
    hints[target.key] = (hints[target.key] ?? 0) + 1
    return hints
}

public func totalHints(_ progress: Progress) -> Int {
    progress.hints.values.reduce(0, +)
}

public struct WordHint: Equatable {
    public let word: PuzzleWord
    public let count: Int
}

public struct WordRow: Equatable {
    public let length: Int
    public let found: PuzzleWord?
    public let hint: WordHint?
}

/// Rows under the board: one per word, shortest first.
/// Found words fill the first empty row of their length, in the order they were found.
public func wordRows(puzzle: Puzzle, progress: Progress) -> [WordRow] {
    let sorted = puzzle.words.sorted { a, b in
        if a.text.count != b.text.count { return a.text.count < b.text.count }
        return a.key < b.key
    }
    var foundByLength: [Int: [PuzzleWord]] = [:]
    for key in progress.found {
        guard let word = puzzle.words.first(where: { $0.key == key }) else { continue }
        foundByLength[word.text.count, default: []].append(word)
    }
    var hintedByLength: [Int: [PuzzleWord]] = [:]
    for word in sorted {
        if progress.found.contains(word.key) || (progress.hints[word.key] ?? 0) == 0 { continue }
        hintedByLength[word.text.count, default: []].append(word)
    }

    var seen: [Int: Int] = [:]
    return sorted.map { slot in
        let len = slot.text.count
        let idx = seen[len] ?? 0
        seen[len] = idx + 1
        if let found = foundByLength[len]?[safe: idx] {
            return WordRow(length: len, found: found, hint: nil)
        }
        let hintIdx = idx - (foundByLength[len]?.count ?? 0)
        if let hinted = hintedByLength[len]?[safe: hintIdx] {
            return WordRow(length: len, found: nil, hint: WordHint(word: hinted, count: progress.hints[hinted.key] ?? 0))
        }
        return WordRow(length: len, found: nil, hint: nil)
    }
}

public func formatTime(_ ms: Double) -> String {
    let total = Int((ms / 1000).rounded(.down))
    let h = total / 3600
    let m = (total % 3600) / 60
    let s = total % 60
    let mm = String(format: "%02d", m)
    let ss = String(format: "%02d", s)
    return h > 0 ? "\(h):\(mm):\(ss)" : "\(m):\(ss)"
}

public func shareText(number: Int, puzzle: Puzzle, progress: Progress, url: String) -> String {
    let hints = totalHints(progress)
    let misses = progress.missCount
    let lengths = puzzle.words
        .sorted { a, b in
            if a.text.count != b.text.count { return a.text.count < b.text.count }
            return a.key < b.key
        }
        .map { String($0.text.count) }
        .joined(separator: "·")
    let hintLabel = hints == 1 ? "hint" : "hints"
    var missPart = ""
    if misses > 0 {
        missPart = " · \(misses) \(misses == 1 ? "miss" : "misses")"
    }
    let lines = [
        "WordTrace #\(number) solved in \(formatTime(progress.elapsedMs))",
        "\(puzzle.words.count) words (\(lengths)) · \(hints) \(hintLabel)\(missPart)",
        hints == 0 && misses == 0 ? "Flawless trace." : "",
        url,
    ].filter { !$0.isEmpty }
    return lines.joined(separator: "\n")
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
