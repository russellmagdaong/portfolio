import { test, before, after } from 'node:test';
import assert from 'node:assert/strict';
import { BASE, openPage } from './browser.mjs';

// The six rooms' panels: each in its room's material, never taller than the room, readable, and
// clear of the things left in view (docs/superpowers/specs/2026-11-18-scene-sections-design.md).
const MATERIAL = { home: 'cork', school: 'chalk', arcade: 'cabinet', store: 'pegboard', 'trophy-shop': 'case', 'post-office': 'airmail' };
const WORD = { home: 'HOME', school: 'ABOUT ME', arcade: 'PROJECTS', store: 'TOOLS', 'trophy-shop': 'AWARDS', 'post-office': 'CONTACT' };
const wait = (ms) => new Promise((r) => setTimeout(r, ms));

let page;
before(async () => (page = await openPage('/')));
after(async () => page?.close());

// Every item, and every tab of every item, shown in turn: the panel must stay inside its room and
// its detail must fit without scrolling.
const FIT = `(async () => {
  const bad = [];
  const check = (panel, what) => {
    const stage = panel.closest('.t-stage');
    const p = panel.getBoundingClientRect();
    const s = stage.getBoundingClientRect();
    const details = panel.querySelector('.t-details');
    if (p.bottom > s.bottom + 0.5) bad.push(what + ': panel past the room by ' + Math.round(p.bottom - s.bottom) + 'px');
    if (panel.offsetHeight > 500) bad.push(what + ': panel ' + panel.offsetHeight + 'px tall');
    if (details.scrollHeight > details.clientHeight + 1) bad.push(what + ': detail overflows by ' + (details.scrollHeight - details.clientHeight) + 'px');
  };
  for (const panel of document.querySelectorAll('[data-panel][data-live]')) {
    const place = panel.closest('[data-place]').dataset.place;
    const items = [...panel.querySelectorAll('.t-item')];
    if (!items.length) check(panel, place);
    for (const item of items) {
      item.click();
      // A certificate plaque opens its window: close it, to measure the detail it shows in the case.
      document.querySelector('dialog[open]')?.close();
      await new Promise((r) => setTimeout(r, 30));
      const detail = panel.querySelector('.t-detail:not([hidden])');
      const tabs = [...detail.querySelectorAll('.t-tab')];
      if (!tabs.length) check(panel, place + '/' + item.dataset.item);
      for (const tab of tabs) {
        tab.click();
        await new Promise((r) => setTimeout(r, 30));
        check(panel, place + '/' + item.dataset.item + '/' + tab.dataset.tab);
      }
    }
    items[0]?.click();
  }
  return bad;
})()`;

test('every panel fits inside its room, with the sidebar open and folded', async () => {
  await page.evaluate(`Promise.all([...document.querySelectorAll('.t-stage img')].map((i) => { i.loading = 'eager'; return i.decode().catch(() => {}); })).then(() => document.fonts.ready).then(() => 1)`);
  assert.deepEqual(await page.evaluate(FIT), [], 'open');
  await page.evaluate(`document.querySelector('[data-side-fold]').click(), 1`);
  await wait(300);
  assert.deepEqual(await page.evaluate(FIT), [], 'folded');
  await page.evaluate(`document.querySelector('[data-side-fold]').click(), 1`);
});

test('every room shows its material and its sign', async () => {
  const r = await page.evaluate(`Object.fromEntries([...document.querySelectorAll('.tsite > section[data-place]:not([data-front])')].map((s) => {
    const panel = s.querySelector('.t-stage > .t-panel');
    return [s.dataset.place, { material: panel?.dataset.material ?? null, word: panel?.querySelector('.t-sign')?.textContent.trim() ?? null, logo: !!panel?.querySelector('.t-sign img') }];
  }))`);
  for (const [place, material] of Object.entries(MATERIAL)) {
    assert.equal(r[place]?.material, material, `${place} material`);
    assert.equal(r[place]?.word, WORD[place], `${place} sign word`);
    assert.ok(r[place]?.logo, `${place} sign logo`);
  }
});

test('panel text is readable on its panel', async () => {
  const low = await page.evaluate(`(() => {
    const rgb = (c) => (c.match(/[\\d.]+/g) || []).map(Number);
    const lum = ([r, g, b]) => [r, g, b].map((v) => { v /= 255; return v <= 0.03928 ? v / 12.92 : ((v + 0.055) / 1.055) ** 2.4; }).reduce((a, v, i) => a + v * [0.2126, 0.7152, 0.0722][i], 0);
    const ground = (el) => { for (let e = el; e; e = e.parentElement) { const c = rgb(getComputedStyle(e).backgroundColor); if (c.length >= 3 && (c[3] ?? 1) > 0.9) return c; } return [13, 11, 26]; };
    const out = [];
    document.querySelectorAll('[data-panel][data-live] .t-detail:not([hidden]) :is(p, li, dd, dt, label)').forEach((el) => {
      if (!el.textContent.trim() || el.closest('[hidden]')) return;
      const a = lum(rgb(getComputedStyle(el).color)), b = lum(ground(el));
      const ratio = (Math.max(a, b) + 0.05) / (Math.min(a, b) + 0.05);
      if (ratio < 4.5) out.push(el.closest('[data-place]').dataset.place + ': ' + el.textContent.trim().slice(0, 30) + ' ' + ratio.toFixed(2));
    });
    return out;
  })()`);
  assert.deepEqual(low, []);
});

test('the things left in view stay clear of the panel', async () => {
  const r = await page.evaluate(`(() => {
    const hit = (a, b) => a.left < b.right && b.left < a.right && a.top < b.bottom && b.top < a.bottom;
    const out = [];
    for (const [sec, ids] of [['#sec-projects', ['odin', 'tako', 'algebrawl']], ['#sec-tools', ['tools-backend-and-data', 'tools-also-comfortable-in']]]) {
      const panel = document.querySelector(sec + ' .t-panel').getBoundingClientRect();
      for (const id of ids) {
        const t = document.querySelector(sec + ' .t-target[data-target="' + id + '"]');
        if (!t || hit(t.getBoundingClientRect(), panel)) out.push(id);
      }
    }
    return out;
  })()`);
  assert.deepEqual(r, []);
});

test('a certificate category opens its window', async () => {
  await page.evaluate(`document.querySelector('[data-cert-category="ctfs"]').click(), 1`);
  await wait(300);
  assert.equal(await page.evaluate(`!!document.querySelector('dialog[data-cert-window][open] [data-spot="certs-ctfs"]')`), true, 'the grid is in the window');
  await page.evaluate(`document.querySelector('dialog[data-cert-window] [data-cert-open]').click(), 1`);
  await wait(200);
  const first = await page.evaluate(`document.querySelector('dialog[data-cert-window] [data-cert-large]:not([hidden]) img')?.getAttribute('src') ?? ''`);
  assert.ok(first, 'a certificate shows large');
  await page.evaluate(`document.querySelector('dialog[data-cert-window] [data-cert-next]').click(), 1`);
  await wait(200);
  const second = await page.evaluate(`document.querySelector('dialog[data-cert-window] [data-cert-large]:not([hidden]) img')?.getAttribute('src') ?? ''`);
  assert.ok(second && second !== first, 'next shows the next one');
  await page.key('Escape');
  await wait(200);
  const after = await page.evaluate(`({ open: !!document.querySelector('dialog[data-cert-window][open]'), back: !!document.querySelector('#sec-credentials [data-spot="certs-ctfs"]'), focus: document.activeElement?.dataset.certCategory ?? null })`);
  assert.equal(after.open, false);
  assert.equal(after.back, true, 'the grid is back in its section');
  assert.equal(after.focus, 'ctfs', 'focus back on the category');
});

test('a frame in the trophy shop opens its window too', async () => {
  await page.evaluate(`document.querySelector('#sec-credentials .t-target[data-target^="certs-"]').click(), 1`);
  await wait(300);
  assert.equal(await page.evaluate(`!!document.querySelector('dialog[data-cert-window][open]')`), true);
  await page.key('Escape');
});

test('the rooms ask for nothing they cannot show: every button in a room stands for something in its panel', async () => {
  const r = await page.evaluate(`[...document.querySelectorAll('.t-stage .t-target')].filter((t) => {
    const panel = t.closest('.t-stage').querySelector('[data-panel]');
    const id = t.dataset.target;
    return !panel.querySelector('[data-detail="' + id + '"], [data-spot="' + id + '"], [data-cert-category="' + id.replace(/^certs-/, '') + '"]');
  }).map((t) => t.dataset.target)`);
  assert.deepEqual(r, []);
});

test("after a reload every room's panel is live", async () => {
  await page.navigate(BASE + '/');
  assert.ok(await page.evaluate(`document.querySelectorAll('[data-panel][data-live]').length`) === 6);
});
