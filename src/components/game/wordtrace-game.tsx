"use client";

import { useCallback, useEffect, useRef, useState } from "react";
import { ChevronLeft, ChevronRight, CircleHelp, Clock, Lightbulb, RotateCcw, Share2, Undo2 } from "lucide-react";
import { toast } from "sonner";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { Tooltip, TooltipContent, TooltipTrigger } from "@/components/ui/tooltip";
import { dateForPuzzleNumber, puzzleForNumber, puzzleNumberForDate } from "@/lib/puzzles";
import {
  emptyProgress,
  evaluateTrace,
  formatTime,
  nextHint,
  shareText,
  type Progress,
} from "@/lib/game";
import { Board } from "./board";
import { WordRows } from "./word-rows";
import { HowToPlay } from "./how-to-play";
import { WinDialog } from "./win-dialog";
import { Logo } from "./logo";

const storageKey = (n: number) => `wordtrace:v1:puzzle-${n}`;
const HELP_SEEN_KEY = "wordtrace:v1:help-seen";

function loadProgress(n: number): Progress {
  try {
    const raw = localStorage.getItem(storageKey(n));
    if (!raw) return emptyProgress();
    return { ...emptyProgress(), ...(JSON.parse(raw) as Partial<Progress>) };
  } catch {
    return emptyProgress();
  }
}

export function WordTraceGame() {
  const [today, setToday] = useState<number | null>(null);
  const [number, setNumber] = useState<number | null>(null);
  const [progress, setProgress] = useState<Progress>(emptyProgress);
  const [started, setStarted] = useState(false);
  const [helpOpen, setHelpOpen] = useState(false);
  const [winOpen, setWinOpen] = useState(false);
  const [shakeKey, setShakeKey] = useState(0);
  const lastTick = useRef<number | null>(null);

  useEffect(() => {
    const todayNumber = puzzleNumberForDate(new Date());
    const requested = Number(new URLSearchParams(window.location.search).get("n"));
    const initial = Number.isInteger(requested) && requested >= 1 && requested <= todayNumber ? requested : todayNumber;
    const saved = loadProgress(initial);
    /* eslint-disable react-hooks/set-state-in-effect -- today's date is only known on the client */
    setToday(todayNumber);
    setNumber(initial);
    setProgress(saved);
    setStarted(saved.elapsedMs > 0);
    if (!localStorage.getItem(HELP_SEEN_KEY)) setHelpOpen(true);
    /* eslint-enable react-hooks/set-state-in-effect */
  }, []);

  useEffect(() => {
    if (number === null) return;
    try {
      localStorage.setItem(storageKey(number), JSON.stringify(progress));
    } catch {
      // Storage can be unavailable (private mode, quota); the game still works without persistence.
    }
  }, [number, progress]);

  const running = started && !progress.completed && number !== null;
  useEffect(() => {
    if (!running) {
      lastTick.current = null;
      return;
    }
    lastTick.current = performance.now();
    const tick = () => {
      const now = performance.now();
      if (document.hidden) {
        lastTick.current = now;
        return;
      }
      const delta = now - (lastTick.current ?? now);
      lastTick.current = now;
      setProgress((p) => (p.completed ? p : { ...p, elapsedMs: p.elapsedMs + delta }));
    };
    const id = window.setInterval(tick, 250);
    const onVisibility = () => {
      lastTick.current = performance.now();
    };
    document.addEventListener("visibilitychange", onVisibility);
    return () => {
      window.clearInterval(id);
      document.removeEventListener("visibilitychange", onVisibility);
    };
  }, [running]);

  const selectPuzzle = useCallback((n: number) => {
    const saved = loadProgress(n);
    setNumber(n);
    setProgress(saved);
    setStarted(saved.elapsedMs > 0);
    setWinOpen(false);
    const url = new URL(window.location.href);
    url.searchParams.set("n", String(n));
    window.history.replaceState(null, "", url);
  }, []);

  if (number === null || today === null) return <GameSkeleton />;

  const puzzle = puzzleForNumber(number);
  const date = dateForPuzzleNumber(number);
  const isToday = number === today;
  const foundCount = progress.found.length;

  const handleCommit = (path: number[]) => {
    const result = evaluateTrace(puzzle, progress, path);
    switch (result.kind) {
      case "found": {
        const found = [...progress.found, result.word.key];
        const completed = found.length === puzzle.words.length;
        setProgress((p) => ({
          ...p,
          found,
          completed,
          misses: p.misses.filter((m) => !m.some((c) => path.includes(c))),
        }));
        if (completed) {
          window.setTimeout(() => setWinOpen(true), 650);
        } else {
          toast.success(result.word.text, { description: `${found.length} of ${puzzle.words.length} words found` });
        }
        return;
      }
      case "already-found":
      case "too-short":
        return;
      case "wrong-tiles":
      case "not-a-word":
        setProgress((p) => ({
          ...p,
          misses: [...p.misses.filter((m) => !m.some((c) => path.includes(c))), path],
          missCount: p.missCount + 1,
        }));
        setShakeKey((k) => k + 1);
        toast.error(
          result.kind === "wrong-tiles"
            ? `${result.text} is hidden somewhere else`
            : `${result.text} isn't one of today's words`,
          { description: "Tap the dashed trace to clear it." },
        );
    }
  };

  const handleTraceStart = (cell: number) => {
    setStarted(true);
    if (progress.misses.some((m) => m.includes(cell))) {
      setProgress((p) => ({ ...p, misses: p.misses.filter((m) => !m.includes(cell)) }));
    }
  };

  const handleTap = () => {
    // Tapping a miss already cleared it in handleTraceStart; a single tile is never a word.
  };

  const handleHint = () => {
    const hints = nextHint(puzzle, progress);
    if (!hints) {
      toast("No more hints for this board", { description: "Every remaining word is fully revealed but one letter." });
      return;
    }
    setStarted(true);
    setProgress((p) => ({ ...p, hints }));
  };

  const handleUndo = () => {
    if (!progress.found.length) return;
    setProgress((p) => ({ ...p, found: p.found.slice(0, -1) }));
  };

  const handleReset = () => {
    setProgress((p) => ({ ...p, found: [], misses: [] }));
    toast("Board cleared", { description: "Your timer and hints carry on." });
  };

  const handleShare = async () => {
    const url = `${window.location.origin}/?n=${number}`;
    const text = shareText({ number, puzzle, progress, url });
    try {
      if (navigator.share && window.matchMedia("(pointer: coarse)").matches) {
        await navigator.share({ text });
        return;
      }
      await navigator.clipboard.writeText(text);
      toast.success("Result copied", { description: "Paste it anywhere to share." });
    } catch (err) {
      if ((err as Error).name === "AbortError") return;
      toast.error("Couldn't copy automatically", { description: text });
    }
  };

  return (
    <div className="mx-auto flex w-full max-w-[30rem] flex-1 flex-col px-4 pb-8 sm:px-6">
      <header className="flex items-center justify-between py-4">
        <div className="flex items-center gap-2">
          <Logo className="size-9" />
          <div className="leading-tight">
            <h1 className="font-heading text-xl font-extrabold tracking-tight text-stone-900">WordTrace</h1>
            <p className="text-xs text-stone-500">A daily word-path puzzle</p>
          </div>
        </div>
        <div className="flex items-center gap-1">
          {progress.completed && (
            <Button variant="ghost" size="icon" aria-label="Share result" onClick={handleShare}>
              <Share2 />
            </Button>
          )}
          <Button variant="ghost" size="icon" aria-label="How to play" onClick={() => setHelpOpen(true)}>
            <CircleHelp />
          </Button>
        </div>
      </header>

      <section className="mb-3 flex items-center justify-between rounded-2xl bg-white/70 px-2 py-2 shadow-[0_1px_0_rgba(120,100,80,0.12)] ring-1 ring-stone-200/80">
        <Button
          variant="ghost"
          size="icon"
          aria-label="Previous puzzle"
          disabled={number <= 1}
          onClick={() => selectPuzzle(number - 1)}
        >
          <ChevronLeft />
        </Button>
        <div className="flex flex-col items-center text-center">
          <div className="flex items-center gap-2">
            <span className="font-heading text-base font-bold text-stone-900">
              #{number} · {puzzle.title}
            </span>
            {isToday ? (
              <Badge className="bg-indigo-600 text-white">Today</Badge>
            ) : (
              <Badge variant="secondary">Archive</Badge>
            )}
          </div>
          <span className="text-xs text-stone-500">
            {date.toLocaleDateString(undefined, { weekday: "long", month: "long", day: "numeric" })}
          </span>
        </div>
        <Button
          variant="ghost"
          size="icon"
          aria-label="Next puzzle"
          disabled={number >= today}
          onClick={() => selectPuzzle(number + 1)}
        >
          <ChevronRight />
        </Button>
      </section>

      <div className="mb-3 flex items-center justify-between px-1 text-sm">
        <span className="flex items-center gap-1.5 font-semibold tabular-nums text-stone-700" aria-label="Elapsed time">
          <Clock className="size-4 text-stone-400" />
          {formatTime(progress.elapsedMs)}
        </span>
        <span className="text-stone-500">
          <span className="font-semibold text-stone-800">{foundCount}</span> of {puzzle.words.length} words
        </span>
      </div>

      <div className="rounded-3xl bg-[#ebe5dc] p-2 shadow-inner sm:p-3">
        <Board
          key={number}
          puzzle={puzzle}
          progress={progress}
          disabled={progress.completed}
          shakeKey={shakeKey}
          onCommit={handleCommit}
          onTap={handleTap}
          onTraceStart={handleTraceStart}
        />
      </div>

      <div className="mt-3 grid grid-cols-3 gap-2">
        <ControlButton label="Undo" tip="Unlock the last word you found" disabled={!foundCount || progress.completed} onClick={handleUndo}>
          <Undo2 />
        </ControlButton>
        <ControlButton label="Hint" tip="Reveal the next letter of a word" disabled={progress.completed} onClick={handleHint}>
          <Lightbulb />
        </ControlButton>
        <ControlButton
          label="Reset"
          tip="Clear the board and start over"
          disabled={(!foundCount && !progress.misses.length) || progress.completed}
          onClick={handleReset}
        >
          <RotateCcw />
        </ControlButton>
      </div>

      <div className="mt-5">
        <WordRows puzzle={puzzle} progress={progress} />
      </div>

      {progress.completed && (
        <div className="mt-5 flex flex-col items-center gap-2 rounded-2xl bg-emerald-50 p-4 text-center ring-1 ring-emerald-200">
          <p className="font-semibold text-emerald-900">
            Solved in {formatTime(progress.elapsedMs)}. Every tile traced.
          </p>
          <div className="flex gap-2">
            <Button size="sm" className="bg-indigo-600 text-white hover:bg-indigo-700" onClick={handleShare}>
              <Share2 /> Share
            </Button>
            <Button size="sm" variant="outline" onClick={() => setWinOpen(true)}>
              See stats
            </Button>
          </div>
        </div>
      )}

      <HowToPlay
        open={helpOpen}
        onOpenChange={(open) => {
          setHelpOpen(open);
          if (!open) localStorage.setItem(HELP_SEEN_KEY, "1");
        }}
      />
      <WinDialog
        open={winOpen}
        onOpenChange={setWinOpen}
        number={number}
        puzzle={puzzle}
        progress={progress}
        isToday={isToday}
        onShare={handleShare}
        onPlayPrevious={number > 1 ? () => selectPuzzle(number - 1) : undefined}
      />
    </div>
  );
}

function ControlButton({
  label,
  tip,
  disabled,
  onClick,
  children,
}: {
  label: string;
  tip: string;
  disabled?: boolean;
  onClick: () => void;
  children: React.ReactNode;
}) {
  return (
    <Tooltip>
      <TooltipTrigger
        render={
          <Button variant="outline" size="lg" className="h-11 w-full rounded-xl bg-white" disabled={disabled} onClick={onClick} />
        }
      >
        {children}
        {label}
      </TooltipTrigger>
      <TooltipContent>{tip}</TooltipContent>
    </Tooltip>
  );
}

function GameSkeleton() {
  return (
    <div className="mx-auto flex w-full max-w-[30rem] flex-1 flex-col px-4 pb-8 sm:px-6" aria-busy="true" aria-label="Loading today's puzzle">
      <div className="flex items-center gap-2 py-4">
        <Logo className="size-9" />
        <span className="font-heading text-xl font-extrabold tracking-tight text-stone-900">WordTrace</span>
      </div>
      <div className="mb-3 h-14 animate-pulse rounded-2xl bg-stone-200/70" />
      <div className="mb-3 h-5" />
      <div className="grid aspect-square grid-cols-5 gap-2 rounded-3xl bg-[#ebe5dc] p-3">
        {Array.from({ length: 25 }, (_, i) => (
          <div key={i} className="animate-pulse rounded-[22%] bg-white/60" style={{ animationDelay: `${(i % 5) * 80}ms` }} />
        ))}
      </div>
      <p className="mt-4 text-center text-sm text-stone-500">Loading today&apos;s board…</p>
    </div>
  );
}
