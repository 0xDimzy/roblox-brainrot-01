// Brainrot Boulevard — make.fun roblox-brainrot-01 entrypoint (Node 22,
// standard library only). The game is the Rojo project in this directory:
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

import { copyFileSync, cpSync, existsSync, mkdirSync, readdirSync, writeFileSync } from 'node:fs';
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
