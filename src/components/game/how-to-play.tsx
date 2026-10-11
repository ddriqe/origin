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
  {
    title: "Trace a word",
    body: "Press on a letter and drag through neighbouring tiles: up, down, left or right. Never diagonally, and never through the striped walls. Release to submit.",
  },
  {
    title: "Use every tile once",
    body: "The hidden words fit together like a jigsaw. Every open tile belongs to exactly one word, and words never overlap.",
  },
  {
    title: "Read the rows",
    body: "The rows under the board tell you how many words are hidden and how long each one is, shortest first. Found words lock in and fill a row.",
  },
  {
    title: "Misses stay put",
    body: "A trace that isn't one of the answers stays on the board, dashed. Tap it to clear it. Spelling a real word on the wrong tiles still counts as a miss.",
  },
];

export function HowToPlay({ open, onOpenChange }: { open: boolean; onOpenChange: (open: boolean) => void }) {
  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="sm:max-w-md">
        <DialogHeader>
          <DialogTitle className="text-xl">How to play WordTrace</DialogTitle>
          <DialogDescription>Find every hidden word and cover the whole board.</DialogDescription>
        </DialogHeader>

        <MiniExample />

        <ol className="space-y-3">
          {RULES.map((rule, i) => (
            <li key={rule.title} className="flex gap-3">
              <span className="flex size-6 shrink-0 items-center justify-center rounded-full bg-indigo-600 text-xs font-bold text-white">
                {i + 1}
              </span>
              <div>
                <p className="font-semibold text-foreground">{rule.title}</p>
                <p className="text-muted-foreground">{rule.body}</p>
              </div>
            </li>
          ))}
        </ol>

        <p className="text-muted-foreground">
          Stuck? <span className="font-medium text-foreground">Hint</span> reveals the next letter of a word on the
          board. A new puzzle unlocks every day at midnight, and you can replay past days with the arrows.
        </p>

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
