/**
 * Builds the sign lettering font (npm run font): reads the glyphs drawn in art/font.aseprite (via
 * dump.lua) and writes src/assets/fonts/russm-sign.woff2, a real font, so titles set in it stay
 * text you can select, find and read aloud.
 *
 * One art pixel is 128 font units and the em is 8 pixels (1024 units), so the font is crisp at
 * 16, 24, 32, 48 and 64 px, where each art pixel is a whole number of screen pixels.
 */
import opentype from 'opentype.js';
import wawoff2 from 'wawoff2';
import { spawnSync } from 'node:child_process';
import { mkdirSync, mkdtempSync, readFileSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { dirname, join, resolve } from 'node:path';
import { fileURLToPath, pathToFileURL } from 'node:url';

const PX = 128;
const CAP = 7; // rows of capital height above the baseline
const SPACE = 4 * PX;
const OUT = 'src/assets/fonts/russm-sign.woff2';

/** One glyph's outline: a rectangle for every horizontal run of ink in each row. */
function outline(rows) {
  const path = new opentype.Path();
  let right = -1;
  rows.forEach((row, y) => {
    const top = (CAP - y) * PX;
    const bottom = top - PX;
    for (let x = 0; x < row.length; x++) {
      if (row[x] !== '1') continue;
      let end = x;
      while (row[end + 1] === '1') end++;
      // Counter-clockwise, as CFF outlines want.
      path.moveTo(x * PX, bottom);
      path.lineTo((end + 1) * PX, bottom);
      path.lineTo((end + 1) * PX, top);
      path.lineTo(x * PX, top);
      path.close();
      right = Math.max(right, end);
      x = end;
    }
  });
  return { path, right };
}

/** @param {Record<string, string[]>} glyphs  char -> 8 rows of "0"/"1" */
export function glyphsToFont(glyphs) {
  const list = [
    new opentype.Glyph({ name: '.notdef', advanceWidth: SPACE, path: new opentype.Path() }),
    new opentype.Glyph({ name: 'space', unicode: 32, advanceWidth: SPACE, path: new opentype.Path() }),
  ];
  for (const [ch, rows] of Object.entries(glyphs)) {
    const code = ch.codePointAt(0);
    const { path, right } = outline(rows);
    const glyph = new opentype.Glyph({
      name: `uni${code.toString(16).toUpperCase().padStart(4, '0')}`,
      unicode: code,
      advanceWidth: right < 0 ? SPACE : (right + 2) * PX,
      path,
    });
    // Capitals only, like the shop signs: a lowercase letter draws its capital. (addUnicode, as
    // opentype.js 1.3.4 ignores the `unicodes` option.)
    if (code >= 65 && code <= 90) glyph.addUnicode(code + 32);
    list.push(glyph);
  }
  const font = new opentype.Font({
    familyName: 'Russm Sign',
    styleName: 'Regular',
    unitsPerEm: 8 * PX,
    ascender: CAP * PX,
    descender: -PX,
    glyphs: list,
  });
  return font.toArrayBuffer();
}

/** @param {ArrayBuffer} otf */
export async function toWoff2(otf) {
  return Uint8Array.from(await wawoff2.compress(new Uint8Array(otf)));
}

async function main() {
  const root = resolve(dirname(fileURLToPath(import.meta.url)), '../../..');
  process.chdir(root);
  const aseprite = process.env.ASEPRITE || 'C:\\aseprite\\build\\bin\\aseprite.exe';
  const json = join(mkdtempSync(join(tmpdir(), 'font-')), 'glyphs.json');
  const run = spawnSync(aseprite, ['-b', '--script', 'scripts/art/font/dump.lua'], { env: { ...process.env, FONT_JSON: json }, encoding: 'utf8' });
  if (run.status !== 0) throw new Error(`Aseprite failed: ${run.stderr || run.stdout}`);
  const glyphs = JSON.parse(readFileSync(json, 'utf8'));
  mkdirSync(dirname(OUT), { recursive: true });
  writeFileSync(OUT, await toWoff2(glyphsToFont(glyphs)));
  console.log(`${OUT}: ${Object.keys(glyphs).length} glyphs`);
}

if (import.meta.url === pathToFileURL(process.argv[1]).href) await main();
