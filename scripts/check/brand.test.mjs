import { test, before, after } from 'node:test';
import assert from 'node:assert/strict';
import { openPage, contrast } from './browser.mjs';

const SIGNS = {
  home: '#46e6e1',
  school: '#be6eff',
  arcade: '#ff4f9a',
  store: '#7cf05a',
  'trophy-shop': '#ffe24d',
  'post-office': '#ff463c',
};

let page;
before(async () => (page = await openPage('/')));
after(async () => page?.close());

const token = (name, sign) =>
  page.evaluate(`(() => {
    const i = document.createElement('i');
    ${sign ? `i.dataset.sign = ${JSON.stringify(sign)};` : ''}
    document.body.append(i);
    const v = getComputedStyle(i).getPropertyValue(${JSON.stringify(name)}).trim().toLowerCase();
    i.remove();
    return v;
  })()`);

test('every place has a sign colour readable on the card', async () => {
  const card = await token('--color-card');
  assert.match(card, /^#[0-9a-f]{6}$/, 'the card colour is a #rrggbb token');
  for (const [id, hex] of Object.entries(SIGNS)) {
    assert.equal(await token('--sign', id), hex, `${id} sign colour`);
    assert.ok(contrast(hex, card) >= 4.5, `${id} on the card: ${contrast(hex, card).toFixed(2)}`);
  }
});

test('text tokens are readable', async () => {
  const [text, soft, ground, card] = await Promise.all(['--color-text', '--color-soft', '--color-ground', '--color-card'].map((t) => token(t)));
  for (const fg of [text, soft]) {
    for (const bg of [ground, card]) {
      assert.match(fg + bg, /^#[0-9a-f]{6}#[0-9a-f]{6}$/, 'tokens are #rrggbb');
      assert.ok(contrast(fg, bg) >= 4.5, `${fg} on ${bg}: ${contrast(fg, bg).toFixed(2)}`);
    }
  }
});
