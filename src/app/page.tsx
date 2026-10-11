import { WordTraceGame } from "@/components/game/wordtrace-game";

export default function Home() {
  return (
    <main className="flex flex-1 flex-col">
      <WordTraceGame />
      <footer className="pb-6 text-center text-xs text-stone-500">
        WordTrace is an independent fan-made puzzle. One new board every day.
      </footer>
    </main>
  );
}
