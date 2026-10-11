import { isPalindrome, type Puzzle, type PuzzleWord } from "./puzzles";

export type Progress = {
  /** Keys of found words, in the order they were found. */
  found: string[];
  /** Incorrect traces that stay on the board until the player clears them. */
  misses: number[][];
  /** Number of revealed letters per word key. */
  hints: Record<string, number>;
  /** Total incorrect traces submitted, including ones already cleared. */
  missCount: number;
  elapsedMs: number;
  completed: boolean;
};

export const emptyProgress = (): Progress => ({
  found: [],
  misses: [],
  hints: {},
  missCount: 0,
  elapsedMs: 0,
  completed: false,
});

export type TraceResult =
  | { kind: "found"; word: PuzzleWord }
  | { kind: "already-found"; word: PuzzleWord }
  | { kind: "wrong-tiles"; text: string }
  | { kind: "not-a-word"; text: string }
  | { kind: "too-short" };

const samePath = (a: number[], b: number[]) =>
  a.length === b.length && a.every((v, i) => v === b[i]);

export function spell(puzzle: Puzzle, path: number[]): string {
  return path.map((i) => puzzle.cells[i] ?? "").join("");
}

export function evaluateTrace(puzzle: Puzzle, progress: Progress, path: number[]): TraceResult {
  if (path.length < 3) return { kind: "too-short" };
  const text = spell(puzzle, path);
  const reversed = [...path].reverse();

  for (const word of puzzle.words) {
    const matches =
      samePath(word.path, path) || (isPalindrome(word.text) && samePath(word.path, reversed));
    if (!matches) continue;
    return progress.found.includes(word.key)
      ? { kind: "already-found", word }
      : { kind: "found", word };
  }

  const remaining = puzzle.words.filter((w) => !progress.found.includes(w.key));
  if (remaining.some((w) => w.text === text)) return { kind: "wrong-tiles", text };
  return { kind: "not-a-word", text };
}

export function lockedCells(puzzle: Puzzle, progress: Progress): Map<number, PuzzleWord> {
  const map = new Map<number, PuzzleWord>();
  for (const key of progress.found) {
    const word = puzzle.words.find((w) => w.key === key);
    word?.path.forEach((cell) => map.set(cell, word));
  }
  return map;
}

/** Reveals one more letter of the shortest unfound word that is still partly hidden. */
export function nextHint(puzzle: Puzzle, progress: Progress): Record<string, number> | null {
  const candidates = puzzle.words
    .filter((w) => !progress.found.includes(w.key))
    .filter((w) => (progress.hints[w.key] ?? 0) < w.text.length - 1)
    .sort((a, b) => {
      const started = Number(!!progress.hints[b.key]) - Number(!!progress.hints[a.key]);
      return started || a.text.length - b.text.length || a.key.localeCompare(b.key);
    });
  const target = candidates[0];
  if (!target) return null;
  return { ...progress.hints, [target.key]: (progress.hints[target.key] ?? 0) + 1 };
}

export function totalHints(progress: Progress): number {
  return Object.values(progress.hints).reduce((n, v) => n + v, 0);
}

/**
 * Rows under the board: one per word, sorted shortest to longest.
 * Found words fill the first empty row of their length, in the order they were found.
 */
export function wordRows(puzzle: Puzzle, progress: Progress) {
  const sorted = [...puzzle.words].sort(
    (a, b) => a.text.length - b.text.length || a.key.localeCompare(b.key),
  );
  const foundByLength = new Map<number, PuzzleWord[]>();
  for (const key of progress.found) {
    const word = puzzle.words.find((w) => w.key === key)!;
    foundByLength.set(word.text.length, [...(foundByLength.get(word.text.length) ?? []), word]);
  }
  const hintedByLength = new Map<number, PuzzleWord[]>();
  for (const w of sorted) {
    if (progress.found.includes(w.key) || !progress.hints[w.key]) continue;
    hintedByLength.set(w.text.length, [...(hintedByLength.get(w.text.length) ?? []), w]);
  }

  const seen = new Map<number, number>();
  return sorted.map((slot) => {
    const len = slot.text.length;
    const idx = seen.get(len) ?? 0;
    seen.set(len, idx + 1);
    const found = foundByLength.get(len)?.[idx];
    if (found) return { length: len, found, hint: null as null | { word: PuzzleWord; count: number } };
    const hintIdx = idx - (foundByLength.get(len)?.length ?? 0);
    const hinted = hintedByLength.get(len)?.[hintIdx];
    return {
      length: len,
      found: null,
      hint: hinted ? { word: hinted, count: progress.hints[hinted.key] } : null,
    };
  });
}

export function formatTime(ms: number): string {
  const total = Math.floor(ms / 1000);
  const h = Math.floor(total / 3600);
  const m = Math.floor((total % 3600) / 60);
  const s = total % 60;
  const pad = (n: number) => n.toString().padStart(2, "0");
  return h > 0 ? `${h}:${pad(m)}:${pad(s)}` : `${m}:${pad(s)}`;
}

export function shareText(opts: {
  number: number;
  puzzle: Puzzle;
  progress: Progress;
  url: string;
}): string {
  const { number, puzzle, progress, url } = opts;
  const hints = totalHints(progress);
  const misses = progress.missCount;
  const lengths = [...puzzle.words]
    .sort((a, b) => a.text.length - b.text.length)
    .map((w) => w.text.length)
    .join("·");
  return [
    `WordTrace #${number} solved in ${formatTime(progress.elapsedMs)}`,
    `${puzzle.words.length} words (${lengths}) · ${hints} ${hints === 1 ? "hint" : "hints"}${misses ? ` · ${misses} ${misses === 1 ? "miss" : "misses"}` : ""}`,
    hints === 0 && misses === 0 ? "Flawless trace." : "",
    url,
  ]
    .filter(Boolean)
    .join("\n");
}
