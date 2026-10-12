import SwiftUI
import WordTraceCore

struct GameView: View {
    @StateObject private var model = GameModel()
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            VStack(spacing: 8) {
                header
                dateBar
                stats
                boardSlot
                    .layoutPriority(1)
                if model.progress.completed {
                    solvedBanner
                }
                controls
                WordRowsView(puzzle: model.puzzle, progress: model.progress)
            }
            .padding(.horizontal, 16)
            .padding(.top, 4)
            .padding(.bottom, 8)

            if let toast = model.toast {
                VStack {
                    toastBanner(toast)
                        .padding(.top, 8)
                        .padding(.horizontal, 16)
                    Spacer()
                }
                .transition(.move(edge: .top).combined(with: .opacity))
            }

            if model.helpOpen {
                HowToPlayView { model.dismissHelp() }
            }
            if model.winOpen {
                WinDialogView(
                    number: model.number,
                    puzzle: model.puzzle,
                    progress: model.progress,
                    isToday: model.isToday,
                    onClose: { model.winOpen = false },
                    onPrevious: model.number > 1 ? {
                        model.winOpen = false
                        model.selectPuzzle(model.number - 1)
                    } : nil
                )
            }
        }
        .animation(.easeOut(duration: 0.2), value: model.toast?.id)
        .onChange(of: scenePhase) { _, phase in
            model.setSceneActive(phase == .active)
        }
    }

    private var header: some View {
        HStack(spacing: 8) {
            LogoView(side: 36)
            VStack(alignment: .leading, spacing: 0) {
                Text("WordTrace")
                    .font(Theme.outfit(20, "Outfit-ExtraBold"))
                    .foregroundStyle(Theme.ink)
                Text("A daily word-path puzzle")
                    .font(.caption)
                    .foregroundStyle(Theme.stone500)
            }
            Spacer()
            if model.progress.completed {
                ShareLink(item: model.shareMessage()) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(Theme.stone700)
                        .frame(width: 36, height: 36)
                }
                .accessibilityLabel("Share result")
            }
            Button {
                model.helpOpen = true
            } label: {
                Image(systemName: "questionmark.circle")
                    .font(.system(size: 22, weight: .regular))
                    .foregroundStyle(Theme.stone700)
                    .frame(width: 36, height: 36)
            }
            .accessibilityLabel("How to play")
        }
    }

    private var dateBar: some View {
        HStack {
            arrow("Previous puzzle", systemName: "chevron.left", enabled: model.number > 1) {
                model.selectPuzzle(model.number - 1)
            }
            Spacer(minLength: 4)
            VStack(spacing: 2) {
                HStack(spacing: 6) {
                    Text("#\(model.number) · \(model.puzzle.title)")
                        .font(Theme.outfit(16, "Outfit-Bold"))
                        .foregroundStyle(Theme.ink)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    Text(model.isToday ? "Today" : "Archive")
                        .font(.caption2.weight(.bold))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(model.isToday ? Theme.indigo : Theme.stone200, in: Capsule())
                        .foregroundStyle(model.isToday ? Color.white : Theme.stone700)
                }
                Text(dateLabel)
                    .font(.caption)
                    .foregroundStyle(Theme.stone500)
            }
            Spacer(minLength: 4)
            arrow("Next puzzle", systemName: "chevron.right", enabled: model.number < model.todayNumber) {
                model.selectPuzzle(model.number + 1)
            }
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.72), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Theme.stone200, lineWidth: 1)
        }
    }

    private var stats: some View {
        HStack {
            Label(formatTime(model.progress.elapsedMs), systemImage: "clock")
                .font(.subheadline.weight(.semibold))
                .monospacedDigit()
                .foregroundStyle(Theme.stone700)
                .accessibilityLabel("Elapsed time")
            Spacer()
            Text("\(model.foundCount)")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Theme.stone800)
            + Text(" of \(model.puzzle.words.count) words")
                .font(.subheadline)
                .foregroundStyle(Theme.stone500)
        }
        .padding(.horizontal, 4)
    }

    private var boardSlot: some View {
        GeometryReader { geo in
            let aspect = CGFloat(model.puzzle.cols) / CGFloat(model.puzzle.rows)
            let pad: CGFloat = 8
            let maxW = max(geo.size.width - pad * 2, 0)
            let maxH = max(geo.size.height - pad * 2, 0)
            let width = min(maxW, maxH * aspect)
            let height = width / aspect
            BoardView(
                puzzle: model.puzzle,
                progress: model.progress,
                disabled: model.progress.completed || model.helpOpen || model.winOpen,
                shakeKey: model.shakeKey,
                onCommit: { model.commit(path: $0) },
                onTraceStart: { model.traceStarted() }
            )
            .id(model.number)
            .frame(width: width, height: height)
            .padding(pad)
            .background(Theme.board, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
            .frame(width: geo.size.width, height: geo.size.height)
        }
    }

    private var controls: some View {
        HStack(spacing: 8) {
            control("Undo", systemName: "arrow.uturn.backward", tip: "Unlock the last word you found", disabled: model.foundCount == 0 || model.progress.completed) {
                model.undo()
            }
            control("Hint", systemName: "lightbulb", tip: "Reveal the next letter of a word", disabled: model.progress.completed) {
                model.hint()
            }
            control(
                "Reset",
                systemName: "arrow.counterclockwise",
                tip: "Clear the board and start over",
                disabled: (model.foundCount == 0 && model.progress.misses.isEmpty) || model.progress.completed
            ) {
                model.reset()
            }
        }
    }

    private var solvedBanner: some View {
        VStack(spacing: 8) {
            Text("Solved in \(formatTime(model.progress.elapsedMs)). Every tile traced.")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Theme.emerald900)
                .multilineTextAlignment(.center)
            HStack(spacing: 8) {
                ShareLink(item: model.shareMessage()) {
                    Label("Share", systemImage: "square.and.arrow.up")
                        .font(.subheadline.weight(.semibold))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Theme.indigo, in: Capsule())
                        .foregroundStyle(.white)
                }
                Button {
                    model.winOpen = true
                } label: {
                    Text("See stats")
                        .font(.subheadline.weight(.semibold))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Capsule().stroke(Theme.emerald200, lineWidth: 1))
                        .foregroundStyle(Theme.emerald900)
                }
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity)
        .background(Theme.emerald50, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Theme.emerald200, lineWidth: 1)
        }
    }

    private var dateLabel: String {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.setLocalizedDateFormatFromTemplate("EEEEMMMMd")
        return formatter.string(from: model.puzzleDate)
    }

    private func arrow(_ label: String, systemName: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(enabled ? Theme.stone700 : Theme.stone300)
                .frame(width: 36, height: 36)
        }
        .disabled(!enabled)
        .accessibilityLabel(label)
    }

    private func control(_ title: String, systemName: String, tip: String, disabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: systemName)
                Text(title)
            }
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(disabled ? Theme.stone400 : Theme.ink)
            .frame(maxWidth: .infinity)
            .frame(height: 44)
            .background(Color.white, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(Theme.stone200, lineWidth: 1)
            }
        }
        .disabled(disabled)
        .accessibilityHint(tip)
    }

    private func toastBanner(_ toast: GameToast) -> some View {
        VStack(spacing: 2) {
            Text(toast.title)
                .font(.subheadline.weight(.semibold))
            if let message = toast.message {
                Text(message)
                    .font(.caption)
            }
        }
        .foregroundStyle(toastForeground(toast.kind))
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity)
        .background(toastBackground(toast.kind), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func toastBackground(_ kind: GameToast.Kind) -> Color {
        switch kind {
        case .success: return Color(hex: 0xECFDF5)
        case .error: return Color(hex: 0xFEF2F2)
        case .info: return Color.white
        }
    }

    private func toastForeground(_ kind: GameToast.Kind) -> Color {
        switch kind {
        case .success: return Theme.emerald900
        case .error: return Color(hex: 0x991B1B)
        case .info: return Theme.ink
        }
    }
}
