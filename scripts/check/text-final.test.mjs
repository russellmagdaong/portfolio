// Fixes from the final code review (2026-11-18): the postcard front as the first section must not
// turn every page into the street, and must not be skipped.
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { openPage, BASE } from './browser.mjs';

async function withPage(path, opts, fn) {
  const page = await openPage(path, opts);
  try {
    return await fn(page);
  } finally {
    await page.close();
  }
}

/** A fresh visit: the chooser is up. */
const fresh = (page, path) =>
  page.evaluate(`sessionStorage.removeItem('mode-chosen'); localStorage.removeItem('mode'); location.href = ${JSON.stringify(BASE + path + '?choose')}; new Promise((r) => setTimeout(r, 2500))`);

test('the home page keeps its own address in text mode', () =>
  withPage('/', {}, async (page) => {
    await page.evaluate('new Promise((r) => setTimeout(r, 800))');
    assert.equal(await page.evaluate('location.pathname'), '/');
  }));

for (const path of ['/', '/map']) {
  test(`choosing text on a first visit to ${path} opens at the postcard's front`, () =>
    withPage(path, {}, async (page) => {
      await fresh(page, path);
      await page.key('ArrowLeft');
      await page.key('Enter');
      // The chooser sweeps away first; the page is placed once it has gone.
      await page.evaluate('new Promise((r) => setTimeout(r, 4000))');
      assert.equal(await page.evaluate('Math.round(scrollY)'), 0);
    }));
}

test('home with nothing named, or anywhere on the street, opens at the very top', () =>
  withPage('/', {}, async (page) => {
    for (const spot of [{ place: 'home', id: null }, { place: 'street', id: 'home' }, { place: 'street', id: null }]) {
      const y = await page.evaluate(
        `scrollTo({ top: 2000, behavior: 'instant' }); window.textAt(${JSON.stringify(spot)}); new Promise((r) => setTimeout(() => r(Math.round(scrollY)), 300))`,
      );
      assert.equal(y, 0, JSON.stringify(spot));
    }
  }));

test('switching to the game from the top of the home page stays in the room', () =>
  withPage('/', {}, async (page) => {
    await page.evaluate(`scrollTo({ top: 0, behavior: 'instant' }); document.querySelector('.t-front [data-change-ui]').click(); new Promise((r) => setTimeout(r, 1500))`);
    await page.key('ArrowRight');
    await page.key('Enter');
    await page.evaluate('new Promise((r) => setTimeout(r, 2500))');
    assert.equal(await page.evaluate('location.pathname'), '/');
  }));

test('every animated layer of the street plays', () =>
  withPage('/', {}, async (page) => {
    const still = await page.evaluate(`[...document.querySelectorAll('.t-front [data-anim]')].filter((el) => !el.getAnimations().length).map((el) => el.getAttribute('style').slice(0, 40))`);
    assert.deepEqual(still, []);
  }));

test("on a phone the chooser's stamp covers nothing", () =>
  withPage('/', { width: 390, height: 844 }, async (page) => {
    await fresh(page, '/');
    const r = await page.evaluate(`(() => {
      const stamp = document.querySelector('.landing-postcard-stamp');
      if (!stamp || !stamp.getClientRects().length || getComputedStyle(stamp).display === 'none') return { hidden: true };
      const a = stamp.getBoundingClientRect();
      const hits = [...document.querySelectorAll('.landing-text .landing-card > :not(.landing-postcard-stamp)')].filter((el) => {
        const b = el.getBoundingClientRect();
        return b.width && a.left < b.right && b.left < a.right && a.top < b.bottom && b.top < a.bottom;
      }).map((el) => el.className);
      return { hidden: false, hits };
    })()`);
    if (!r.hidden) assert.deepEqual(r.hits, []);
  }));

test('with the sign font switched on, a phone page still never scrolls sideways', () =>
  withPage('/', { width: 390, height: 844 }, async (page) => {
    const w = await page.evaluate(`(async () => {
      document.documentElement.style.setProperty('--font-title', '"Russm Sign", "Jersey 10", sans-serif');
      await document.fonts.load('32px "Russm Sign"');
      await new Promise((r) => setTimeout(r, 300));
      return document.documentElement.scrollWidth;
    })()`);
    assert.ok(w <= 390, `page is ${w} px wide`);
  }));
