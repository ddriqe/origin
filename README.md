# WordTrace

WordTrace is a daily word-path puzzle for the browser, modelled on the mechanics of LinkedIn's **Wend** (launched June 2026). It uses original branding, art, and puzzles.

A small grid of letters hides 4–7 words. You find them by dragging from letter to letter, and every open tile belongs to exactly one word.

## Rules

1. **Trace a word.** Press on a letter and drag through neighbouring tiles: up, down, left, or right. Diagonal moves are not allowed, and striped tiles are walls you can't pass through. Release to submit.
2. **Use every tile once.** Words never overlap, and no open tile is left over. The word lengths add up to the number of open tiles.
3. **Read the rows.** The rows under the board show how many words are hidden and how long each one is, shortest first. A correct word locks in with its own colour and fills a matching row.
4. **Only the exact path counts.** A trace is accepted only if it follows the hidden word's tiles from first letter to last. Palindromes can be traced in either direction. A real word traced on the wrong tiles is a miss.
5. **Misses stay on the board.** They show as dashed traces until you tap them or trace over them.

**Hint** reveals the next letter of a word on the board. **Undo** unlocks the last word you found, and **Reset** clears the board. The timer starts on your first move and pauses while the tab is hidden.

## Features

- Mouse and touch tracing via pointer events. You can backtrack by dragging back onto the previous tile, and tile corners have a dead zone so diagonal swipes don't misfire.
- 7 bundled puzzles (5×5 and 6×6) that rotate daily by local date. Puzzle #1 is dated 1 October 2026. The arrows let you replay past days, and `?n=<number>` links straight to a puzzle.
- Progress, timer, hints, and misses are saved per puzzle in `localStorage`.
- A win dialog shows your time, hints, and misses, with shareable result text (native share sheet on mobile, clipboard on desktop).
- A how-to-play dialog opens on your first visit, and the layout is responsive for mobile and desktop.

## Tech stack

Next.js 16 (App Router, Turbopack), TypeScript, Tailwind CSS v4, and shadcn/ui (Base UI) with sonner toasts. There is no backend; everything runs in the browser.

## Running locally

```bash
npm install
npm run dev            # http://localhost:4317
```

Other scripts:

```bash
npm run validate:puzzles   # checks every bundled puzzle is consistent and fully traceable
npm run lint
npm run build && npm start # production build, also served on port 4317
```

## Adding a puzzle

Puzzles live in `src/lib/puzzles.ts`. Each one is a letter grid, a matching region grid that tags every open tile with a word key (`#` marks walls), and the word for each key:

```ts
{
  title: "Low Tide",
  letters: ["CORAT", "REELI", "#WFED", "VASEA", "EEEL#"],
  regions: ["aaaab", "cccab", "#dcbb", "ddeee", "dfff#"],
  words: { a: "CORAL", b: "TIDE", c: "REEF", d: "WAVE", e: "SEA", f: "EEL" },
}
```

The solution path for each word is worked out from its region when the app loads. Run `npm run validate:puzzles` to confirm that the walls line up, every word can be traced through its region, lengths are between 3 and width + 1, and every open tile is covered.

## Project layout

```
src/lib/puzzles.ts               puzzle data, parsing, daily rotation
src/lib/game.ts                  pure game logic (trace evaluation, hints, rows, share text)
src/components/game/             board, word rows, dialogs, main game component
scripts/validate-puzzles.mts     puzzle consistency check
```
