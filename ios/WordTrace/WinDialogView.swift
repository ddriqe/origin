import SwiftUI
import WordTraceCore

struct WinDialogView: View {
    let number: Int
    let puzzle: Puzzle
    let progress: Progress
    let isToday: Bool
    var onClose: () -> Void
    var onPrevious: (() -> Void)?

    var body: some View {
        let hints = totalHints(progress)
        let flawless = hints == 0 && progress.missCount == 0
        ZStack {
            Color.black.opacity(0.35)
                .ignoresSafeArea()
                .onTapGesture(perform: onClose)
            VStack(spacing: 16) {
                Image(systemName: "checkmark")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(Theme.emerald700)
                    .frame(width: 48, height: 48)
                    .background(Circle().fill(Color(hex: 0xD1FAE5)))

                VStack(spacing: 4) {
                    Text(flawless ? "Flawless trace!" : "Board cleared!")
                        .font(Theme.outfit(24, "Outfit-ExtraBold"))
                        .foregroundStyle(Theme.ink)
                    Text("You solved WordTrace #\(number), “\(puzzle.title)”.")
                        .font(.subheadline)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(Theme.stone500)
                }

                HStack(spacing: 8) {
                    stat(icon: "clock", value: formatTime(progress.elapsedMs), label: "Time")
                    stat(icon: "lightbulb", value: "\(hints)", label: "Hints")
                    stat(icon: "xmark", value: "\(progress.missCount)", label: "Misses")
                }

                FlowWords(words: puzzle.words)

                Text(isToday ? "A fresh board unlocks at midnight." : "Nice work on the archive puzzle.")
                    .font(.subheadline)
                    .foregroundStyle(Theme.stone500)
                    .multilineTextAlignment(.center)

                ShareLink(item: shareText(number: number, puzzle: puzzle, progress: progress, url: WordTraceSite.puzzleURL(number: number))) {
                    Label("Share result", systemImage: "square.and.arrow.up")
                        .font(Theme.outfit(17, "Outfit-Bold"))
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(Theme.indigo, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .foregroundStyle(.white)
                }

                if let onPrevious {
                    Button(action: onPrevious) {
                        Text("Play the previous day")
                            .font(Theme.outfit(17, "Outfit-SemiBold"))
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                            .background(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .stroke(Theme.stone300, lineWidth: 1)
                            )
                            .foregroundStyle(Theme.ink)
                    }
                }
            }
            .padding(20)
            .background(Color.white, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .padding(.horizontal, 20)
        }
    }

    private func stat(icon: String, value: String, label: String) -> some View {
        VStack(spacing: 2) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(Theme.stone500)
            Text(value)
                .font(Theme.outfit(18, "Outfit-Bold"))
                .foregroundStyle(Theme.ink)
                .monospacedDigit()
            Text(label)
                .font(.caption)
                .foregroundStyle(Theme.stone500)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(Color(hex: 0xF5F5F4), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

private struct FlowWords: View {
    let words: [PuzzleWord]

    var body: some View {
        WrappingHStack(spacing: 6) {
            ForEach(words, id: \.key) { word in
                let tone = Theme.tone(word.colorIndex)
                Text(word.text)
                    .font(Theme.outfit(12, "Outfit-Bold"))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(tone.tile, in: RoundedRectangle(cornerRadius: 6, style: .continuous))
                    .foregroundStyle(tone.ink)
            }
        }
    }
}

/// Centers a run of chips, wrapping when the row is full.
private struct WrappingHStack<Content: View>: View {
    var spacing: CGFloat
    @ViewBuilder var content: Content

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: spacing) { content }
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 64), spacing: spacing)], spacing: spacing) {
                content
            }
        }
    }
}
