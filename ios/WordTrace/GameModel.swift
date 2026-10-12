import Combine
import Foundation
import WordTraceCore

struct GameToast: Identifiable, Equatable {
    enum Kind { case success, error, info }
    let id = UUID()
    var title: String
    var message: String?
    var kind: Kind
}

@MainActor
final class GameModel: ObservableObject {
    @Published var todayNumber: Int
    @Published var number: Int
    @Published var progress: Progress {
        didSet {
            guard persistEnabled else { return }
            persist()
            updateClock()
        }
    }
    @Published var helpOpen: Bool
    @Published var winOpen = false
    @Published var toast: GameToast?
    @Published var shakeKey = 0
    @Published private(set) var sceneActive = true

    private var started: Bool
    private var persistEnabled = true
    private var timer: Timer?
    private var lastTick: Date?
    private var missTask: Task<Void, Never>?
    private var winTask: Task<Void, Never>?
    private var toastTask: Task<Void, Never>?

    init(now: Date = Date(), timeZone: TimeZone = .current) {
        let today = puzzleNumber(for: now, timeZone: timeZone)
        let saved = Self.load(today)
        todayNumber = today
        number = today
        progress = saved
        started = saved.elapsedMs > 0
        helpOpen = !UserDefaults.standard.bool(forKey: Self.helpSeenKey)
        updateClock()
    }

    var puzzle: Puzzle { WordTraceCore.puzzle(for: number) }
    var isToday: Bool { number == todayNumber }
    var foundCount: Int { progress.found.count }

    var puzzleDate: Date {
        let parts = dateComponents(forPuzzleNumber: number)
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .current
        return calendar.date(from: DateComponents(year: parts.year, month: parts.month, day: parts.day, hour: 12)) ?? Date()
    }

    func setSceneActive(_ active: Bool) {
        sceneActive = active
        if active {
            lastTick = Date()
        } else {
            lastTick = nil
        }
        updateClock()
    }

    func selectPuzzle(_ n: Int) {
        guard n >= 1, n <= todayNumber, n != number else { return }
        missTask?.cancel()
        winTask?.cancel()
        persistEnabled = false
        number = n
        progress = Self.load(n)
        started = progress.elapsedMs > 0
        winOpen = false
        persistEnabled = true
        updateClock()
    }

    func traceStarted() {
        started = true
        missTask?.cancel()
        if !progress.misses.isEmpty {
            progress.misses = []
        }
        updateClock()
    }

    func commit(path: [Int]) {
        let result = evaluateTrace(puzzle: puzzle, progress: progress, path: path)
        switch result {
        case .found(let word):
            var found = progress.found
            found.append(word.key)
            let completed = found.count == puzzle.words.count
            progress.found = found
            progress.completed = completed
            progress.misses.removeAll { miss in miss.contains { path.contains($0) } }
            if completed {
                let snapshot = number
                winTask?.cancel()
                winTask = Task { [weak self] in
                    try? await Task.sleep(nanoseconds: 650_000_000)
                    guard let self, !Task.isCancelled, self.number == snapshot, self.progress.completed else { return }
                    self.winOpen = true
                }
            } else {
                showToast(GameToast(
                    title: word.text,
                    message: "\(found.count) of \(puzzle.words.count) words found",
                    kind: .success
                ))
            }
        case .alreadyFound, .tooShort:
            break
        case .wrongTiles(let text):
            registerMiss(path: path, message: "\(text) is hidden somewhere else")
        case .notAWord(let text):
            registerMiss(path: path, message: "\(text) isn't one of today's words")
        }
    }

    func hint() {
        guard let hints = nextHint(puzzle: puzzle, progress: progress) else {
            showToast(GameToast(
                title: "No more hints for this board",
                message: "Every remaining word is fully revealed but one letter.",
                kind: .info
            ))
            return
        }
        started = true
        progress.hints = hints
        updateClock()
    }

    func undo() {
        guard !progress.found.isEmpty, !progress.completed else { return }
        progress.found.removeLast()
    }

    func reset() {
        guard !progress.completed else { return }
        guard !progress.found.isEmpty || !progress.misses.isEmpty else { return }
        progress.found = []
        progress.misses = []
        showToast(GameToast(title: "Board cleared", message: "Your timer and hints carry on.", kind: .info))
    }

    func dismissHelp() {
        helpOpen = false
        UserDefaults.standard.set(true, forKey: Self.helpSeenKey)
    }

    func shareMessage() -> String {
        shareText(
            number: number,
            puzzle: puzzle,
            progress: progress,
            url: WordTraceSite.puzzleURL(number: number)
        )
    }

    private func registerMiss(path: [Int], message: String) {
        missTask?.cancel()
        progress.misses = [path]
        progress.missCount += 1
        shakeKey += 1
        showToast(GameToast(title: message, message: nil, kind: .error))
        missTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 500_000_000)
            guard let self, !Task.isCancelled else { return }
            self.progress.misses = []
        }
    }

    private func showToast(_ toast: GameToast) {
        self.toast = toast
        toastTask?.cancel()
        toastTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 2_200_000_000)
            guard let self, !Task.isCancelled else { return }
            if self.toast?.id == toast.id { self.toast = nil }
        }
    }

    private func updateClock() {
        let running = started && !progress.completed && sceneActive
        if running {
            if timer == nil {
                lastTick = Date()
                let timer = Timer(timeInterval: 0.25, repeats: true) { [weak self] _ in
                    Task { @MainActor in self?.tick() }
                }
                RunLoop.main.add(timer, forMode: .common)
                self.timer = timer
            }
        } else {
            timer?.invalidate()
            timer = nil
            lastTick = nil
        }
    }

    private func tick() {
        guard started, !progress.completed, sceneActive, let lastTick else { return }
        let now = Date()
        progress.elapsedMs += now.timeIntervalSince(lastTick) * 1000
        self.lastTick = now
    }

    private func persist() {
        guard persistEnabled else { return }
        var copy = progress
        copy.misses = []
        guard let data = try? JSONEncoder().encode(copy) else { return }
        UserDefaults.standard.set(data, forKey: Self.storageKey(number))
    }

    private static func load(_ number: Int) -> Progress {
        guard let data = UserDefaults.standard.data(forKey: storageKey(number)),
              var progress = try? JSONDecoder().decode(Progress.self, from: data) else {
            return .empty()
        }
        progress.misses = []
        return progress
    }

    private static func storageKey(_ number: Int) -> String { "wordtrace:v1:puzzle-\(number)" }
    private static let helpSeenKey = "wordtrace:v1:help-seen"

    deinit {
        timer?.invalidate()
    }
}
