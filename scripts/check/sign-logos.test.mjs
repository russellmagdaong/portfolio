import { test } from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';

// The icon on each shop's sign, cut from its shopfront by `npm run art` (scripts/art/sign-logos.lua).
const PLACES = ['home', 'school', 'arcade', 'store', 'trophy-shop', 'post-office'];

test('each place has its sign logo, cut to the icon alone', () => {
  for (const id of PLACES) {
    const png = readFileSync(`src/assets/sign-logos/${id}.png`);
    const w = png.readUInt32BE(16);
    const h = png.readUInt32BE(20);
    assert.ok(w >= 6 && w <= 10 && h >= 5 && h <= 10, `${id} ${w}x${h}`);
  }
});
