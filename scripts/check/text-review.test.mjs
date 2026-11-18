// Fixes from the finish review of the text page (2026-11-18).
import { test, before, after } from 'node:test';
import assert from 'node:assert/strict';
import { openPage } from './browser.mjs';

let page;
before(async () => (page = await openPage('/')));
after(async () => page?.close());

test('About does not repeat the letter', async () => {
  const r = await page.evaluate(`(() => {
    const letter = document.querySelector('#sec-home [data-spot="pc"] p').textContent.trim();
    const about = document.querySelector('#sec-about').innerText;
    const facts = [...document.querySelectorAll('#sec-about [data-spot="profile"] dt')].map((d) => d.textContent.trim());
    return { repeats: about.includes(letter), facts };
  })()`);
  assert.equal(r.repeats, false, "the letter's opening paragraph is not in About");
  for (const f of ['Open to', 'Thesis', 'Now building']) assert.ok(!r.facts.includes(f), `${f} is already on the back`);
});

test('the P.S. is one line per role', async () => {
  assert.equal(await page.evaluate(`document.querySelectorAll('#sec-home [data-ps] li ul').length`), 0);
});

test('the caption under the street says who he is', async () => {
  const caption = await page.evaluate(`document.querySelector('.t-front-caption').textContent`);
  assert.match(caption, /Russell Magdaong/);
  assert.match(caption, /FEU Tech/);
});

test('SEND is set in the pixel label face, like every other button', async () => {
  const r = await page.evaluate(`({
    send: getComputedStyle(document.querySelector('#sec-contact button[type=submit]')).fontFamily,
    pixel: getComputedStyle(document.documentElement).getPropertyValue('--font-pixel').trim(),
  })`);
  assert.equal(r.send, r.pixel);
});

test('"now building" is part of the meta line, not a label over a heading', async () => {
  const r = await page.evaluate(`({
    labels: document.querySelectorAll('.tsite .t-status').length,
    meta: document.querySelector('[data-spot="nova"] .t-project-meta')?.textContent ?? '',
  })`);
  assert.equal(r.labels, 0);
  assert.match(r.meta, /now building/i);
});
