import { test, before, after } from 'node:test';
import assert from 'node:assert/strict';
import { openPage } from './browser.mjs';

// The panel over each room: a list beside one detail, chosen by resting the pointer on an item or a
// thing in the room, by click or by focus (docs/superpowers/specs/2026-11-18-scene-sections-design.md).
let page;
before(async () => (page = await openPage('/')));
after(async () => page?.close());

const wait = (ms) => new Promise((r) => setTimeout(r, ms));
const shown = () => page.evaluate(`[...document.querySelectorAll('#sec-projects .t-detail')].filter((d) => !d.hidden).map((d) => d.dataset.detail)`);
const over = (sel) => page.evaluate(`document.querySelector(${JSON.stringify(sel)}).dispatchEvent(new PointerEvent('pointerover', { bubbles: true, pointerType: 'mouse' })), 1`);
const out = (sel) => page.evaluate(`document.querySelector(${JSON.stringify(sel)}).dispatchEvent(new PointerEvent('pointerout', { bubbles: true, pointerType: 'mouse' })), 1`);

test('the first item shows by default and the rest are findable', async () => {
  assert.deepEqual(await shown(), ['odin']);
  assert.equal(await page.evaluate(`document.querySelector('#sec-projects [data-detail="tako"]').getAttribute('hidden')`), 'until-found');
});

test('resting on an item shows its detail; leaving keeps it', async () => {
  await over('#sec-projects [data-item="tako"]');
  await wait(60);
  assert.deepEqual(await shown(), ['odin'], 'not yet: the pointer is only passing');
  await wait(140);
  assert.deepEqual(await shown(), ['tako']);
  await out('#sec-projects [data-item="tako"]');
  await wait(200);
  assert.deepEqual(await shown(), ['tako'], 'still tako after the pointer leaves');
});

test('passing over an item on the way somewhere else changes nothing', async () => {
  await over('#sec-projects [data-item="nova"]');
  await wait(40);
  await out('#sec-projects [data-item="nova"]');
  await wait(200);
  assert.deepEqual(await shown(), ['tako']);
});

test('a cabinet in the room does the same', async () => {
  await over('#sec-projects .t-target[data-target="algebrawl"]');
  await wait(200);
  assert.deepEqual(await shown(), ['algebrawl']);
  assert.equal(await page.evaluate(`document.querySelector('#sec-projects .t-target[data-target="algebrawl"]').hasAttribute('data-on')`), true);
  assert.equal(await page.evaluate(`document.querySelector('#sec-projects [data-item="algebrawl"]').getAttribute('aria-pressed')`), 'true');
});

test('click and keyboard focus are instant', async () => {
  await page.evaluate(`document.querySelector('#sec-projects [data-item="runner"]').click(), 1`);
  assert.deepEqual(await shown(), ['runner'], 'click');
  // Headless Edge has no focused window, so focus() moves focus without firing focusin: send it as the browser would.
  await page.evaluate(`(() => { const b = document.querySelector('#sec-projects [data-item="nova"]'); b.focus(); b.dispatchEvent(new FocusEvent('focusin', { bubbles: true })); return 1; })()`);
  assert.deepEqual(await shown(), ['nova'], 'focus');
});

test('Esc goes back to the first', async () => {
  await page.key('Escape');
  assert.deepEqual(await shown(), ['odin']);
});

test('find-in-page opens the detail it found', async () => {
  await page.evaluate(`document.querySelector('#sec-projects [data-detail="tako"]').dispatchEvent(new Event('beforematch', { bubbles: true })), 1`);
  assert.deepEqual(await shown(), ['tako']);
});

test('a detail keeps its tabs: one shows, the rest are findable', async () => {
  const r = await page.evaluate(`(() => {
    const d = document.querySelector('#sec-projects [data-detail="odin"]');
    return [...d.querySelectorAll('[data-tab-panel]')].map((p) => [p.dataset.tabPanel, p.getAttribute('hidden')]);
  })()`);
  assert.deepEqual(r[0], ['overview', null]);
  for (const [, hidden] of r.slice(1)) assert.equal(hidden, 'until-found');
});

test('arriving from the game shows that thing', async () => {
  await page.evaluate(`window.textAt({ place: 'arcade', id: 'algebrawl' }, { mark: true }), 1`);
  await wait(400);
  assert.deepEqual(await shown(), ['algebrawl']);
  assert.equal(await page.evaluate(`document.querySelector('[data-spot="algebrawl"]').classList.contains('is-here')`), true);
});

test('the text page reports the thing showing', async () => {
  await page.evaluate(`document.querySelector('#sec-projects [data-item="tako"]').click(), 1`);
  await page.evaluate(`window.textAt({ place: 'arcade', id: null }), 1`);
  await wait(300);
  assert.deepEqual(await page.evaluate(`window.textSpot()`), { place: 'arcade', id: 'tako' });
});

test('without the script, every detail is in the page', async () => {
  const r = await page.evaluate(`fetch(location.href).then((res) => res.text()).then((html) => {
    const doc = new DOMParser().parseFromString(html, 'text/html');
    return { details: doc.querySelectorAll('#sec-projects .t-detail').length, hidden: doc.querySelectorAll('.t-detail[hidden], [data-tab-panel][hidden]').length, live: doc.querySelectorAll('[data-live]').length };
  })`);
  assert.ok(r.details >= 5);
  assert.equal(r.hidden, 0);
  assert.equal(r.live, 0);
});
