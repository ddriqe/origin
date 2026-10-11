import { RAW_PUZZLES, parsePuzzle } from "../src/lib/puzzles.ts";

let failed = false;
for (const raw of RAW_PUZZLES) {
  try {
    const p = parsePuzzle(raw);
    const open = p.cells.filter((c) => c !== null).length;
    const covered = p.words.reduce((n, w) => n + w.text.length, 0);
    if (open !== covered) throw new Error(`${p.title}: ${open} open tiles but words cover ${covered}`);
    const lengths = p.words.map((w) => w.text.length);
    if (Math.min(...lengths) < 3) throw new Error(`${p.title}: words must be at least 3 letters`);
    if (Math.max(...lengths) > p.cols + 1) throw new Error(`${p.title}: longest word exceeds width + 1`);
    console.log(`ok  ${p.title} (${p.rows}x${p.cols}, ${p.words.map((w) => w.text).join(" ")})`);
  } catch (err) {
    failed = true;
    console.error(`ERR ${(err as Error).message}`);
  }
}
process.exit(failed ? 1 : 0);
