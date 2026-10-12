import Foundation

/// How far past a tile's centre, in tile widths, the finger must travel before the next neighbour joins the path.
/// Same constant as `STEP_THRESHOLD` in the website's `board.tsx`.
public let stepThreshold = 0.55

/// One orthogonal step toward the finger. Returns nil when the finger has not crossed the threshold.
/// Backtracking onto the previous tile returns the shortened path. Diagonals are never taken:
/// the larger axis wins, and a tie steps horizontally, matching the site.
public func stepToward(
    path: [Int],
    fx: Double,
    fy: Double,
    cols: Int,
    rows: Int,
    canEnter: (Int) -> Bool
) -> [Int]? {
    guard let last = path.last else { return nil }
    let dx = fx - (Double(last % cols) + 0.5)
    let dy = fy - (Double(last / cols) + 0.5)
    let horizontal = abs(dx) >= abs(dy)
    if (horizontal ? abs(dx) : abs(dy)) < stepThreshold { return nil }

    let neighbor: Int
    if horizontal {
        let dir = dx > 0 ? 1 : -1
        let col = last % cols
        if col + dir < 0 || col + dir >= cols { return nil }
        neighbor = last + dir
    } else {
        let dir = dy > 0 ? 1 : -1
        let row = last / cols
        if row + dir < 0 || row + dir >= rows { return nil }
        neighbor = last + dir * cols
    }

    if path.count > 1 && neighbor == path[path.count - 2] {
        return Array(path.dropLast())
    }
    if path.contains(neighbor) || !canEnter(neighbor) { return nil }
    return path + [neighbor]
}

/// Walks one orthogonal tile at a time toward the finger. Never skips or moves diagonally.
/// The finger does not need to sit on the centre of the next tile.
public func extendTrace(
    path: [Int],
    fx: Double,
    fy: Double,
    cols: Int,
    rows: Int,
    canEnter: (Int) -> Bool
) -> [Int] {
    var next = path
    guard !next.isEmpty else { return next }
    for _ in 0..<(cols * rows) {
        guard let stepped = stepToward(path: next, fx: fx, fy: fy, cols: cols, rows: rows, canEnter: canEnter) else {
            return next
        }
        next = stepped
    }
    return next
}
