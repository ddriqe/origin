export type WordColor = { tile: string; ink: string; pipe: string };

export const WORD_COLORS: WordColor[] = [
  { tile: "#cfe8ff", ink: "#0b3a66", pipe: "#7cb8f2" },
  { tile: "#ffe1c2", ink: "#6b3300", pipe: "#f5a65b" },
  { tile: "#d4f2dc", ink: "#0f4d27", pipe: "#6fcf8d" },
  { tile: "#f1d9ff", ink: "#4b1670", pipe: "#c08ae8" },
  { tile: "#fff1a8", ink: "#5c4a00", pipe: "#e8c93a" },
  { tile: "#ffd6dc", ink: "#6e1022", pipe: "#f2899a" },
  { tile: "#c9f1ee", ink: "#0b4a46", pipe: "#5fcdc4" },
];

export const colorFor = (index: number) => WORD_COLORS[index % WORD_COLORS.length];

export const TRACE_COLOR = { tile: "#3b3bd6", ink: "#ffffff", pipe: "#6c6cf0" };
export const MISS_COLOR = { tile: "#f3f0ec", ink: "#8a5a52", pipe: "#e3b7ae" };
