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
//   art/map-objects/<id>.aseprite -> src/assets/map-objects/<id>.png + .json (buildings etc.)
//   art/hub.aseprite            -> src/assets/hub/ (a PNG per layer + hub.json: the front-view street)
//   art/hub-objects/<id>.aseprite -> src/assets/hub-objects/<id>.png + .json (the six destinations on it)
//                                    and src/assets/sign-logos/<id>.png (the icon on its sign)
//   art/objects/<scene>/<id>.aseprite -> src/assets/objects/<scene>/<id>.png + .json (a scene's interactables)
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

// A room's moving layers live in art/anim/<name>.aseprite, apart from its still art (see
// scripts/art/stills.lua); the two are put together before the room is exported.
const animOf = (name) => {
  const file = join(ART, 'anim', `${name}.aseprite`);
  return existsSync(file) ? file : undefined;
};

// Every export to run, in order.
const jobs = [];
for (const file of aseprites(ART)) {
  const name = file.replace(/\.aseprite$/, '');
  const source = join(ART, file);
  if (name === 'map' || name === 'hub') {
    jobs.push({ source, anim: animOf(name), mode: 'layers', out: join(ASSETS, name), name, clean: true });
    continue;
  }
  jobs.push({ source, mode: 'sprite', out: join(ASSETS, 'sprites'), name });
  if (name === 'russell') {
    jobs.push({ source, script: join(ROOT, 'scripts', 'art', 'runner.lua'), out: join(ASSETS, 'runner'), name: 'runner minigame' });
  }
}
for (const file of aseprites(join(ART, 'map-objects'))) {
  const name = file.replace(/\.aseprite$/, '');
  jobs.push({ source: join(ART, 'map-objects', file), mode: 'sprite', out: join(ASSETS, 'map-objects'), name });
}
for (const file of aseprites(join(ART, 'hub-objects'))) {
  const name = file.replace(/\.aseprite$/, '');
  jobs.push({ source: join(ART, 'hub-objects', file), mode: 'sprite', out: join(ASSETS, 'hub-objects'), name });
}
// The scenes' interactable objects, a folder per scene (scripts/art/objects.lua).
const OBJECTS = join(ART, 'objects');
for (const scene of existsSync(OBJECTS) ? readdirSync(OBJECTS).sort() : []) {
  for (const file of aseprites(join(OBJECTS, scene))) {
    const name = file.replace(/.aseprite$/, '');
    jobs.push({ source: join(OBJECTS, scene, file), mode: 'sprite', out: join(ASSETS, 'objects', scene), name });
  }
}
for (const file of aseprites(join(ART, 'scenes'))) {
  const name = file.replace(/\.aseprite$/, '');
  jobs.push({ source: join(ART, 'scenes', file), anim: animOf(name), mode: 'layers', out: join(ASSETS, 'scenes', name), name, clean: true });
}

const filters = process.argv.slice(2).map((f) => f.replaceAll('\\', '/'));
const chosen = jobs.filter((job) => {
  if (filters.length === 0) return true;
  const paths = [job.source, job.anim].filter(Boolean).map((p) => relative(ART, p).replaceAll('\\', '/'));
  return filters.some((f) => paths.some((path) => path.includes(f)));
});
if (chosen.length === 0) {
  console.error(filters.length ? `No file in art/ matches ${filters.join(', ')}.` : 'There is nothing in art/ to export.');
  process.exit(1);
}

let failed = 0;
for (const job of chosen) {
  const label = relative(ROOT, job.source).replaceAll('\\', '/');
  // A room with an anim file: its still and anim files are put together first, and that is exported.
  let file = label;
  if (job.anim) {
    const anim = relative(ROOT, job.anim).replaceAll('\\', '/');
    file = `art/_work/combined/${job.name}.aseprite`;
    const combined = spawnSync(
      ASEPRITE,
      ['-b', '--script-param', `still=${label}`, '--script-param', `anim=${anim}`, '--script-param', `out=${file}`,
        '--script', join(ROOT, 'scripts', 'art', 'combine-stills.lua')],
      { cwd: ROOT, encoding: 'utf8' },
    );
    const said = `${combined.stdout ?? ''}${combined.stderr ?? ''}`.trim();
    if (combined.status !== 0 || !said.includes('COMBINE-OK')) {
      console.log(`${label} + ${anim}`);
      for (const line of said.split(/\r?\n/).filter(Boolean)) console.log(`  ${line}`);
      console.error('  FAILED to put the still and anim files together');
      failed += 1;
      continue;
    }
    for (const line of said.split(/\r?\n/).filter((l) => l && l !== 'COMBINE-OK')) console.log(`  ${line}`);
  }
  console.log(`${label}${job.anim ? ' + its anim file' : ''} (${job.mode ?? 'runner'})`);
  // A scene's folder is emptied first, so a layer that was deleted or renamed
  // does not leave its old image behind.
  if (job.clean) rmSync(job.out, { recursive: true, force: true });
  mkdirSync(job.out, { recursive: true });

  // Paths relative to the repo (Aseprite runs from there), so the JSON holds
  // nothing specific to this machine.
  const params = job.script
    ? ['--script-param', `file=${label}`, '--script-param', `out=${job.out}`]
    : [
        '--script-param', `file=${file}`,
        '--script-param', `source=${label}`,
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

// The shop signs' icons, cut from the shopfronts just exported (scripts/art/sign-logos.lua).
if (chosen.some((job) => job.out === join(ASSETS, 'hub-objects'))) {
  const out = join(ASSETS, 'sign-logos');
  mkdirSync(out, { recursive: true });
  const result = spawnSync(
    ASEPRITE,
    ['-b', '--script-param', `root=${ROOT}`, '--script-param', `out=${out}`, '--script', join(ROOT, 'scripts', 'art', 'sign-logos.lua')],
    { cwd: ROOT, encoding: 'utf8' },
  );
  const said = `${result.stdout ?? ''}${result.stderr ?? ''}`.trim();
  console.log('sign logos (from art/hub-objects)');
  if (said) for (const line of said.split(/\r?\n/)) console.log(`  ${line}`);
  if (result.status !== 0 || said) {
    failed += 1;
    console.error('  FAILED to cut the sign logos');
  }
}

console.log(failed ? `\n${failed} of ${chosen.length} exports failed.` : `\nExported ${chosen.length} file(s) into src/assets/.`);
process.exit(failed ? 1 : 0);
