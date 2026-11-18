import { test, before, after } from 'node:test';
import assert from 'node:assert/strict';
import { openPage } from './browser.mjs';

let page;
before(async () => (page = await openPage('/')));
after(async () => page?.close());

test('the back of the postcard is a letter from Russell', async () => {
  const r = await page.evaluate(`(() => {
    const home = document.getElementById('sec-home');
    return {
      h1: home.querySelector('h1')?.textContent.trim(),
      stamp: !!home.querySelector('[data-spot="mirror"] img'),
      postmark: home.querySelector('[data-postmark]')?.textContent.trim(),
      ps: [...home.querySelectorAll('[data-ps] li[data-spot]')].map((li) => li.dataset.spot),
    };
  })()`);
  assert.equal(r.h1, "Hi, I'm Russell Magdaong");
  assert.ok(r.stamp, 'the stamp is his photo');
  assert.equal(r.postmark, 'Manila · November 2026');
  assert.deepEqual(r.ps, ['music', 'games', 'video', 'ctf', 'hackathons']);
});

test('the nav lists the six places in chapter order', async () => {
  const labels = await page.evaluate(`[...document.querySelectorAll('[data-t-header] nav a[data-goto]')].map((a) => a.textContent.trim())`);
  assert.deepEqual(labels, ['Home', 'About', 'Projects', 'Tools', 'Credentials', 'Contact']);
});

test('the nav bar appears once the street is out of view', async () => {
  await page.evaluate('scrollTo(0, 0)');
  await page.evaluate('new Promise((r) => setTimeout(r, 300))');
  assert.equal(await page.evaluate(`document.querySelector('[data-t-header]').hasAttribute('data-past-front')`), false);
  await page.evaluate(`document.getElementById('sec-projects').scrollIntoView({ behavior: 'instant' }); new Promise((r) => setTimeout(r, 500))`);
  const r = await page.evaluate(`({
    past: document.querySelector('[data-t-header]').hasAttribute('data-past-front'),
    current: document.querySelector('[data-t-header] nav a[aria-current]')?.textContent.trim(),
  })`);
  assert.equal(r.past, true);
  assert.equal(r.current, 'Projects');
});

test('no empty links, and no résumé line without a résumé', async () => {
  const r = await page.evaluate(`({
    empty: [...document.querySelectorAll('.tsite a')].filter((a) => !a.getAttribute('href') || (!a.textContent.trim() && !a.getAttribute('aria-label'))).map((a) => a.outerHTML.slice(0, 80)),
    resume: [...document.querySelectorAll('.tsite *')].some((el) => el.children.length === 0 && el.textContent.trim() === 'Résumé'),
  })`);
  assert.deepEqual(r.empty, []);
  assert.equal(r.resume, false);
});
