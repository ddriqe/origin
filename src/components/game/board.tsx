"use client";

import { useCallback, useMemo, useRef, useState } from "react";
import { cn } from "@/lib/utils";
import type { Puzzle } from "@/lib/puzzles";
import { lockedCells, type Progress } from "@/lib/game";
import { colorFor, MISS_COLOR, TRACE_COLOR } from "./palette";

type BoardProps = {
  puzzle: Puzzle;
  progress: Progress;
  disabled?: boolean;
  shakeKey?: number;
  onCommit: (path: number[]) => void;
  onTap: (cell: number) => void;
  onTraceStart?: (cell: number) => void;
};

/** How far past a tile's centre, in tile widths, the pointer must travel before the next neighbour joins the path. */
const STEP_THRESHOLD = 0.55;

function stepToward(
  path: number[],
  fx: number,
  fy: number,
  cols: number,
  rows: number,
  canEnter: (cell: number) => boolean,
): number[] | null {
  const last = path[path.length - 1];
  const dx = fx - ((last % cols) + 0.5);
  const dy = fy - (Math.floor(last / cols) + 0.5);
  const horizontal = Math.abs(dx) >= Math.abs(dy);
  if ((horizontal ? Math.abs(dx) : Math.abs(dy)) < STEP_THRESHOLD) return null;

  let neighbor: number;
  if (horizontal) {
    const dir = dx > 0 ? 1 : -1;
    const col = last % cols;
    if (col + dir < 0 || col + dir >= cols) return null;
    neighbor = last + dir;
  } else {
    const dir = dy > 0 ? 1 : -1;
    const row = Math.floor(last / cols);
    if (row + dir < 0 || row + dir >= rows) return null;
    neighbor = last + dir * cols;
  }

  if (path.length > 1 && neighbor === path[path.length - 2]) return path.slice(0, -1);
  if (path.includes(neighbor) || !canEnter(neighbor)) return null;
  return [...path, neighbor];
}

/** Walks one orthogonal tile at a time toward the pointer. Never skips or moves diagonally. */
function extendTrace(
  path: number[],
  fx: number,
  fy: number,
  cols: number,
  rows: number,
  canEnter: (cell: number) => boolean,
): number[] {
  let next = path;
  for (let guard = 0; guard < cols * rows; guard++) {
    const stepped = stepToward(next, fx, fy, cols, rows, canEnter);
    if (!stepped) return next;
    next = stepped;
  }
  return next;
}

export function Board({ puzzle, progress, disabled, shakeKey, onCommit, onTap, onTraceStart }: BoardProps) {
  const { rows, cols, cells } = puzzle;
  const boardRef = useRef<HTMLDivElement>(null);
  const traceRef = useRef<number[]>([]);
  const [trace, setTrace] = useState<number[]>([]);

  const locked = useMemo(() => lockedCells(puzzle, progress), [puzzle, progress]);
  const missByCell = useMemo(() => {
    const map = new Map<number, number>();
    progress.misses.forEach((path, i) => path.forEach((c) => map.set(c, i)));
    return map;
  }, [progress.misses]);
  const hintCells = useMemo(() => {
    const map = new Map<number, number>();
    for (const word of puzzle.words) {
      if (progress.found.includes(word.key)) continue;
      const count = progress.hints[word.key] ?? 0;
      word.path.slice(0, count).forEach((cell, i) => map.set(cell, i + 1));
    }
    return map;
  }, [puzzle, progress]);

  const updateTrace = (next: number[]) => {
    traceRef.current = next;
    setTrace(next);
  };

  const pointerOnBoard = useCallback(
    (clientX: number, clientY: number): { x: number; y: number } | null => {
      const rect = boardRef.current?.getBoundingClientRect();
      if (!rect || rect.width === 0 || rect.height === 0) return null;
      return {
        x: ((clientX - rect.left) / rect.width) * cols,
        y: ((clientY - rect.top) / rect.height) * rows,
      };
    },
    [cols, rows],
  );

  const cellAt = useCallback(
    (clientX: number, clientY: number): number | null => {
      const point = pointerOnBoard(clientX, clientY);
      if (!point) return null;
      const c = Math.floor(point.x);
      const r = Math.floor(point.y);
      if (c < 0 || r < 0 || c >= cols || r >= rows) return null;
      return r * cols + c;
    },
    [cols, pointerOnBoard, rows],
  );

  const canEnter = (cell: number) => cells[cell] !== null && !locked.has(cell);

  const handlePointerDown = (e: React.PointerEvent<HTMLDivElement>) => {
    if (disabled || (e.pointerType === "mouse" && e.button !== 0)) return;
    const cell = cellAt(e.clientX, e.clientY);
    if (cell === null || !canEnter(cell)) return;
    e.preventDefault();
    e.currentTarget.setPointerCapture(e.pointerId);
    onTraceStart?.(cell);
    updateTrace([cell]);
  };

  const handlePointerMove = (e: React.PointerEvent<HTMLDivElement>) => {
    const current = traceRef.current;
    if (!current.length) return;
    const point = pointerOnBoard(e.clientX, e.clientY);
    if (!point) return;
    const next = extendTrace(current, point.x, point.y, cols, rows, canEnter);
    if (next.length === current.length && next.every((cell, i) => cell === current[i])) return;
    updateTrace(next);
  };

  const finish = () => {
    const path = traceRef.current;
    if (!path.length) return;
    updateTrace([]);
    if (path.length === 1) onTap(path[0]);
    else onCommit(path);
  };

  const traceSet = new Set(trace);
  const center = (cell: number) => ({ x: (cell % cols) + 0.5, y: Math.floor(cell / cols) + 0.5 });
  const pipe = (path: number[]) => path.map((c) => `${center(c).x},${center(c).y}`).join(" ");

  return (
    <div
      key={shakeKey}
      className={cn("@container relative w-full select-none", shakeKey ? "animate-shake" : "")}
      style={{ aspectRatio: `${cols} / ${rows}` }}
    >
      <svg
        className="pointer-events-none absolute inset-0 h-full w-full"
        viewBox={`0 0 ${cols} ${rows}`}
        aria-hidden
      >
        {progress.misses.map((path, i) => (
          <polyline
            key={`miss-${i}`}
            points={pipe(path)}
            fill="none"
            stroke={MISS_COLOR.pipe}
            strokeWidth={0.22}
            strokeLinecap="round"
            strokeLinejoin="round"
            strokeDasharray="0.08 0.12"
          />
        ))}
        {progress.found.map((key) => {
          const word = puzzle.words.find((w) => w.key === key)!;
          return (
            <polyline
              key={key}
              points={pipe(word.path)}
              fill="none"
              stroke={colorFor(word.colorIndex).pipe}
              strokeWidth={0.3}
              strokeLinecap="round"
              strokeLinejoin="round"
            />
          );
        })}
        {trace.length > 1 && (
          <polyline
            points={pipe(trace)}
            fill="none"
            stroke={TRACE_COLOR.pipe}
            strokeWidth={0.3}
            strokeLinecap="round"
            strokeLinejoin="round"
          />
        )}
      </svg>

      <div
        ref={boardRef}
        role="grid"
        aria-label="Letter grid"
        className={cn("absolute inset-0 grid touch-none", disabled ? "cursor-default" : "cursor-pointer")}
        style={{ gridTemplateColumns: `repeat(${cols}, 1fr)`, gridTemplateRows: `repeat(${rows}, 1fr)` }}
        onPointerDown={handlePointerDown}
        onPointerMove={handlePointerMove}
        onPointerUp={finish}
        onPointerCancel={finish}
        onContextMenu={(e) => e.preventDefault()}
      >
        {cells.map((letter, i) => {
          const word = locked.get(i);
          const inTrace = traceSet.has(i);
          const isMiss = missByCell.has(i) && !inTrace;
          const hint = hintCells.get(i);
          const style =
            letter === null
              ? undefined
              : inTrace
                ? { background: TRACE_COLOR.tile, color: TRACE_COLOR.ink }
                : word
                  ? { background: colorFor(word.colorIndex).tile, color: colorFor(word.colorIndex).ink }
                  : isMiss
                    ? { background: MISS_COLOR.tile, color: MISS_COLOR.ink }
                    : undefined;
          return (
            <div key={i} role="gridcell" className="p-[7%]">
              {letter === null ? (
                <div
                  aria-label="Wall"
                  className="h-full w-full rounded-[22%] bg-[repeating-linear-gradient(135deg,#d9d4cc_0_4px,#cfc9c0_4px_8px)]"
                />
              ) : (
                <div
                  aria-label={letter}
                  style={{ fontSize: `${46 / cols}cqw`, ...style }}
                  className={cn(
                    "relative flex h-full w-full items-center justify-center rounded-[22%] font-heading font-bold uppercase transition-[background,color,transform] duration-150",
                    !style && "bg-white text-stone-800 shadow-[0_1px_0_1px_rgba(120,100,80,0.18)]",
                    inTrace && "scale-[1.04] shadow-lg shadow-indigo-900/20",
                    word && "shadow-none",
                    isMiss && "outline-2 outline-dashed outline-[#e3b7ae]",
                  )}
                >
                  {letter}
                  {hint !== undefined && !word && !inTrace && (
                    <span className="absolute top-[8%] right-[10%] flex size-[28%] items-center justify-center rounded-full bg-amber-400 font-bold text-amber-950"
                      style={{ fontSize: `${18 / cols}cqw` }}>
                      {hint}
                    </span>
                  )}
                </div>
              )}
            </div>
          );
        })}
      </div>
    </div>
  );
}
