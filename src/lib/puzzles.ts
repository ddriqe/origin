export type RawPuzzle = {
  title: string;
  /** Letter grid. `#` marks a wall tile. */
  letters: string[];
  /** Same shape as `letters`; each open tile is tagged with the key of the word that covers it. */
  regions: string[];
  /** Word for each region key. */
  words: Record<string, string>;
};

export type PuzzleWord = {
  key: string;
  text: string;
  /** Cell indices (row * cols + col) in reading order of the word. */
  path: number[];
  colorIndex: number;
};

export type Puzzle = {
  title: string;
  rows: number;
  cols: number;
  /** Letter per cell, or null for walls. */
  cells: (string | null)[];
  words: PuzzleWord[];
};

export const RAW_PUZZLES: RawPuzzle[] = [
  {
    title: "Coffee Break",
    letters: ["BEANC", "MIL#U", "ASKSP", "U#ROA", "CERTS"],
    regions: ["aaaab", "ccc#b", "ddcbb", "d#eee", "dddee"],
    words: { a: "BEAN", b: "CUPS", c: "MILK", d: "SAUCER", e: "ROAST" },
  },
  {
    title: "In the Garden",
    letters: ["ES#BL", "ELEAO", "DR#FO", "SALAM", "EKPNT"],
    regions: ["aa#bb", "acccb", "ad#cb", "adeeb", "ddeee"],
    words: { a: "SEEDS", b: "BLOOM", c: "LEAF", d: "RAKE", e: "PLANT" },
  },
  {
    title: "Nine to Five",
    letters: ["DESE#", "ATKMA", "SMEMI", "KOJOL", "#BFAX"],
    regions: ["aaab#", "ccabb", "cdddb", "ceedb", "#efff"],
    words: { a: "DESK", b: "EMAIL", c: "TASK", d: "MEMO", e: "JOB", f: "FAX" },
  },
  {
    title: "Forecast",
    letters: ["SHOAR", "H#WIG", "ARENU", "ILC#S", "LOUDT"],
    regions: ["aaabb", "c#abd", "caabd", "cee#d", "ceeed"],
    words: { a: "SHOWER", b: "RAIN", c: "HAIL", d: "GUST", e: "CLOUD" },
  },
  {
    title: "Out of Office",
    letters: ["CKETIS", "I#TOHL", "TLEJOA", "EBY#UN", "A#ENRD", "CHMAPS"],
    regions: ["aaaabb", "a#cccb", "accddb", "eed#db", "e#dddb", "eeffff"],
    words: {
      a: "TICKET",
      b: "ISLAND",
      c: "HOTEL",
      d: "JOURNEY",
      e: "BEACH",
      f: "MAPS",
    },
  },
  {
    title: "Kitchen Shift",
    letters: ["KILLE#", "SWHITB", "PE#SKU", "GPPERT", "ARPOTT", "#LICRE"],
    regions: ["aaaaa#", "acccab", "dd#ccb", "eddddb", "eefffb", "#eeebb"],
    words: {
      a: "SKILLET",
      b: "BUTTER",
      c: "WHISK",
      d: "PEPPER",
      e: "GARLIC",
      f: "POT",
    },
  },
  {
    title: "Low Tide",
    letters: ["CORAT", "REELI", "#WFED", "VASEA", "EEEL#"],
    regions: ["aaaab", "cccab", "#dcbb", "ddeee", "dfff#"],
    words: { a: "CORAL", b: "TIDE", c: "REEF", d: "WAVE", e: "SEA", f: "EEL" },
  },
];

const neighbors = (index: number, rows: number, cols: number): number[] => {
  const r = Math.floor(index / cols);
  const c = index % cols;
  const out: number[] = [];
  if (r > 0) out.push(index - cols);
  if (r < rows - 1) out.push(index + cols);
  if (c > 0) out.push(index - 1);
  if (c < cols - 1) out.push(index + 1);
  return out;
};

export function isAdjacent(a: number, b: number, cols: number): boolean {
  const ra = Math.floor(a / cols);
  const rb = Math.floor(b / cols);
  const ca = a % cols;
  const cb = b % cols;
  return Math.abs(ra - rb) + Math.abs(ca - cb) === 1;
}

/** Finds the path through every tile of a region that spells `word`. */
function findRegionPath(
  word: string,
  region: Set<number>,
  cells: (string | null)[],
  rows: number,
  cols: number,
): number[] | null {
  const dfs = (path: number[], used: Set<number>): number[] | null => {
    if (path.length === word.length) return path;
    const last = path[path.length - 1];
    for (const next of neighbors(last, rows, cols)) {
      if (!region.has(next) || used.has(next)) continue;
      if (cells[next] !== word[path.length]) continue;
      used.add(next);
      const found = dfs([...path, next], used);
      if (found) return found;
      used.delete(next);
    }
    return null;
  };

  for (const start of region) {
    if (cells[start] !== word[0]) continue;
    const found = dfs([start], new Set([start]));
    if (found) return found;
  }
  return null;
}

export function parsePuzzle(raw: RawPuzzle): Puzzle {
  const rows = raw.letters.length;
  const cols = raw.letters[0].length;
  if (raw.regions.length !== rows) throw new Error(`${raw.title}: region rows mismatch`);

  const cells: (string | null)[] = [];
  const regionCells = new Map<string, Set<number>>();

  raw.letters.forEach((line, r) => {
    const regionLine = raw.regions[r];
    if (line.length !== cols || regionLine.length !== cols) {
      throw new Error(`${raw.title}: row ${r} has the wrong width`);
    }
    for (let c = 0; c < cols; c++) {
      const ch = line[c];
      const region = regionLine[c];
      if ((ch === "#") !== (region === "#")) {
        throw new Error(`${raw.title}: wall mismatch at ${r},${c}`);
      }
      if (ch === "#") {
        cells.push(null);
        continue;
      }
      cells.push(ch);
      const set = regionCells.get(region) ?? new Set<number>();
      set.add(r * cols + c);
      regionCells.set(region, set);
    }
  });

  const keys = Object.keys(raw.words).sort();
  const regionKeys = [...regionCells.keys()].sort();
  if (keys.join() !== regionKeys.join()) {
    throw new Error(`${raw.title}: word keys ${keys} do not match regions ${regionKeys}`);
  }

  const words = keys.map((key, i) => {
    const text = raw.words[key];
    const region = regionCells.get(key)!;
    if (region.size !== text.length) {
      throw new Error(`${raw.title}: "${text}" has ${text.length} letters but region ${key} has ${region.size} tiles`);
    }
    const path = findRegionPath(text, region, cells, rows, cols);
    if (!path) throw new Error(`${raw.title}: cannot trace "${text}" through region ${key}`);
    return { key, text, path, colorIndex: i };
  });

  return { title: raw.title, rows, cols, cells, words };
}

export const PUZZLES: Puzzle[] = RAW_PUZZLES.map(parsePuzzle);

/** Puzzle #1 is the one published on this date; one new puzzle unlocks each day after. */
const LAUNCH_DATE = { year: 2026, month: 10, day: 1 };

const dayNumber = (year: number, month: number, day: number) =>
  Math.floor(Date.UTC(year, month - 1, day) / 86_400_000);

export function puzzleNumberForDate(date: Date): number {
  const today = dayNumber(date.getFullYear(), date.getMonth() + 1, date.getDate());
  const launch = dayNumber(LAUNCH_DATE.year, LAUNCH_DATE.month, LAUNCH_DATE.day);
  return Math.max(1, today - launch + 1);
}

export function dateForPuzzleNumber(n: number): Date {
  return new Date(LAUNCH_DATE.year, LAUNCH_DATE.month - 1, LAUNCH_DATE.day + n - 1);
}

export function puzzleForNumber(n: number): Puzzle {
  return PUZZLES[(n - 1) % PUZZLES.length];
}

export function isPalindrome(word: string): boolean {
  return word === [...word].reverse().join("");
}
