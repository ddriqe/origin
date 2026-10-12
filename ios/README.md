# WordTrace for iOS

A phone-first SwiftUI version of [WordTrace](https://ddriqe.github.io/origin/). Trace words up, down, left, and right. Walls stay blocked, diagonals are not allowed, and the daily board is the same one the website serves for that local date.

This folder is an Xcode project. It does not change the website, the puzzle rules, or the GitHub Pages workflow.

## Open the project

1. On a Mac, install Xcode 16 or newer.
2. Open `ios/WordTrace.xcodeproj`.
3. Wait for Xcode to resolve the local `WordTraceCore` package (it has no network dependencies).
4. Choose an iPhone simulator or a connected iPhone and press Run.

The iPhone target is portrait only. iPad can rotate, and the layout stays a single column.

## Daily puzzle

Puzzle number and words come from the same list and the same date rule as `src/lib/puzzles.ts` on `main` of this repo (copied at `e57fe241aab73faac16546bf755ee6f939ddb98c`).

- Puzzle #1 is 1 October 2026 in the player's local calendar.
- Each later local date unlocks the next puzzle. Dates before launch stay on puzzle #1.
- The day count uses the Gregorian year, month, and day, then the same UTC day number as `Math.floor(Date.UTC(year, month - 1, day) / 86400000)`. A local evening is not shifted onto the next UTC date.
- The board is `puzzles[(number - 1) % puzzles.count]`, in the published order.

So 12 October 2026 is puzzle #12, **Out of Office**, on both the app and https://ddriqe.github.io/origin/.

The list is compiled into the app. When a puzzle is added to `src/lib/puzzles.ts`, copy that list into `ios/WordTraceCore/Sources/WordTraceCore/Puzzle.swift` and extend `PuzzleSelectionTests`. Until that copy is updated, dates keep using the seven boards shipped here, in the same rotation the site used at the commit above.

`WordTraceTests` (and `cd ios/WordTraceCore && swift test`) checks fixed dates against the puzzle number, title, words, and solution paths produced by the website code.

## Tracing, hints, and archive

- A drag steps to the next orthogonal neighbour once the finger is 0.55 tile-widths past the current centre, even if it is not on that tile's centre. Dragging back pops the previous tile.
- A miss draws a dashed path for half a second, then clears. Starting another trace clears it immediately. Traces shorter than 3 letters are ignored.
- Hint, Undo, and Reset match the site. Reset clears found words and keeps the timer and hints. The timer starts on the first trace or hint and pauses while the app is in the background.
- The arrows open earlier days and stop at today. The how-to card includes the small CAT / SUN example board and opens on the first launch.
- Progress is stored on the device, per puzzle number. Share text points at `https://ddriqe.github.io/origin/?n=<number>`.

## Tests without a Mac

The puzzle rules live in the Swift package `ios/WordTraceCore`, which does not import SwiftUI. On a machine with Swift:

```bash
cd ios/WordTraceCore
swift test
```

In Xcode, Product > Test runs the same files inside `WordTraceTests`.

## App Store

A paid [Apple Developer Program](https://developer.apple.com/programs/) membership is required. This repository cannot upload the build for you.

1. Select the **WordTrace** target, then **Signing & Capabilities**.
2. Choose your Team.
3. Change the bundle identifier from `com.wordtrace.app` to one you own, such as `com.yourname.wordtrace`. The test target uses `com.wordtrace.app.tests`; change that prefix to match if you want both to sit under your identifier.
4. Set the version and build under **General** if you are shipping an update. The project starts at version 1.0 (build 1).
5. Choose **Any iOS Device (arm64)** as the run destination.
6. **Product > Archive**.
7. In the Organizer, **Distribute App > App Store Connect > Upload**.
8. In App Store Connect, attach the build to a new app record that uses the same bundle identifier, fill in the listing, and submit for review.

The app declares no encryption beyond the standard HTTPS exemption (`ITSAppUsesNonExemptEncryption` is false) and does not collect data. It targets iOS 17.

The Outfit typeface is licensed under the SIL Open Font License. The license is in `WordTrace/Fonts/OFL.txt`.
