import XCTest
@testable import WordTraceCore

final class TraceRulesTests: XCTestCase {
    private var coffee: Puzzle { puzzle(for: 1) }

    func testFingerExtendsToTheNextTileBeforeItsCentre() {
        let open: (Int) -> Bool = { _ in true }
        // Cell 0's centre is (0.5, 0.5). The boundary with cell 1 is x = 1.
        // 0.55 tile-widths past the centre is x = 1.05, still on the left edge of cell 1, not its centre (1.5).
        let stepped = extendTrace(path: [0], fx: 1.05, fy: 0.5, cols: 5, rows: 5, canEnter: open)
        XCTAssertEqual(stepped, [0, 1])

        let short = extendTrace(path: [0], fx: 1.04, fy: 0.5, cols: 5, rows: 5, canEnter: open)
        XCTAssertEqual(short, [0])
    }

    func testDiagonalFingerPicksTheStrongerAxisAndWallsBlock() {
        let open: (Int) -> Bool = { _ in true }
        // The stronger axis wins. Past the threshold adds that neighbour, not a diagonal.
        let horizontal = extendTrace(path: [6], fx: 2.10, fy: 1.60, cols: 5, rows: 5, canEnter: open)
        XCTAssertEqual(horizontal, [6, 7])

        // A finger farther down the diagonal keeps walking one orthogonal tile at a time.
        // It must not jump from cell 6 straight to cell 12.
        let stepped = extendTrace(path: [6], fx: 1.5 + 0.8, fy: 1.5 + 0.8, cols: 5, rows: 5, canEnter: open)
        XCTAssertEqual(stepped, [6, 7, 12])
        XCTAssertNotEqual(stepped, [6, 12])

        let vertical = extendTrace(path: [6], fx: 1.70, fy: 2.20, cols: 5, rows: 5, canEnter: open)
        XCTAssertEqual(vertical, [6, 11])

        // Coffee Break wall at index 8 (row 1, col 3).
        let cells = coffee.cells
        let wall: (Int) -> Bool = { cells[$0] != nil }
        let blocked = extendTrace(path: [7], fx: 3.5, fy: 1.5, cols: 5, rows: 5, canEnter: wall)
        XCTAssertEqual(blocked, [7])
    }

    func testBacktrackPopsThePreviousTile() {
        let open: (Int) -> Bool = { _ in true }
        let back = extendTrace(path: [0, 1], fx: 0.4, fy: 0.5, cols: 5, rows: 5, canEnter: open)
        XCTAssertEqual(back, [0])
    }

    func testCanonicalPathIsAcceptedAndAShortOrReversedTraceIsNot() {
        let bean = coffee.words[0]
        XCTAssertEqual(bean.text, "BEAN")
        let found = evaluateTrace(puzzle: coffee, progress: .empty(), path: bean.path)
        XCTAssertEqual(found, .found(bean))

        var progress = Progress.empty()
        progress.found = [bean.key]
        XCTAssertEqual(evaluateTrace(puzzle: coffee, progress: progress, path: bean.path), .alreadyFound(bean))
        XCTAssertEqual(evaluateTrace(puzzle: coffee, progress: .empty(), path: [0, 1]), .tooShort)
        if case .notAWord(let text) = evaluateTrace(puzzle: coffee, progress: .empty(), path: Array(bean.path.reversed())) {
            XCTAssertEqual(text, "NAEB")
        } else {
            XCTFail("reversed BEAN should miss")
        }
    }

    func testHintOrderAndWordRowsMatchTheSite() {
        var progress = Progress.empty()
        let first = nextHint(puzzle: coffee, progress: progress)
        XCTAssertEqual(first, ["a": 1])
        progress.hints = first!
        XCTAssertEqual(nextHint(puzzle: coffee, progress: progress), ["a": 2])

        progress.found = ["c"]
        let rows = wordRows(puzzle: coffee, progress: progress)
        XCTAssertEqual(rows.map(\.length), [4, 4, 4, 5, 6])
        XCTAssertEqual(rows[0].found?.text, "MILK")
        XCTAssertNil(rows[1].found)
    }
}
