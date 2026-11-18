import { test, before, after } from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { openPage } from './browser.mjs';

const data = readFileSync('src/data/site.ts', 'utf8');
const slug = (t) => t.toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/^-|-$/g, '');
const toolSpots = [...data.matchAll(/group: '([^']+)',\s*\n\s*items:/g)].map((m) => `tools-${slug(m[1])}`);
const certSpots = [...data.matchAll(/folder: '([^']+)'/g)].map((m) => `certs-${m[1]}`);
const SPOTS = [
  'poster', 'pc', 'mirror', 'music', 'games', 'video', 'ctf', 'hackathons',
  'about', 'profile', 'thesis', 'odin', 'tako', 'algebrawl', 'nova', 'runner',
  'achievements', 'contact', 'socials', ...toolSpots, ...certSpots,
];
const OLD_KIT = '.t-eyebrow, .t-window-bar, .t-lights, .t-live, .t-corner, .t-card-num, .t-meter, .t-roll, .t-tilt, .t-term, .t-display, .t-outline, .t-letter, .t-caret, .t-note, .t-signal, .t-postcard, mark';
const REMOVED_COPY = [
  'Each of these is a cabinet in the arcade',
  'grouped the way the shop shelves them',
  'The things lying around my room',
  'In the game, every part of this portfolio',
  'Click a certificate to see it up close',
];

let page;
before(async () => (page = await openPage('/')));
after(async () => page?.close());

test('the sections run front, letter, then the chapters', async () => {
  const r = await page.evaluate(`[...document.querySelectorAll('.tsite > section')].map((s) => [s.id, s.dataset.place])`);
  assert.deepEqual(r, [
    ['sec-street', 'street'], ['sec-home', 'home'], ['sec-about', 'school'], ['sec-projects', 'arcade'],
    ['sec-tools', 'store'], ['sec-credentials', 'trophy-shop'], ['sec-contact', 'post-office'],
  ]);
});

test('every chapter opens on its room, with a title', async () => {
  const r = await page.evaluate(`[...document.querySelectorAll('.tsite > section[data-chapter]')].map((s) => !!(s.querySelector('.t-stage .t-stage-art') && s.querySelector('.t-stage h2')))`);
  assert.deepEqual(r, [true, true, true, true, true]);
});

test('every spot the game knows is on the page once', async () => {
  const counts = await page.evaluate(`(() => { const c = {}; document.querySelectorAll('.tsite [data-spot]').forEach((e) => { if (!e.closest('[data-front]')) c[e.dataset.spot] = (c[e.dataset.spot] || 0) + 1; }); return c; })()`);
  for (const spot of SPOTS) assert.equal(counts[spot], 1, `data-spot="${spot}"`);
});

test('the old kit is gone', async () => {
  assert.equal(await page.evaluate(`document.querySelectorAll(${JSON.stringify(OLD_KIT.split(", ").map((s) => ".tsite " + s).join(", "))}).length`), 0);
});

test('no heading ends in a full stop', async () => {
  const r = await page.evaluate(`[...document.querySelectorAll('.tsite :is(h1, h2, h3)')].map((h) => h.textContent.trim()).filter((t) => /\\.$/.test(t))`);
  assert.deepEqual(r, []);
});

test('only buttons cast a shadow, nothing glows, and the old fonts are gone', async () => {
  const r = await page.evaluate(`(() => {
    const out = { shadows: [], glows: [], fonts: [] };
    document.querySelectorAll('.tsite *').forEach((el) => {
      const s = getComputedStyle(el);
      const name = el.tagName + '.' + el.className;
      if (s.boxShadow !== 'none' && !el.matches('.t-btn, .btn') && !el.closest('.t-panel, .t-stage') && /(-?[1-9]\\d*px)/.test(s.boxShadow)) out.shadows.push(name + ' ' + s.boxShadow);
      if (s.textShadow !== 'none') out.glows.push(name + ' text-shadow');
      if (/blur\\(|drop-shadow/.test(s.filter)) out.glows.push(name + ' filter');
      if (/Press Start 2P|IBM Plex Mono/.test(s.fontFamily)) out.fonts.push(name);
    });
    return out;
  })()`);
  assert.deepEqual(r.shadows, []);
  assert.deepEqual(r.glows, []);
  assert.deepEqual(r.fonts, []);
});

test('the copy that narrated the game is gone', async () => {
  const text = await page.evaluate('document.body.innerText');
  for (const line of REMOVED_COPY) assert.ok(!text.includes(line), line);
});

test('a certificate opens up close', async () => {
  const open = await page.evaluate(`document.querySelector('.tsite [data-cert-open]').click(); new Promise((r) => setTimeout(() => r(!!document.querySelector('dialog[open]')), 400))`);
  assert.ok(open);
  await page.key('Escape');
});

test('switching from the game lands on the thing, or its section', async () => {
  for (const [spot, target] of [[{ place: 'home', id: 'music' }, '[data-spot="music"]'], [{ place: 'post-office', id: 'testimonials' }, '#sec-contact']]) {
    const r = await page.evaluate(`(() => {
      window.textAt(${JSON.stringify(spot)}, { mark: true });
      return new Promise((done) => setTimeout(() => {
        const el = document.querySelector(${JSON.stringify(target)});
        const top = el.getBoundingClientRect().top;
        done({ inView: top >= 0 && top < innerHeight, marked: el.classList.contains('is-here') });
      }, 400));
    })()`);
    assert.ok(r.inView, `${spot.id} in view`);
    if (spot.id === 'music') assert.ok(r.marked, 'music is marked');
  }
});

test('narrow windows never scroll sideways', async () => {
  for (const [w, h] of [[640, 900], [390, 844]]) {
    const narrow = await openPage('/', { width: w, height: h });
    try {
      assert.ok((await narrow.evaluate('document.documentElement.scrollWidth')) <= w, `${w} px`);
    } finally {
      await narrow.close();
    }
  }
});
