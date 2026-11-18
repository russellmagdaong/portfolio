import { test, before, after } from 'node:test';
import assert from 'node:assert/strict';
import { openPage } from './browser.mjs';

let page;
before(async () => (page = await openPage('/projects', { mode: 'game' })));
after(async () => page?.close());

const style = (selector, props) =>
  page.evaluate(`(() => {
    const el = document.querySelector(${JSON.stringify(selector)});
    if (!el) return null;
    const s = getComputedStyle(el);
    return Object.fromEntries(${JSON.stringify(props)}.map((p) => [p, s.getPropertyValue(p)]));
  })()`);

test('HUD buttons are steel plates from the street', async () => {
  const s = await style('.hud-btn', ['background-color', 'border-left-color', 'border-top-color', 'color']);
  assert.ok(s, 'the HUD is on the page');
  assert.equal(s['background-color'], 'rgb(26, 25, 38)', 'concrete 1 fill');
  assert.equal(s['border-left-color'], 'rgb(75, 76, 100)', 'concrete 4 edge');
  assert.equal(s['border-top-color'], 'rgb(104, 106, 132)', 'concrete 5 top edge');
  assert.equal(s.color, 'rgb(255, 205, 120)', 'sodium 4 label');
});

test('the place name is set in the title lettering', async () => {
  const title = await page.evaluate(`getComputedStyle(document.documentElement).getPropertyValue('--font-title').trim()`);
  const s = await style('.hud-where > span', ['font-family']);
  assert.equal(s['font-family'], title);
});

test('no HUD element keeps the old violet', async () => {
  const hits = await page.evaluate(`[...document.querySelectorAll('.hud, .hud *')].filter((el) => {
    const s = getComputedStyle(el);
    return [s.borderTopColor, s.borderLeftColor, s.backgroundColor].includes('rgb(74, 58, 133)');
  }).map((el) => el.className)`);
  assert.deepEqual(hits, []);
});

test('the key caps stay yellow', async () => {
  const s = await style('.hud-key', ['background-color']);
  assert.equal(s['background-color'], 'rgb(255, 233, 31)');
});

test('the wordmark shows on a phone, with no divider before it', async () => {
  const phone = await openPage('/projects', { mode: 'game', width: 390, height: 844 });
  try {
    const s = await phone.evaluate(`(() => {
      const w = document.querySelector('.hud-name .wordmark');
      return w && { width: w.getBoundingClientRect().width, rule: getComputedStyle(w).borderLeftWidth };
    })()`);
    assert.ok(s && s.width > 0, 'the wordmark is drawn');
    assert.equal(s.rule, '0px');
  } finally {
    await phone.close();
  }
});
