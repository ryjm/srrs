// Writes revlog.json: a synthetic %seer revlog (no user data) in the engine
// input shape of RWKV.md. Deterministic: rerunning reproduces the file.
import { writeFileSync } from "node:fs";

let seed = 0x5eed;
function random() {
  seed = (seed + 0x6d2b79f5) | 0;
  let t = Math.imul(seed ^ (seed >>> 15), 1 | seed);
  t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t;
  return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
}
const pick = (weights) => {
  let x = random() * weights.reduce((a, b) => a + b);
  return weights.findIndex((w) => (x -= w) < 0);
};

const MINUTE = 60_000;
const DAY = 1_440 * MINUTE;
const start = Date.UTC(2026, 6, 1, 7, 30);
const intervals = [10 * MINUTE, DAY, 3 * DAY, 7 * DAY, 16 * DAY, 35 * DAY];
const grades = ["again", "hard", "good", "easy"];
const decks = [["~zod", "spanish"], ["~zod", "physics"], ["~nec", "spanish"]];

const answers = [];
for (let c = 0; c < 36; c++) {
  const [owner, stack] = decks[c % decks.length];
  const item = c % 5 === 0 ? `${c}x-imported` : `card-${c}`;
  let at = start + Math.floor(random() * 20) * DAY + Math.floor(random() * 600) * MINUTE;
  let box = 0;
  let reviewed = false;
  const reviews = 1 + Math.floor(random() * 11);
  for (let i = 0; i < reviews; i++) {
    const grade = box === 0 ? pick([3, 2, 5, 1]) : pick([2, 2, 6, 1]);
    const kind = box !== 0 ? "review" : reviewed ? "relearn" : "learn";
    const think = c === 7 && i === 2 ? 15 * MINUTE : Math.floor(2_000 + random() * 25_000);
    answers.push({ owner, stack, item, grade: grades[grade], kind, shown_at: at - think, answered_at: at });
    reviewed = true;
    box = grade === 0 ? 0 : Math.min(box + 1, intervals.length - 1);
    at += Math.floor(intervals[box] * (0.8 + random() * 0.6));
  }
}
answers.sort((a, b) => a.answered_at - b.answered_at);
const events = answers.map((a, i) => ({ id: i + 1, ...a }));
const now_ms = events.at(-1).answered_at + 2 * DAY + 3 * 3_600_000;
writeFileSync(
  new URL("revlog.json", import.meta.url),
  JSON.stringify({ now_ms, events }, null, 1) + "\n",
);
