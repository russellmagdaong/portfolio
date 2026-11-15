// `npm run art`: exports every .aseprite file in art/ into src/assets/ through
// the Aseprite CLI, so the site never needs Aseprite to build. The exports are
// committed.
//
//   npm run art                 everything
//   npm run art -- scenes/home  only the files whose path contains a filter
//
// Aseprite's path comes from the ASEPRITE environment variable, or else the
// default below. What goes where (art/README.md has the details):
//   art/<name>.aseprite         -> src/assets/sprites/<name>.png + .json
//   art/russell.aseprite        -> also src/assets/runner/ (the runner minigame)
//   art/map.aseprite            -> src/assets/map/ (a PNG per layer + map.json)
//   art/scenes/<name>.aseprite  -> src/assets/scenes/<name>/ (a PNG per layer + <name>.json)
// Files in art/_work/ (git-ignored, may hold template pixels) are never exported.

import { spawnSync } from 'node:child_process';
import { existsSync, mkdirSync, readdirSync, rmSync } from 'node:fs';
import { dirname, join, relative, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const ROOT = resolve(dirname(fileURLToPath(import.meta.url)), '../..');
const ART = join(ROOT, 'art');
const ASSETS = join(ROOT, 'src', 'assets');
const PALETTE = join(ART, 'palette.gpl');
const ASEPRITE = process.env.ASEPRITE || 'C:\\aseprite\\build\\bin\\aseprite.exe';

if (!existsSync(ASEPRITE)) {
  console.error(`Aseprite was not found at ${ASEPRITE}.\nSet the ASEPRITE environment variable to its path and run again.`);
  process.exit(1);
}

const aseprites = (dir) =>
  existsSync(dir) ? readdirSync(dir).filter((f) => f.endsWith('.aseprite')).sort() : [];

// Every export to run, in order.
const jobs = [];
for (const file of aseprites(ART)) {
  const name = file.replace(/\.aseprite$/, '');
  const source = join(ART, file);
  if (name === 'map') {
    jobs.push({ source, mode: 'layers', out: join(ASSETS, 'map'), name, clean: true });
    continue;
  }
  jobs.push({ source, mode: 'sprite', out: join(ASSETS, 'sprites'), name });
  if (name === 'russell') {
    jobs.push({ source, script: join(ROOT, 'scripts', 'art', 'runner.lua'), out: join(ASSETS, 'runner'), name: 'runner minigame' });
  }
}
for (const file of aseprites(join(ART, 'scenes'))) {
  const name = file.replace(/\.aseprite$/, '');
  jobs.push({ source: join(ART, 'scenes', file), mode: 'layers', out: join(ASSETS, 'scenes', name), name, clean: true });
}

const filters = process.argv.slice(2).map((f) => f.replaceAll('\\', '/'));
const chosen = jobs.filter((job) => {
  if (filters.length === 0) return true;
  const path = relative(ART, job.source).replaceAll('\\', '/');
  return filters.some((f) => path.includes(f));
});
if (chosen.length === 0) {
  console.error(filters.length ? `No file in art/ matches ${filters.join(', ')}.` : 'There is nothing in art/ to export.');
  process.exit(1);
}

let failed = 0;
for (const job of chosen) {
  const label = relative(ROOT, job.source).replaceAll('\\', '/');
  console.log(`${label} (${job.mode ?? 'runner'})`);
  // A scene's folder is emptied first, so a layer that was deleted or renamed
  // does not leave its old image behind.
  if (job.clean) rmSync(job.out, { recursive: true, force: true });
  mkdirSync(job.out, { recursive: true });

  // Paths relative to the repo (Aseprite runs from there), so the JSON holds
  // nothing specific to this machine.
  const params = job.script
    ? ['--script-param', `file=${label}`, '--script-param', `out=${job.out}`]
    : [
        '--script-param', `file=${label}`,
        '--script-param', `out=${job.out}`,
        '--script-param', `name=${job.name}`,
        '--script-param', `mode=${job.mode}`,
        '--script-param', `palette=${PALETTE}`,
      ];
  const result = spawnSync(ASEPRITE, ['-b', ...params, '--script', job.script ?? join(ROOT, 'scripts', 'art', 'export.lua')], {
    cwd: ROOT,
    encoding: 'utf8',
  });
  const output = `${result.stdout ?? ''}${result.stderr ?? ''}`.trim();
  const ok = result.status === 0 && (job.script ? /Wrote /.test(output) : output.includes('EXPORT-OK'));
  const shown = output.split(/\r?\n/).filter((line) => line && line !== 'EXPORT-OK');
  for (const line of shown) console.log(line.startsWith('  ') ? line : `  ${line}`);
  if (!ok) {
    failed += 1;
    console.error(`  FAILED${result.error ? `: ${result.error.message}` : ''}`);
  }
}

console.log(failed ? `\n${failed} of ${chosen.length} exports failed.` : `\nExported ${chosen.length} file(s) into src/assets/.`);
process.exit(failed ? 1 : 0);
