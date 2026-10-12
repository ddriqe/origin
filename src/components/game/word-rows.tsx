import { cn } from "@/lib/utils";
import type { Puzzle } from "@/lib/puzzles";
import { wordRows, type Progress } from "@/lib/game";
import { colorFor } from "./palette";

export function WordRows({ puzzle, progress }: { puzzle: Puzzle; progress: Progress }) {
  const rows = wordRows(puzzle, progress);
  const maxLen = Math.max(...rows.map((r) => r.length));

  return (
    <ol className="flex flex-col items-center gap-1.5 max-sm:gap-1" aria-label="Words to find">
      {rows.map((row, i) => {
        const color = row.found ? colorFor(row.found.colorIndex) : null;
        return (
          <li
            key={i}
            className="grid w-full gap-1 max-sm:max-w-[min(100%,calc(var(--row-len)*1.65rem))] sm:max-w-[calc(var(--row-len)*2.4rem)]"
            style={{
              gridTemplateColumns: `repeat(${maxLen}, minmax(0, 1fr))`,
              ["--row-len" as string]: maxLen,
            }}
            aria-label={row.found ? `Found: ${row.found.text}` : `${row.length}-letter word`}
          >
            {Array.from({ length: row.length }, (_, j) => {
              const letter = row.found?.text[j] ?? (row.hint && j < row.hint.count ? row.hint.word.text[j] : "");
              return (
                <span
                  key={j}
                  style={color ? { background: color.tile, color: color.ink, transitionDelay: `${j * 40}ms` } : undefined}
                  className={cn(
                    "flex aspect-square items-center justify-center rounded-md text-xs font-bold uppercase transition-colors duration-300 sm:text-base",
                    !color && "border border-dashed border-stone-300 bg-white/60 text-amber-700",
                  )}
                >
                  {letter}
                </span>
              );
            })}
          </li>
        );
      })}
    </ol>
  );
}
