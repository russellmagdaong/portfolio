import { test } from 'node:test';
import assert from 'node:assert/strict';
import { openPage } from './browser.mjs';

const PLACES = ['home', 'school', 'arcade', 'store', 'trophy-shop', 'post-office'];

async function withPage(path, opts, fn) {
  const page = await openPage(path, opts);
  try {
    return await fn(page);
  } finally {
    await page.close();
  }
}

test('front shows the real street at 3x', () =>
  withPage('/', {}, async (page) => {
    const r = await page.evaluate(`(() => {
      const front = document.querySelector('[data-front]');
      const stage = front.querySelector('[data-front-stage]').getBoundingClientRect();
      const links = [...front.querySelectorAll('[data-front-stage] a[data-goto]')];
      const home = front.querySelector('a[data-spot="home"]').getBoundingClientRect();
      return { spots: links.map((a) => a.dataset.spot).sort(), stageWidth: stage.width, home: [home.left - stage.left, home.top - stage.top, home.width, home.height] };
    })()`);
    assert.deepEqual(r.spots, [...PLACES].sort());
    assert.equal(r.stageWidth, 1440);
    assert.deepEqual(r.home.map(Math.round), [288, 240, 273, 183]);
  }));

// Wider than a phone the street is zoomed to the smallest whole-number scale that covers the frame,
// its ends cropped evenly: no bars beside it, and no scrollbar.
const covers = (width, height, scale) =>
  withPage('/map', { width, height }, async (page) => {
    const r = await page.evaluate(`(() => {
      const scroll = document.querySelector('[data-front-scroll]');
      const clip = document.querySelector('.t-front-clip').getBoundingClientRect();
      const stage = document.querySelector('[data-front-stage]').getBoundingClientRect();
      return { stage: stage.width, left: stage.left - clip.left, right: clip.right - stage.right, sw: scroll.scrollWidth, cw: scroll.clientWidth };
    })()`);
    assert.equal(r.stage, 480 * scale, `${width}px: ${scale}x`);
    assert.ok(r.left <= 4 && r.right <= 4, `${width}px: bars of ${Math.round(r.left)} and ${Math.round(r.right)}px`);
    assert.ok(r.sw <= r.cw, `scroller overflows: ${r.sw} > ${r.cw}`);
  });

test('a laptop zooms the street to 3x, cropped, without a scrollbar', () => covers(1366, 768, 3));

test('a wide screen zooms the street in until it fills the frame', async () => {
  await covers(1920, 1080, 4);
  await covers(2560, 1440, 6);
});

test('phone scrolls the street inside the frame only', () =>
  withPage('/', { width: 390, height: 844 }, async (page) => {
    const r = await page.evaluate(`(() => {
      const scroll = document.querySelector('[data-front-scroll]');
      const list = document.querySelector('[data-front-list]');
      return { page: document.documentElement.scrollWidth, scroll: scroll.scrollWidth, list: getComputedStyle(list).display, links: list.querySelectorAll('a').length };
    })()`);
    assert.ok(r.page <= 390, `page is ${r.page} wide`);
    assert.equal(r.scroll, 960);
    assert.notEqual(r.list, 'none');
    assert.equal(r.links, 6);
  }));

test('russell stands at the last place', async () => {
  for (const [path, at] of [['/', 'home'], ['/projects', 'arcade']]) {
    await withPage(path, {}, async (page) => {
      assert.equal(await page.evaluate(`document.querySelector('[data-front-russell]')?.dataset.at`), at, path);
    });
  }
});

test('keyboard focus lights a sign', () =>
  withPage('/', {}, async (page) => {
    for (let i = 0; i < 60; i++) {
      await page.key('Tab');
      if (await page.evaluate(`document.activeElement?.dataset?.spot === 'arcade' && !!document.activeElement.closest('[data-front]')`)) break;
    }
    const r = await page.evaluate(`(() => {
      const a = document.activeElement;
      const sprite = a.querySelector('[data-front-sprite]');
      return { spot: a.dataset.spot, outline: getComputedStyle(a).outlineStyle, y: getComputedStyle(sprite).backgroundPositionY, hover: sprite.style.getPropertyValue('--hover-y') };
    })()`);
    assert.equal(r.spot, 'arcade');
    assert.notEqual(r.outline, 'none');
    assert.equal(r.y, '-204px', 'the hover row (row 1 of 68 px at 3x)');
  }));

test('reduced motion stills the street', () =>
  withPage('/', { reducedMotion: true }, async (page) => {
    const running = await page.evaluate(`document.getAnimations().filter((a) => a.playState === 'running').map((a) => a.effect?.target?.className || a.animationName)`);
    assert.deepEqual(running, []);
  }));

test('on a phone the street opens scrolled to russell', () =>
  withPage('/projects', { width: 390, height: 844 }, async (page) => {
    const r = await page.evaluate(`(() => {
      const box = document.querySelector('[data-front-scroll]').getBoundingClientRect();
      const me = document.querySelector('[data-front-russell]').getBoundingClientRect();
      return { inside: me.left >= box.left && me.right <= box.right };
    })()`);
    assert.ok(r.inside, 'russell is inside the visible part of the street');
  }));

test('a sign holds each frame for its own duration', () =>
  withPage('/', {}, async (page) => {
    const r = await page.evaluate(`(() => {
      const sprite = document.querySelector('a[data-spot="arcade"] [data-front-sprite]');
      const anim = sprite.getAnimations()[0];
      const frames = anim.effect.getKeyframes().map((k) => Math.round(k.offset * 2080));
      return frames;
    })()`);
    // The arcade's idle tag: 900, 600, 80, 500 ms (2080 in all).
    assert.deepEqual(r.slice(0, 4), [0, 900, 1500, 1580]);
  }));
