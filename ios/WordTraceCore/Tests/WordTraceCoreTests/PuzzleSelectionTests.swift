import XCTest
@testable import WordTraceCore

/// Expected puzzle numbers, titles, words, and paths were produced by running
/// `src/lib/puzzles.ts` from https://github.com/ddriqe/origin at
/// e57fe241aab73faac16546bf755ee6f939ddb98c (the site published at
/// https://ddriqe.github.io/origin/). `utcDay` is `Math.floor(Date.UTC(y, m-1, d) / 86400000)`.
final class PuzzleSelectionTests: XCTestCase {
    func testUTCDayNumbersMatchJavaScriptDateUTC() {
        XCTAssertEqual(utcDayNumber(year: 1970, month: 1, day: 1), 0)
        XCTAssertEqual(utcDayNumber(year: 2026, month: 9, day: 30), 20726)
        XCTAssertEqual(utcDayNumber(year: 2026, month: 10, day: 1), 20727)
        XCTAssertEqual(utcDayNumber(year: 2026, month: 10, day: 12), 20738)
        XCTAssertEqual(utcDayNumber(year: 2026, month: 12, day: 31), 20818)
        XCTAssertEqual(utcDayNumber(year: 2027, month: 1, day: 1), 20819)
        XCTAssertEqual(utcDayNumber(year: 2028, month: 2, day: 29), 21243)
        XCTAssertEqual(utcDayNumber(year: 2030, month: 10, day: 1), 22188)
    }

    func testFixedDatesSelectTheSamePuzzleAsTheWebsite() {
        let cases: [(Int, Int, Int, Int, String, [String])] = [
            (2026, 9, 30, 1, "Coffee Break", ["BEAN", "CUPS", "MILK", "SAUCER", "ROAST"]),
            (2026, 10, 1, 1, "Coffee Break", ["BEAN", "CUPS", "MILK", "SAUCER", "ROAST"]),
            (2026, 10, 2, 2, "In the Garden", ["SEEDS", "BLOOM", "LEAF", "RAKE", "PLANT"]),
            (2026, 10, 3, 3, "Nine to Five", ["DESK", "EMAIL", "TASK", "MEMO", "JOB", "FAX"]),
            (2026, 10, 4, 4, "Forecast", ["SHOWER", "RAIN", "HAIL", "GUST", "CLOUD"]),
            (2026, 10, 6, 6, "Kitchen Shift", ["SKILLET", "BUTTER", "WHISK", "PEPPER", "GARLIC", "POT"]),
            (2026, 10, 7, 7, "Low Tide", ["CORAL", "TIDE", "REEF", "WAVE", "SEA", "EEL"]),
            (2026, 10, 8, 8, "Coffee Break", ["BEAN", "CUPS", "MILK", "SAUCER", "ROAST"]),
            (2026, 10, 12, 12, "Out of Office", ["TICKET", "ISLAND", "HOTEL", "JOURNEY", "BEACH", "MAPS"]),
            (2026, 12, 31, 92, "Coffee Break", ["BEAN", "CUPS", "MILK", "SAUCER", "ROAST"]),
            (2027, 1, 1, 93, "In the Garden", ["SEEDS", "BLOOM", "LEAF", "RAKE", "PLANT"]),
            (2027, 1, 15, 107, "In the Garden", ["SEEDS", "BLOOM", "LEAF", "RAKE", "PLANT"]),
            (2028, 2, 29, 517, "Kitchen Shift", ["SKILLET", "BUTTER", "WHISK", "PEPPER", "GARLIC", "POT"]),
            (2030, 10, 1, 1462, "Kitchen Shift", ["SKILLET", "BUTTER", "WHISK", "PEPPER", "GARLIC", "POT"]),
        ]

        for (year, month, day, number, title, words) in cases {
            XCTAssertEqual(puzzleNumber(year: year, month: month, day: day), number, "\(year)-\(month)-\(day)")
            let puzzle = puzzle(for: number)
            XCTAssertEqual(puzzle.title, title, "\(year)-\(month)-\(day)")
            XCTAssertEqual(puzzle.words.map(\.text), words, "\(year)-\(month)-\(day)")
        }
    }

    func testSolutionPathsMatchTheWebsite() {
        let expected: [(String, [[Int]])] = [
            ("Coffee Break", [[0, 1, 2, 3], [4, 9, 14, 13], [5, 6, 7, 12], [11, 10, 15, 20, 21, 22], [17, 18, 19, 24, 23]]),
            ("In the Garden", [[1, 0, 5, 10, 15], [3, 4, 9, 14, 19], [6, 7, 8, 13], [11, 16, 21, 20], [22, 17, 18, 23, 24]]),
            ("Nine to Five", [[0, 1, 2, 7], [3, 8, 9, 14, 19], [6, 5, 10, 15], [11, 12, 13, 18], [17, 16, 21], [22, 23, 24]]),
            ("Forecast", [[0, 1, 2, 7, 12, 11], [4, 3, 8, 13], [5, 10, 15, 20], [9, 14, 19, 24], [17, 16, 21, 22, 23]]),
            ("Out of Office", [[12, 6, 0, 1, 2, 3], [4, 5, 11, 17, 23, 29], [10, 9, 8, 14, 13], [15, 16, 22, 28, 27, 26, 20], [19, 18, 24, 30, 31], [32, 33, 34, 35]]),
            ("Kitchen Shift", [[6, 0, 1, 2, 3, 4, 10], [11, 17, 23, 29, 35, 34], [7, 8, 9, 15, 16], [12, 13, 19, 20, 21, 22], [18, 24, 25, 31, 32, 33], [26, 27, 28]]),
            ("Low Tide", [[0, 1, 2, 3, 8], [4, 9, 14, 13], [5, 6, 7, 12], [11, 16, 15, 20], [17, 18, 19], [21, 22, 23]]),
        ]

        XCTAssertEqual(puzzles.count, expected.count)
        for (puzzle, item) in zip(puzzles, expected) {
            XCTAssertEqual(puzzle.title, item.0)
            XCTAssertEqual(puzzle.words.map(\.path), item.1, puzzle.title)
            for word in puzzle.words {
                XCTAssertEqual(spell(puzzle, path: word.path), word.text, word.text)
                assertOrthogonal(word.path, cols: puzzle.cols, title: word.text)
            }
        }
    }

    func testPuzzleNumberUsesTheLocalCalendarNotUTC() throws {
        let newYork = try XCTUnwrap(TimeZone(identifier: "America/New_York"))
        let utc = try XCTUnwrap(TimeZone(secondsFromGMT: 0))
        // 2026-10-12 02:00 UTC is still 11 October in New York (EDT, UTC-4).
        let instant = Date(timeIntervalSince1970: Double(utcDayNumber(year: 2026, month: 10, day: 12)) * 86_400 + 2 * 3_600)
        XCTAssertEqual(puzzleNumber(for: instant, timeZone: utc), 12)
        XCTAssertEqual(puzzleNumber(for: instant, timeZone: newYork), 11)
        XCTAssertEqual(puzzle(for: 12).title, "Out of Office")
        XCTAssertEqual(puzzle(for: 11).title, "Forecast")
    }

    func testDateForPuzzleNumberRoundTrips() {
        XCTAssertEqual(dateComponents(forPuzzleNumber: 1).year, 2026)
        XCTAssertEqual(dateComponents(forPuzzleNumber: 1).month, 10)
        XCTAssertEqual(dateComponents(forPuzzleNumber: 1).day, 1)
        let oct12 = dateComponents(forPuzzleNumber: 12)
        XCTAssertEqual(oct12.year, 2026)
        XCTAssertEqual(oct12.month, 10)
        XCTAssertEqual(oct12.day, 12)
        let leap = dateComponents(forPuzzleNumber: 517)
        XCTAssertEqual(leap.year, 2028)
        XCTAssertEqual(leap.month, 2)
        XCTAssertEqual(leap.day, 29)
    }

    private func assertOrthogonal(_ path: [Int], cols: Int, title: String) {
        for pair in zip(path, path.dropFirst()) {
            let dr = abs(pair.0 / cols - pair.1 / cols)
            let dc = abs(pair.0 % cols - pair.1 % cols)
            XCTAssertEqual(dr + dc, 1, "\(title) step \(pair.0)->\(pair.1) is not orthogonal")
        }
    }
}
