import { test, before, after } from 'node:test';
import assert from 'node:assert/strict';
import { openPage } from './browser.mjs';

let page;
before(async () => (page = await openPage('/no-such-page')));
after(async () => page?.close());

test('the 404 is a card from the same postcard', async () => {
  const r = await page.evaluate(`(() => {
    const h1s = [...document.querySelectorAll('h1')];
    const title = getComputedStyle(document.documentElement).getPropertyValue('--font-title').trim();
    const h = h1s[0];
    return {
      count: h1s.length,
      text: h?.textContent.trim(),
      font: h && getComputedStyle(h).fontFamily,
      size: h && getComputedStyle(h).fontSize,
      title,
      oldKit: document.querySelectorAll('.font-mono, .text-magenta, .text-head').length,
      links: [...document.querySelectorAll('main a')].map((a) => [a.textContent.trim(), a.getAttribute('href')]),
    };
  })()`);
  assert.equal(r.count, 1, 'one h1');
  assert.equal(r.text, 'Nobody lives here');
  assert.equal(r.font, r.title);
  assert.equal(r.size, '48px');
  assert.equal(r.oldKit, 0);
  assert.deepEqual(r.links.filter(([t]) => t === 'The street' || t === 'Home'), [['The street', '/map'], ['Home', '/']]);
});
