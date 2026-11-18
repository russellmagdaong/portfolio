import { test, before, after } from 'node:test';
import assert from 'node:assert/strict';
import { BASE, openPage } from './browser.mjs';

// The sidebar on wide screens (docs/superpowers/specs/2026-11-18-scene-sections-design.md).
const ORDER = ['home', 'school', 'arcade', 'store', 'trophy-shop', 'post-office'];
const wait = (ms) => new Promise((r) => setTimeout(r, ms));

let page;
before(async () => (page = await openPage('/')));
after(async () => page?.close());

test('the sidebar lists the six places with their sign logos', async () => {
  const r = await page.evaluate(`[...document.querySelectorAll('.t-side-nav a[data-goto]')].map((a) => {
    const img = a.querySelector('img');
    return { place: a.dataset.goto, logo: !!img && img.naturalWidth > 0 && img.width === img.naturalWidth * 2 };
  })`);
  assert.deepEqual(r.map((x) => x.place), ORDER);
  for (const x of r) assert.ok(x.logo, `${x.place} logo at 2x`);
});

test('the current entry follows the section being read', async () => {
  await page.evaluate(`window.textAt({ place: 'store', id: null })`);
  await wait(300);
  assert.equal(await page.evaluate(`document.querySelector('.t-side [aria-current="location"]')?.dataset.goto`), 'store');
});

test('the sidebar never moves the scroll', async () => {
  const r = await page.evaluate(`(() => { scrollTo({ top: 3000, behavior: 'instant' }); return new Promise((done) => setTimeout(() => done({ pos: getComputedStyle(document.querySelector('.t-side')).position, y: scrollY }), 300)); })()`);
  assert.equal(r.pos, 'sticky');
  assert.equal(r.y, 3000);
});

test('folding is remembered, and junk in storage opens it', async () => {
  await page.evaluate(`document.querySelector('.t-side [data-side-fold]').click()`);
  assert.equal(await page.evaluate(`document.documentElement.dataset.side`), 'folded');
  await page.navigate(BASE + '/');
  assert.equal(await page.evaluate(`document.documentElement.dataset.side`), 'folded');
  assert.equal(await page.evaluate(`(() => { const i = document.querySelector('.t-side img'); return i.width === i.naturalWidth * 3; })()`), true, 'logos at 3x when folded');
  await page.evaluate(`localStorage.setItem('t-side', 'junk')`);
  await page.navigate(BASE + '/');
  assert.equal(await page.evaluate(`document.documentElement.dataset.side`), 'open');
  await page.evaluate(`localStorage.removeItem('t-side')`);
});

test('below 1181px the top bar is back', async () => {
  const narrow = await openPage('/', { width: 1100, height: 887 });
  try {
    const r = await narrow.evaluate(`({ side: getComputedStyle(document.querySelector('.t-side')).display, header: getComputedStyle(document.querySelector('.t-header')).display })`);
    assert.equal(r.side, 'none');
    assert.notEqual(r.header, 'none');
  } finally {
    await narrow.close();
  }
});
