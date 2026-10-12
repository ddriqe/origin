"use client";

import { Button } from "@/components/ui/button";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";

const RULES = [
  "Drag through neighbouring letters: up, down, left, or right. Not diagonally, and not through walls.",
  "Every open tile belongs to one word. The rows show those lengths, shortest first.",
  "A miss flashes as a dashed line, then clears on its own.",
  "Hint reveals the next letter. The arrows replay earlier days.",
];

export function HowToPlay({ open, onOpenChange }: { open: boolean; onOpenChange: (open: boolean) => void }) {
  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="sm:max-w-md">
        <DialogHeader>
          <DialogTitle className="text-xl">How to play</DialogTitle>
          <DialogDescription>Trace every hidden word and cover the whole board.</DialogDescription>
        </DialogHeader>

        <MiniExample />

        <ul className="list-disc space-y-2 pl-5 text-sm text-foreground">
          {RULES.map((rule) => (
            <li key={rule}>{rule}</li>
          ))}
        </ul>

        <DialogFooter>
          <Button className="w-full bg-indigo-600 text-white hover:bg-indigo-700" size="lg" onClick={() => onOpenChange(false)}>
            Let&apos;s play
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}

/** A 3x3 example: CAT bends around a wall and SUN winds through the rest. */
function MiniExample() {
  const cells = [
    { l: "C", w: 0 },
    { l: "A", w: 0 },
    { l: "#", w: -1 },
    { l: "#", w: -1 },
    { l: "T", w: 0 },
    { l: "S", w: 1 },
    { l: "#", w: -1 },
    { l: "N", w: 1 },
    { l: "U", w: 1 },
  ];
  const tones = ["bg-[#cfe8ff] text-[#0b3a66]", "bg-[#ffe1c2] text-[#6b3300]"];
  return (
    <div className="flex items-center justify-center gap-4 rounded-xl bg-stone-100 p-3">
      <div className="grid grid-cols-3 gap-1">
        {cells.map((c, i) =>
          c.l === "#" ? (
            <div key={i} className="size-9 rounded-md bg-[repeating-linear-gradient(135deg,#d9d4cc_0_4px,#cfc9c0_4px_8px)]" />
          ) : (
            <div key={i} className={`flex size-9 items-center justify-center rounded-md font-bold ${tones[c.w]}`}>
              {c.l}
            </div>
          ),
        )}
      </div>
      <div className="space-y-1 text-xs text-muted-foreground">
        <p>
          <span className="font-bold text-[#0b3a66]">CAT</span> bends down around the wall.
        </p>
        <p>
          <span className="font-bold text-[#6b3300]">SUN</span> winds through what&apos;s left.
        </p>
        <p>Every tile used once, so it&apos;s solved.</p>
      </div>
    </div>
  );
}
