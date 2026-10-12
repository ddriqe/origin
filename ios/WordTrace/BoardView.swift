import SwiftUI
import UIKit
import WordTraceCore

struct BoardView: View {
    let puzzle: Puzzle
    let progress: Progress
    var disabled = false
    var shakeKey = 0
    var onCommit: ([Int]) -> Void
    var onTraceStart: () -> Void

    @State private var trace: [Int] = []
    @State private var tracing = false
    @State private var gestureClaimed = false
    @State private var shakeOffset: CGFloat = 0

    var body: some View {
        GeometryReader { geo in
            let layout = BoardLayout(size: geo.size, cols: puzzle.cols, rows: puzzle.rows)
            ZStack {
                pipeLayer(layout)
                tileLayer(layout)
            }
            .contentShape(Rectangle())
            .gesture(drag(layout))
        }
        .offset(x: shakeOffset)
        .onChange(of: shakeKey) { _, key in
            guard key > 0 else { return }
            playShake()
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Letter grid")
    }

    private var locked: [Int: PuzzleWord] {
        lockedCells(puzzle: puzzle, progress: progress)
    }

    private func drag(_ layout: BoardLayout) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                if !gestureClaimed {
                    gestureClaimed = true
                    guard !disabled, let cell = layout.cell(at: value.startLocation), canEnter(cell) else { return }
                    tracing = true
                    onTraceStart()
                    trace = [cell]
                }
                guard tracing else { return }
                let point = layout.fraction(value.location)
                let next = extendTrace(
                    path: trace,
                    fx: point.x,
                    fy: point.y,
                    cols: puzzle.cols,
                    rows: puzzle.rows,
                    canEnter: canEnter
                )
                if next != trace { trace = next }
            }
            .onEnded { _ in
                let path = trace
                let wasTracing = tracing
                trace = []
                tracing = false
                gestureClaimed = false
                guard wasTracing else { return }
                if path.count > 1 { onCommit(path) }
            }
    }

    private func canEnter(_ cell: Int) -> Bool {
        puzzle.cells[cell] != nil && locked[cell] == nil
    }

    private func pipeLayer(_ layout: BoardLayout) -> some View {
        Canvas { context, _ in
            for path in progress.misses where path.count > 1 {
                stroke(path, in: &context, layout: layout, color: Theme.missPipe, width: layout.cell * 0.22, dashed: true)
            }
            for key in progress.found {
                guard let word = puzzle.words.first(where: { $0.key == key }), word.path.count > 1 else { continue }
                stroke(word.path, in: &context, layout: layout, color: Theme.tone(word.colorIndex).pipe, width: layout.cell * 0.30, dashed: false)
            }
            if trace.count > 1 {
                stroke(trace, in: &context, layout: layout, color: Theme.tracePipe, width: layout.cell * 0.30, dashed: false)
            }
        }
        .allowsHitTesting(false)
    }

    private func stroke(
        _ path: [Int],
        in context: inout GraphicsContext,
        layout: BoardLayout,
        color: Color,
        width: CGFloat,
        dashed: Bool
    ) {
        var line = Path()
        for (index, cell) in path.enumerated() {
            let point = layout.center(of: cell)
            if index == 0 { line.move(to: point) } else { line.addLine(to: point) }
        }
        var style = StrokeStyle(lineWidth: width, lineCap: .round, lineJoin: .round)
        if dashed {
            style.dash = [layout.cell * 0.08, layout.cell * 0.12]
        }
        context.stroke(line, with: .color(color), style: style)
    }

    private func tileLayer(_ layout: BoardLayout) -> some View {
        let traceSet = Set(trace)
        var missSet = Set<Int>()
        for path in progress.misses { missSet.formUnion(path) }
        let hints = hintCells()

        return ZStack {
            ForEach(0..<(puzzle.rows * puzzle.cols), id: \.self) { index in
                let origin = layout.origin(of: index)
                tile(
                    index: index,
                    side: layout.tile,
                    inTrace: traceSet.contains(index),
                    isMiss: missSet.contains(index) && !traceSet.contains(index),
                    word: locked[index],
                    hint: hints[index]
                )
                .frame(width: layout.tile, height: layout.tile)
                .position(x: origin.x + layout.cell / 2, y: origin.y + layout.cell / 2)
            }
        }
        .allowsHitTesting(false)
    }

    private func hintCells() -> [Int: Int] {
        var map: [Int: Int] = [:]
        for word in puzzle.words {
            if progress.found.contains(word.key) { continue }
            let count = progress.hints[word.key] ?? 0
            for (offset, cell) in word.path.prefix(count).enumerated() {
                map[cell] = offset + 1
            }
        }
        return map
    }

    @ViewBuilder
    private func tile(index: Int, side: CGFloat, inTrace: Bool, isMiss: Bool, word: PuzzleWord?, hint: Int?) -> some View {
        let radius = side * 0.22
        if puzzle.cells[index] == nil {
            WallTile()
                .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
                .accessibilityLabel("Wall")
        } else {
            let letter = String(puzzle.cells[index]!)
            ZStack(alignment: .topTrailing) {
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .fill(fill(inTrace: inTrace, isMiss: isMiss, word: word))
                    .overlay {
                        if isMiss {
                            RoundedRectangle(cornerRadius: radius, style: .continuous)
                                .stroke(Theme.missPipe, style: StrokeStyle(lineWidth: 2, dash: [3, 3]))
                        }
                    }
                    .shadow(color: shadow(inTrace: inTrace, word: word), radius: inTrace ? 8 : 0, y: inTrace ? 4 : 1)
                Text(letter)
                    .font(Theme.outfit(side * 0.52, "Outfit-Bold"))
                    .foregroundStyle(ink(inTrace: inTrace, isMiss: isMiss, word: word))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                if let hint, word == nil, !inTrace {
                    Text("\(hint)")
                        .font(Theme.outfit(side * 0.22, "Outfit-Bold"))
                        .foregroundStyle(Theme.amberInk)
                        .frame(width: side * 0.28, height: side * 0.28)
                        .background(Circle().fill(Theme.amber))
                        .padding(side * 0.06)
                }
            }
            .scaleEffect(inTrace ? 1.04 : 1)
            .animation(.easeOut(duration: 0.15), value: inTrace)
            .accessibilityLabel(letter)
        }
    }

    private func fill(inTrace: Bool, isMiss: Bool, word: PuzzleWord?) -> Color {
        if inTrace { return Theme.traceTile }
        if let word { return Theme.tone(word.colorIndex).tile }
        if isMiss { return Theme.missTile }
        return .white
    }

    private func ink(inTrace: Bool, isMiss: Bool, word: PuzzleWord?) -> Color {
        if inTrace { return Theme.traceInk }
        if let word { return Theme.tone(word.colorIndex).ink }
        if isMiss { return Theme.missInk }
        return Theme.stone800
    }

    private func shadow(inTrace: Bool, word: PuzzleWord?) -> Color {
        if word != nil { return .clear }
        if inTrace { return Theme.traceTile.opacity(0.35) }
        return Color(hex: 0x786450, opacity: 0.18)
    }

    private func playShake() {
        guard !UIAccessibility.isReduceMotionEnabled else { return }
        let steps: [CGFloat] = [-6, 6, -4, 4, 0]
        for (index, value) in steps.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.08 * Double(index)) {
                withAnimation(.easeInOut(duration: 0.08)) {
                    shakeOffset = value
                }
            }
        }
    }
}

struct BoardLayout {
    let size: CGSize
    let cols: Int
    let rows: Int

    var cell: CGFloat { size.width / CGFloat(cols) }
    var tile: CGFloat { cell * 0.86 }

    func origin(of index: Int) -> CGPoint {
        let col = index % cols
        let row = index / cols
        return CGPoint(x: CGFloat(col) * cell, y: CGFloat(row) * cell)
    }

    func center(of index: Int) -> CGPoint {
        let origin = origin(of: index)
        return CGPoint(x: origin.x + cell / 2, y: origin.y + cell / 2)
    }

    func fraction(_ point: CGPoint) -> (x: Double, y: Double) {
        (Double(point.x / cell), Double(point.y / (size.height / CGFloat(rows))))
    }

    func cell(at point: CGPoint) -> Int? {
        let point = fraction(point)
        let c = Int(point.x.rounded(.down))
        let r = Int(point.y.rounded(.down))
        guard c >= 0, r >= 0, c < cols, r < rows else { return nil }
        return r * cols + c
    }
}

private struct WallTile: View {
    var body: some View {
        Canvas { context, size in
            context.fill(Path(CGRect(origin: .zero, size: size)), with: .color(Theme.wallDark))
            let span = size.width + size.height
            var start: CGFloat = -size.height
            while start < span {
                var band = Path()
                band.move(to: CGPoint(x: start, y: 0))
                band.addLine(to: CGPoint(x: start + size.height, y: size.height))
                band.addLine(to: CGPoint(x: start + size.height + 4, y: size.height))
                band.addLine(to: CGPoint(x: start + 4, y: 0))
                band.closeSubpath()
                context.fill(band, with: .color(Theme.wallLight))
                start += 8
            }
        }
    }
}
