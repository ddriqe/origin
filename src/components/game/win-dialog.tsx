"use client";

import { Check, Clock, Lightbulb, Share2, X } from "lucide-react";
import { Button } from "@/components/ui/button";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import { formatTime, totalHints, type Progress } from "@/lib/game";
import type { Puzzle } from "@/lib/puzzles";
import { colorFor } from "./palette";

type WinDialogProps = {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  number: number;
  puzzle: Puzzle;
  progress: Progress;
  isToday: boolean;
  onShare: () => void;
  onPlayPrevious?: () => void;
};

export function WinDialog({ open, onOpenChange, number, puzzle, progress, isToday, onShare, onPlayPrevious }: WinDialogProps) {
  const hints = totalHints(progress);
  const stats = [
    { icon: Clock, label: "Time", value: formatTime(progress.elapsedMs) },
    { icon: Lightbulb, label: "Hints", value: String(hints) },
    { icon: X, label: "Misses", value: String(progress.missCount) },
  ];

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="sm:max-w-md">
        <DialogHeader className="items-center text-center">
          <span className="mb-1 flex size-12 items-center justify-center rounded-full bg-emerald-100 text-emerald-700">
            <Check className="size-6" strokeWidth={3} />
          </span>
          <DialogTitle className="text-2xl">
            {hints === 0 && progress.missCount === 0 ? "Flawless trace!" : "Board cleared!"}
          </DialogTitle>
          <DialogDescription>
            You solved WordTrace #{number}, &ldquo;{puzzle.title}&rdquo;.
          </DialogDescription>
        </DialogHeader>

        <div className="grid grid-cols-3 gap-2">
          {stats.map(({ icon: Icon, label, value }) => (
            <div key={label} className="flex flex-col items-center rounded-xl bg-stone-100 py-3">
              <Icon className="mb-1 size-4 text-muted-foreground" />
              <span className="text-lg font-bold tabular-nums text-foreground">{value}</span>
              <span className="text-xs text-muted-foreground">{label}</span>
            </div>
          ))}
        </div>

        <div className="flex flex-wrap justify-center gap-1.5">
          {puzzle.words.map((w) => {
            const c = colorFor(w.colorIndex);
            return (
              <span
                key={w.key}
                className="rounded-md px-2 py-1 text-xs font-bold tracking-wide"
                style={{ background: c.tile, color: c.ink }}
              >
                {w.text}
              </span>
            );
          })}
        </div>

        <p className="text-center text-sm text-muted-foreground">
          {isToday ? "A fresh board unlocks at midnight." : "Nice work on the archive puzzle."}
        </p>

        <DialogFooter className="flex-col gap-2 sm:flex-col">
          <Button size="lg" className="w-full bg-indigo-600 text-white hover:bg-indigo-700" onClick={onShare}>
            <Share2 /> Share result
          </Button>
          {onPlayPrevious && (
            <Button size="lg" variant="outline" className="w-full" onClick={onPlayPrevious}>
              Play the previous day
            </Button>
          )}
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}
