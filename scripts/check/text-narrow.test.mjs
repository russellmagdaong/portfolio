import { test } from 'node:test';
import assert from 'node:assert/strict';
import { openPage } from './browser.mjs';

// The rooms on narrower screens (docs/superpowers/plans/2026-11-18-scene-sections.md, Task 6): the
// page never scrolls sideways; on a phone each panel sits under its room, and a tap on an item
// brings its detail into view.
const wait = (ms) => new Promise((r) => setTimeout(r, ms));

const at = async (width, height, fn) => {
  const page = await openPage('/', { width, height });
  try {
    await page.evaluate(`Promise.all([...document.querySelectorAll('.t-stage img')].map((i) => { i.loading = 'eager'; return i.decode().catch(() => {}); })).then(() => document.fonts.ready).then(() => 1)`);
    return await fn(page);
  } finally {
    await page.close();
  }
};

test('no sideways page scroll', async () => {
  for (const [w, h] of [[1000, 800], [640, 900], [390, 844]]) {
    const r = await at(w, h, (page) => page.evaluate(`({ sw: document.documentElement.scrollWidth, iw: innerWidth })`));
    assert.ok(r.sw <= r.iw, `${w}px: page is ${r.sw}px wide`);
  }
});

test('on a phone the panel sits under its room', async () => {
  const bad = await at(390, 844, (page) =>
    page.evaluate(`[...document.querySelectorAll('.t-stage')].filter((stage) => {
      const panel = stage.querySelector(':scope > .t-panel');
      const art = stage.querySelector('.t-stage-art');
      return !panel || panel.getBoundingClientRect().top < art.getBoundingClientRect().bottom - 1;
    }).map((s) => s.closest('[data-place]').dataset.place)`),
  );
  assert.deepEqual(bad, []);
});

test('on a phone the room scrolls sideways inside its frame, set at its focus', async () => {
  const r = await at(390, 844, (page) =>
    page.evaluate(`[...document.querySelectorAll('.t-stage')].map((s) => ({ place: s.closest('[data-place]').dataset.place, scrolls: s.querySelector('.t-stage-frame')?.scrollWidth > s.querySelector('.t-stage-frame')?.clientWidth, left: s.querySelector('.t-stage-frame')?.scrollLeft, focus: Math.min(parseFloat(s.style.getPropertyValue('--focus')) * 2, s.querySelector('.t-stage-frame')?.scrollWidth - s.querySelector('.t-stage-frame')?.clientWidth) }))`),
  );
  for (const room of r) {
    assert.ok(room.scrolls, `${room.place} scrolls inside its frame`);
    assert.equal(room.left, room.focus, `${room.place} opens at its focus`);
  }
});

test('on a phone a tap shows the detail', async () => {
  const r = await at(390, 844, async (page) => {
    await page.evaluate(`document.querySelector('#sec-projects').scrollIntoView({ behavior: 'instant' }), 1`);
    await page.evaluate(`document.querySelector('[data-item="tako"]').click(), 1`);
    await wait(400);
    return page.evaluate(`(() => { const d = document.querySelector('[data-detail="tako"]'); const b = d.getBoundingClientRect(); return { shown: !d.hidden, top: b.top, ih: innerHeight }; })()`);
  });
  assert.ok(r.shown, 'tako is shown');
  assert.ok(r.top >= 0 && r.top < r.ih, `tako's top is in view (${Math.round(r.top)})`);
});

test('from 900 to 1180px the panel stays over the room', async () => {
  const bad = await at(1000, 800, (page) =>
    page.evaluate(`[...document.querySelectorAll('.t-stage > .t-panel')].filter((panel) => {
      const s = panel.closest('.t-stage').getBoundingClientRect(), p = panel.getBoundingClientRect();
      return getComputedStyle(panel).position !== 'absolute' || p.bottom > s.bottom + 0.5 || p.right > s.right + 0.5;
    }).map((p) => p.closest('[data-place]').dataset.place)`),
  );
  assert.deepEqual(bad, []);
});
