import Foundation

// Daily rotation and puzzle list copied from the website source of truth:
// https://github.com/ddriqe/origin/blob/e57fe241aab73faac16546bf755ee6f939ddb98c/src/lib/puzzles.ts
//
// Puzzle #1 is the board for 1 October 2026 in the player's local calendar.
// Each following local date unlocks the next board. After the last board, the
// list repeats in the same order the site uses: (number - 1) % count.
// Walls (`#`) are part of the published boards. Traces cannot enter them.

public struct PuzzleWord: Equatable {
    public let key: String
    public let text: String
    /// Cell indices (row * cols + col) in the order the word is traced.
    public let path: [Int]
    public let colorIndex: Int
}

public struct Puzzle: Equatable {
    public let title: String
    public let rows: Int
    public let cols: Int
    /// Letter per cell, or nil for a wall.
    public let cells: [Character?]
    public let words: [PuzzleWord]
}

struct RawPuzzle {
    let title: String
    let letters: [String]
    let regions: [String]
    let words: [String: String]
}

let rawPuzzles: [RawPuzzle] = [
    RawPuzzle(
        title: "Coffee Break",
        letters: ["BEANC", "MIL#U", "ASKSP", "U#ROA", "CERTS"],
        regions: ["aaaab", "ccc#b", "ddcbb", "d#eee", "dddee"],
        words: ["a": "BEAN", "b": "CUPS", "c": "MILK", "d": "SAUCER", "e": "ROAST"]
    ),
    RawPuzzle(
        title: "In the Garden",
        letters: ["ES#BL", "ELEAO", "DR#FO", "SALAM", "EKPNT"],
        regions: ["aa#bb", "acccb", "ad#cb", "adeeb", "ddeee"],
        words: ["a": "SEEDS", "b": "BLOOM", "c": "LEAF", "d": "RAKE", "e": "PLANT"]
    ),
    RawPuzzle(
        title: "Nine to Five",
        letters: ["DESE#", "ATKMA", "SMEMI", "KOJOL", "#BFAX"],
        regions: ["aaab#", "ccabb", "cdddb", "ceedb", "#efff"],
        words: ["a": "DESK", "b": "EMAIL", "c": "TASK", "d": "MEMO", "e": "JOB", "f": "FAX"]
    ),
    RawPuzzle(
        title: "Forecast",
        letters: ["SHOAR", "H#WIG", "ARENU", "ILC#S", "LOUDT"],
        regions: ["aaabb", "c#abd", "caabd", "cee#d", "ceeed"],
        words: ["a": "SHOWER", "b": "RAIN", "c": "HAIL", "d": "GUST", "e": "CLOUD"]
    ),
    RawPuzzle(
        title: "Out of Office",
        letters: ["CKETIS", "I#TOHL", "TLEJOA", "EBY#UN", "A#ENRD", "CHMAPS"],
        regions: ["aaaabb", "a#cccb", "accddb", "eed#db", "e#dddb", "eeffff"],
        words: ["a": "TICKET", "b": "ISLAND", "c": "HOTEL", "d": "JOURNEY", "e": "BEACH", "f": "MAPS"]
    ),
    RawPuzzle(
        title: "Kitchen Shift",
        letters: ["KILLE#", "SWHITB", "PE#SKU", "GPPERT", "ARPOTT", "#LICRE"],
        regions: ["aaaaa#", "acccab", "dd#ccb", "eddddb", "eefffb", "#eeebb"],
        words: ["a": "SKILLET", "b": "BUTTER", "c": "WHISK", "d": "PEPPER", "e": "GARLIC", "f": "POT"]
    ),
    RawPuzzle(
        title: "Low Tide",
        letters: ["CORAT", "REELI", "#WFED", "VASEA", "EEEL#"],
        regions: ["aaaab", "cccab", "#dcbb", "ddeee", "dfff#"],
        words: ["a": "CORAL", "b": "TIDE", "c": "REEF", "d": "WAVE", "e": "SEA", "f": "EEL"]
    ),
]

func neighbors(_ index: Int, rows: Int, cols: Int) -> [Int] {
    let r = index / cols
    let c = index % cols
    var out: [Int] = []
    if r > 0 { out.append(index - cols) }
    if r < rows - 1 { out.append(index + cols) }
    if c > 0 { out.append(index - 1) }
    if c < cols - 1 { out.append(index + 1) }
    return out
}

/// Finds the path through every tile of a region that spells `word`.
/// Start tiles are tried in row-major insertion order, and each step tries
/// up, down, left, then right, matching the website's search.
func findRegionPath(
    word: String,
    regionOrder: [Int],
    region: Set<Int>,
    cells: [Character?],
    rows: Int,
    cols: Int
) -> [Int]? {
    let letters = Array(word)
    func dfs(path: [Int], used: inout Set<Int>) -> [Int]? {
        if path.count == letters.count { return path }
        let last = path[path.count - 1]
        let expected = letters[path.count]
        for next in neighbors(last, rows: rows, cols: cols) {
            if !region.contains(next) || used.contains(next) { continue }
            if cells[next] != expected { continue }
            used.insert(next)
            if let found = dfs(path: path + [next], used: &used) { return found }
            used.remove(next)
        }
        return nil
    }

    for start in regionOrder {
        if cells[start] != letters.first { continue }
        var used: Set<Int> = [start]
        if let found = dfs(path: [start], used: &used) { return found }
    }
    return nil
}

func parsePuzzle(_ raw: RawPuzzle) throws -> Puzzle {
    let rows = raw.letters.count
    let cols = raw.letters[0].count
    if raw.regions.count != rows {
        throw PuzzleParseError.message("\(raw.title): region rows mismatch")
    }

    var cells: [Character?] = []
    var regionOrder: [String: [Int]] = [:]
    var regionSets: [String: Set<Int>] = [:]

    for (r, line) in raw.letters.enumerated() {
        let regionLine = raw.regions[r]
        if line.count != cols || regionLine.count != cols {
            throw PuzzleParseError.message("\(raw.title): row \(r) has the wrong width")
        }
        let letters = Array(line)
        let regions = Array(regionLine)
        for c in 0..<cols {
            let ch = letters[c]
            let region = regions[c]
            if (ch == "#") != (region == "#") {
                throw PuzzleParseError.message("\(raw.title): wall mismatch at \(r),\(c)")
            }
            if ch == "#" {
                cells.append(nil)
                continue
            }
            cells.append(ch)
            let index = r * cols + c
            regionOrder[String(region), default: []].append(index)
            regionSets[String(region), default: []].insert(index)
        }
    }

    let keys = raw.words.keys.sorted()
    let regionKeys = regionSets.keys.sorted()
    if keys != regionKeys {
        throw PuzzleParseError.message("\(raw.title): word keys \(keys) do not match regions \(regionKeys)")
    }

    var words: [PuzzleWord] = []
    for (i, key) in keys.enumerated() {
        let text = raw.words[key]!
        let region = regionSets[key]!
        let order = regionOrder[key]!
        if region.count != text.count {
            throw PuzzleParseError.message("\(raw.title): \"\(text)\" has \(text.count) letters but region \(key) has \(region.count) tiles")
        }
        guard let path = findRegionPath(word: text, regionOrder: order, region: region, cells: cells, rows: rows, cols: cols) else {
            throw PuzzleParseError.message("\(raw.title): cannot trace \"\(text)\" through region \(key)")
        }
        words.append(PuzzleWord(key: key, text: text, path: path, colorIndex: i))
    }

    return Puzzle(title: raw.title, rows: rows, cols: cols, cells: cells, words: words)
}

enum PuzzleParseError: Error, CustomStringConvertible {
    case message(String)
    var description: String {
        switch self {
        case .message(let text): return text
        }
    }
}

public let puzzles: [Puzzle] = {
    do {
        return try rawPuzzles.map(parsePuzzle)
    } catch {
        fatalError("Bundled puzzle failed to parse: \(error)")
    }
}()

public let launchYear = 2026
public let launchMonth = 10
public let launchDay = 1

/// Days since Unix epoch for a Gregorian UTC date. Matches `Math.floor(Date.UTC(y, m - 1, d) / 86_400_000)`.
public func utcDayNumber(year: Int, month: Int, day: Int) -> Int {
    daysFromCivil(year: year, month: month, day: day)
}

/// Howard Hinnant's `days_from_civil`. Day 0 is 1970-01-01.
func daysFromCivil(year: Int, month: Int, day: Int) -> Int {
    var y = year
    y -= month <= 2 ? 1 : 0
    let era = (y >= 0 ? y : y - 399) / 400
    let yoe = y - era * 400
    let doy = (153 * (month + (month > 2 ? -3 : 9)) + 2) / 5 + day - 1
    let doe = yoe * 365 + yoe / 4 - yoe / 100 + doy
    return era * 146097 + doe - 719468
}

public func civilFromDays(_ z0: Int) -> (year: Int, month: Int, day: Int) {
    let z = z0 + 719468
    let era = (z >= 0 ? z : z - 146096) / 146097
    let doe = z - era * 146097
    let yoe = (doe - doe / 1460 + doe / 36524 - doe / 146096) / 365
    let y = yoe + era * 400
    let doy = doe - (365 * yoe + yoe / 4 - yoe / 100)
    let mp = (5 * doy + 2) / 153
    let d = doy - (153 * mp + 2) / 5 + 1
    let m = mp < 10 ? mp + 3 : mp - 9
    return (y + (m <= 2 ? 1 : 0), m, d)
}

/// Puzzle number for a local calendar date. Dates before launch stay on puzzle 1.
public func puzzleNumber(year: Int, month: Int, day: Int) -> Int {
    let today = utcDayNumber(year: year, month: month, day: day)
    let launch = utcDayNumber(year: launchYear, month: launchMonth, day: launchDay)
    return max(1, today - launch + 1)
}

/// Local Gregorian calendar date, matching `date.getFullYear/getMonth/getDate` on the website.
public func puzzleNumber(for date: Date, timeZone: TimeZone = .current) -> Int {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = timeZone
    return puzzleNumber(
        year: calendar.component(.year, from: date),
        month: calendar.component(.month, from: date),
        day: calendar.component(.day, from: date)
    )
}

public func dateComponents(forPuzzleNumber n: Int) -> (year: Int, month: Int, day: Int) {
    let launch = utcDayNumber(year: launchYear, month: launchMonth, day: launchDay)
    return civilFromDays(launch + n - 1)
}

public func puzzle(for number: Int) -> Puzzle {
    let count = puzzles.count
    let index = ((number - 1) % count + count) % count
    return puzzles[index]
}

public func isPalindrome(_ word: String) -> Bool {
    let chars = Array(word)
    return chars == chars.reversed()
}

public enum WordTraceSite {
    public static func puzzleURL(number: Int) -> String {
        "https://ddriqe.github.io/origin/?n=\(number)"
    }
}
