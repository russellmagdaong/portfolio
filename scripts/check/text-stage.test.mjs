import { test, before, after } from 'node:test';
import assert from 'node:assert/strict';
import { openPage } from './browser.mjs';

// Each section is its place's interior at 2x (docs/superpowers/specs/2026-11-18-scene-sections-design.md).
let page;
before(async () => (page = await openPage('/')));
after(async () => page?.close());

const stageAnimations = `document.getAnimations().filter((a) => a.effect?.target?.closest?.('.t-stage')).length`;

test('every section is a room at 2x', async () => {
  // The rooms load lazily: load them all before measuring.
  await page.evaluate(`Promise.all([...document.querySelectorAll('.t-stage img')].map((i) => { i.loading = 'eager'; return i.decode().catch(() => {}); })).then(() => 1)`);
  const r = await page.evaluate(`[...document.querySelectorAll('.tsite > section[data-place]:not([data-front])')].map((s) => {
    const stages = s.querySelectorAll('.t-stage');
    const stage = stages[0];
    const imgs = stage ? [...stage.querySelectorAll('.t-stage-art img')] : [];
    return {
      place: s.dataset.place,
      stages: stages.length,
      height: stage?.offsetHeight ?? 0,
      imgs: imgs.length,
      wrongScale: imgs.filter((i) => !i.naturalWidth || i.width !== i.naturalWidth * 2).map((i) => i.getAttribute('src')),
      smooth: imgs.filter((i) => getComputedStyle(i).imageRendering !== 'pixelated').length,
    };
  })`);
  assert.deepEqual(r.map((x) => x.place), ['home', 'school', 'arcade', 'store', 'trophy-shop', 'post-office']);
  for (const x of r) {
    assert.equal(x.stages, 1, `${x.place}: one stage`);
    assert.equal(x.height, 540, `${x.place}: as tall as the art at 2x`);
    assert.ok(x.imgs > 3, `${x.place}: its layers`);
    assert.deepEqual(x.wrongScale, [], `${x.place}: every layer at 2x`);
    assert.equal(x.smooth, 0, `${x.place}: pixelated`);
  }
});

test("the game's objects are buttons over the art", async () => {
  const r = await page.evaluate(`[...document.querySelectorAll('#sec-projects .t-target')].map((b) => ({ id: b.dataset.target, tag: b.tagName, label: b.getAttribute('aria-label') ?? '' }))`);
  for (const id of ['odin', 'tako', 'algebrawl', 'nova']) {
    const t = r.find((x) => x.id === id);
    assert.ok(t, `${id} target`);
    assert.equal(t.tag, 'BUTTON');
    assert.ok(t.label.trim().length > 0, `${id} has a name`);
  }
});

test('no glow, no blur on the room', async () => {
  const r = await page.evaluate(`[...document.querySelectorAll('.t-stage *')].filter((el) => { const s = getComputedStyle(el); return s.textShadow !== 'none' || s.filter !== 'none'; }).length`);
  assert.equal(r, 0);
});

test('a room keeps one loop of its own art running', async () => {
  assert.ok((await page.evaluate(stageAnimations)) > 0);
});

test('reduced motion stills the room', async () => {
  const still = await openPage('/', { reducedMotion: true });
  try {
    assert.equal(await still.evaluate(stageAnimations), 0);
  } finally {
    await still.close();
  }
});
