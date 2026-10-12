import SwiftUI
import WordTraceCore

struct WordRowsView: View {
    let puzzle: Puzzle
    let progress: Progress

    var body: some View {
        let rows = wordRows(puzzle: puzzle, progress: progress)
        let maxLen = rows.map(\.length).max() ?? 1
        let cell: CGFloat = rows.count >= 6 ? 22 : 26
        let gap: CGFloat = 4
        let width = CGFloat(maxLen) * cell + CGFloat(max(maxLen - 1, 0)) * gap

        VStack(spacing: 6) {
            ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                HStack(spacing: gap) {
                    ForEach(0..<row.length, id: \.self) { index in
                        cellView(row: row, index: index, side: cell)
                    }
                    Spacer(minLength: 0)
                }
                .frame(width: width, alignment: .leading)
                .accessibilityLabel(label(for: row))
            }
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Words to find")
    }

    private func cellView(row: WordRow, index: Int, side: CGFloat) -> some View {
        let letter = letter(row: row, index: index)
        let tone = row.found.map { Theme.tone($0.colorIndex) }
        return Text(letter)
            .font(Theme.outfit(side * 0.46, "Outfit-Bold"))
            .foregroundStyle(tone?.ink ?? Theme.hintLetter)
            .frame(width: side, height: side)
            .background(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(tone?.tile ?? Color.white.opacity(0.6))
            )
            .overlay {
                if tone == nil {
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .stroke(Theme.stone300, style: StrokeStyle(lineWidth: 1, dash: [3, 3]))
                }
            }
    }

    private func letter(row: WordRow, index: Int) -> String {
        if let found = row.found {
            let chars = Array(found.text)
            return String(chars[index])
        }
        if let hint = row.hint, index < hint.count {
            let chars = Array(hint.word.text)
            return String(chars[index])
        }
        return ""
    }

    private func label(for row: WordRow) -> String {
        if let found = row.found { return "Found: \(found.text)" }
        return "\(row.length)-letter word"
    }
}
