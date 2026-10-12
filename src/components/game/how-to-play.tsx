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
  "A miss stays on the board as a dashed line. Tap it to clear it.",
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
