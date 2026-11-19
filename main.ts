// Brainrot Boulevard — make.fun roblox-brainrot-01 entrypoint (Node 22,
// standard library only). v7 adds the Fuse Machine (press G to fuse 3
// same-rarity brainrots into 1 of the next rarity), 12 new brainrots
// (64 -> 76), 9 rarities (Eternal and OG above Transcendent), 6 mutations
// (Void, Cosmic and Glitch above Rainbow), and 100 static decor parts
// in default.project.json (trees, lamps, benches, fence posts).
// `rojo build default.project.json --output game.rbxl` turns src/ and
// default.project.json into game.rbxl, and this program hands the entry in
// by copying game.rbxl, src/, screenshots/ and PLAY.json next to this file
// into /output and writing /output/dossier.json — the summary the judge
// reads — with the vendored make.fun library (vendor/makefun-roblox.ts,
// the kit's copy, unchanged).
//
// The grader runs this program twice in a fresh container with no network,
// a read-only /bot (this repository at the submitted commit) and a writable
// /output, and both runs must write the same bytes. It takes no arguments.
// Outside the grader, MAKEFUN_OUTPUT_DIR stands in for /output:
//   mkdir -p out && MAKEFUN_OUTPUT_DIR=out node main.ts
//
// Names under /output must start with a letter, a digit or _ and hold only
// letters, digits, . _ and -, so anything starting with a dot (.gitkeep,
// .DS_Store, .git) is left out of the copies below; the grader refuses an
// entry whose output holds one.

import { copyFileSync, cpSync, existsSync, mkdirSync, readdirSync, readFileSync, statSync, writeFileSync } from 'node:fs';
import { basename, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { buildDossier } from './vendor/makefun-roblox.ts';

const here = fileURLToPath(new URL('.', import.meta.url));
const out = process.env.MAKEFUN_OUTPUT_DIR ?? '/output';

// Everything the entry hands in, and where it lands in /output.
const HAND_IN = [
  { from: 'game.rbxl', to: 'game.rbxl' },
  { from: 'PLAY.json', to: 'PLAY.json' },
  { from: 'src', to: 'src' },
  { from: 'screenshots', to: 'screenshots' },
] as const;

function isDotted(name: string): boolean {
  return name.startsWith('.');
}

function copyTree(from: string, to: string): void {
  cpSync(from, to, {
    recursive: true,
    // Skip dotted names at every depth: a .gitkeep or .DS_Store anywhere
    // under /output fails the entry.
    filter: (path) => !isDotted(basename(path)),
  });
}

function fail(message: string): never {
  throw new Error(`brainrot-boulevard main.ts: ${message}`);
}

mkdirSync(out, { recursive: true });

for (const item of HAND_IN) {
  const source = join(here, item.from);
  const target = join(out, item.to);
  if (!existsSync(source)) {
    fail(`missing ${item.from} beside main.ts`);
  }
  if (item.from === 'src' || item.from === 'screenshots') {
    copyTree(source, target);
  } else {
    copyFileSync(source, target);
  }
}

// Sanity: the place, the link file and at least one screenshot made it.
const shots = readdirSync(join(out, 'screenshots')).filter((n) => !isDotted(n));
if (shots.length < 3 || shots.length > 4) {
  fail(`expected 3 or 4 screenshots, found ${shots.length}`);
}

// v2 validation: the place must be a real binary Roblox place (Rojo's
// output starts with the <roblox! binary magic), every screenshot must
// fit the gate's 256 KiB cap, and PLAY.json must parse with a matching
// url / place_id pair — a placeholder or a typo here refuses the entry.
const placeBytes = readFileSync(join(out, 'game.rbxl'));
if (placeBytes.length === 0 || placeBytes.subarray(0, 8).toString('ascii') !== '<roblox!') {
  fail('game.rbxl is not a binary Roblox place (missing <roblox! magic)');
}
for (const shot of shots) {
  const size = statSync(join(out, 'screenshots', shot)).size;
  if (size > 262144) {
    fail(`screenshot ${shot} is ${size} bytes, over the 256 KiB cap`);
  }
}
const play = JSON.parse(readFileSync(join(out, 'PLAY.json'), 'utf8')) as {
  url: string;
  place_id: number;
  universe_id: number;
};
if (typeof play.url !== 'string' || !play.url.startsWith('https://www.roblox.com/games/')) {
  fail('PLAY.json url is not a Roblox games link');
}
if (play.url !== `https://www.roblox.com/games/${play.place_id}` && !play.url.startsWith(`https://www.roblox.com/games/${play.place_id}/`)) {
  fail('PLAY.json url does not match its place_id');
}
if (!Number.isInteger(play.place_id) || !Number.isInteger(play.universe_id)) {
  fail('PLAY.json place_id / universe_id must be integers');
}
const srcCount = readdirSync(join(out, 'src'), { recursive: true }).filter(
  (n) => typeof n === 'string' && n.endsWith('.luau'),
).length;

// v3 validation: the four new services must exist as files (the Rojo
// build maps src/server/ to ModuleScripts, so a missing file would
// silently drop a whole system from the place), and the v3 cast must
// be present in BrainrotData. Count the v3 lines so the build summary
// shows what this version added over v2.5's 4,492 counted lines.
const V3_SERVICES = ['TradeService', 'RaidService', 'MinigameService', 'TeamService'];
for (const service of V3_SERVICES) {
  if (!existsSync(join(out, 'src', 'server', `${service}.luau`))) {
    fail(`missing v3 service src/server/${service}.luau`);
  }
}
const brainrotData = readFileSync(join(out, 'src', 'shared', 'BrainrotData.luau'), 'utf8');
const castCount = (brainrotData.match(/\{ id = "/g) ?? []).length;
if (castCount < 76) {
  fail(`expected 76 brainrots in BrainrotData, found ${castCount}`);
}
const v3LineCounts: Record<string, number> = {};
for (const service of V3_SERVICES) {
  const text = readFileSync(join(out, 'src', 'server', `${service}.luau`), 'utf8');
  v3LineCounts[service] = text.split('\n').length - 1;
}
const v3ServiceLines = Object.values(v3LineCounts).reduce((a, b) => a + b, 0);

// v7 validation: the fuse service must exist as a file, same pattern as
// the v3 services above — a missing file would silently drop the whole
// Fuse Machine from the place while the build still succeeded.
const V7_SERVICES = ['FuseService'];
for (const service of V7_SERVICES) {
  if (!existsSync(join(out, 'src', 'server', `${service}.luau`))) {
    fail(`missing v7 service src/server/${service}.luau`);
  }
}
const v7LineCounts: Record<string, number> = {};
for (const service of V7_SERVICES) {
  const text = readFileSync(join(out, 'src', 'server', `${service}.luau`), 'utf8');
  v7LineCounts[service] = text.split('\n').length - 1;
}
const v7ServiceLines = Object.values(v7LineCounts).reduce((a, b) => a + b, 0);

// v3 build summary (stdout only — it never lands in /output, so both
// grader runs stay byte-identical): what the entry hands in, at a glance.
console.log(
  `brainrot-boulevard v7: place ${placeBytes.length} bytes, ${srcCount} Luau scripts, ` +
    `${shots.length} screenshots, PLAY place_id=${play.place_id} universe_id=${play.universe_id}, ` +
    `${castCount} brainrots, v3 services ${v3ServiceLines} lines ` +
    `(${V3_SERVICES.map((s) => `${s}=${v3LineCounts[s]}`).join(', ')}), ` +
    `v7 services ${v7ServiceLines} lines ` +
    `(${V7_SERVICES.map((s) => `${s}=${v7LineCounts[s]}`).join(', ')})`,
);

// The scorer's own caps (from the kit's reference/gate.json): only
// text_max_bytes shapes the dossier text; the other caps refuse an entry
// the scorer would refuse anyway (more than 4 screenshots or one over
// 256 KiB; a place over 500,000 instances, scripts over 8 MiB of source,
// or script paths over 1,048,576 characters in all).
writeFileSync(
  join(out, 'dossier.json'),
  buildDossier(out, {
    text_max_bytes: 65536,
    screenshots: { max: 4, max_bytes: 262144 },
    max_instances: 500000,
    scripts_max_source_bytes: 8388608,
    scripts_max_path_chars: 1048576,
  }),
);
