import { test } from 'node:test';
import assert from 'node:assert/strict';
import { existsSync, readFileSync } from 'node:fs';

const SHIPPED = 'src/assets/fonts/russm-sign.woff2';
const A = ['01110', '10001', '10001', '11111', '10001', '10001', '10001', '00000'];

const load = async () => {
  const { glyphsToFont, toWoff2 } = await import('../art/font/build.mjs');
  const { default: opentype } = await import('opentype.js');
  return { glyphsToFont, toWoff2, opentype };
};

test('a glyph becomes a font with the sign metrics', async () => {
  const { glyphsToFont, opentype } = await load();
  const font = opentype.parse(glyphsToFont({ A }));
  assert.equal(font.unitsPerEm, 1024);
  assert.equal(font.charToGlyph('A').advanceWidth, 768, 'five pixels wide plus a one-pixel gap');
  assert.equal(font.charToGlyph(' ').advanceWidth, 512, 'the space is four pixels');
  assert.ok(font.charToGlyph('A').path.commands.length > 0, 'A has ink');
});

test('lowercase letters draw the capitals', async () => {
  const { glyphsToFont, opentype } = await load();
  const font = opentype.parse(glyphsToFont({ A }));
  assert.equal(font.charToGlyph('a').index, font.charToGlyph('A').index);
});

test('the font is compressed to WOFF2', async () => {
  const { glyphsToFont, toWoff2 } = await load();
  const bytes = await toWoff2(glyphsToFont({ A }));
  assert.equal(Buffer.from(bytes.slice(0, 4)).toString('latin1'), 'wOF2');
});

test('shipped font covers chars.txt', { skip: !existsSync(SHIPPED) && 'the font has not been drawn yet' }, async () => {
  const { opentype } = await load();
  const { default: wawoff2 } = await import('wawoff2');
  const otf = await wawoff2.decompress(readFileSync(SHIPPED));
  const font = opentype.parse(Uint8Array.from(otf).buffer);
  const chars = [...readFileSync('scripts/art/font/chars.txt', 'utf8').trim()];
  for (const ch of [...chars, ' ']) assert.notEqual(font.charToGlyph(ch).index, 0, `no glyph for ${JSON.stringify(ch)}`);
});
