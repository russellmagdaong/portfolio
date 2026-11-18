import { test } from 'node:test';
import assert from 'node:assert/strict';
import { openPage, BASE } from './browser.mjs';

/** The chooser on a fresh visit: no mode chosen this session. */
async function chooser(width, height) {
  const page = await openPage('/', { width, height });
  await page.evaluate(`sessionStorage.removeItem('mode-chosen'); localStorage.removeItem('mode'); location.href = ${JSON.stringify(BASE + '/?choose')}; 1`);
  await page.evaluate('new Promise((r) => setTimeout(r, 2500))');
  return page;
}

const drawn = `(() => {
  const c = document.querySelector('[data-landing-street]');
  if (!c || !c.width || !c.height) return 0;
  const data = c.getContext('2d').getImageData(0, 0, c.width, c.height).data;
  let n = 0;
  for (let i = 3; i < data.length; i += 4) if (data[i] > 0) n++;
  return n;
})()`;

for (const [w, h] of [[1469, 887], [390, 844]]) {
  test(`the street draws behind the game side at ${w} px`, async () => {
    const page = await chooser(w, h);
    try {
      assert.ok((await page.evaluate(drawn)) > 1000, 'the canvas has the street on it');
    } finally {
      await page.close();
    }
  });
}

test('the chooser is the postcard, not the old kit', async () => {
  const page = await chooser(1469, 887);
  try {
    const r = await page.evaluate(`(() => {
      const land = document.querySelector('[data-landing]');
      const title = document.getElementById('landing-title');
      return {
        oldKit: land.querySelectorAll('mark, .landing-tags, .landing-or, .landing-paper').length,
        grey: [...land.querySelectorAll('*')].filter((el) => /grayscale/.test(getComputedStyle(el).filter)).length,
        titleFont: getComputedStyle(title).fontFamily,
        fontTitle: getComputedStyle(document.documentElement).getPropertyValue('--font-title').trim(),
        postcard: !!land.querySelector('[data-landing-postcard] [data-postmark]'),
      };
    })()`);
    assert.equal(r.oldKit, 0);
    assert.equal(r.grey, 0, 'the unpicked side is not greyed out');
    assert.equal(r.titleFont, r.fontTitle);
    assert.ok(r.postcard, 'the text side previews the postcard back');
  } finally {
    await page.close();
  }
});

test('the keys still choose', async () => {
  const page = await chooser(1469, 887);
  try {
    await page.key('ArrowLeft');
    assert.equal(await page.evaluate(`document.querySelector('[data-landing]').dataset.lean`), 'text');
    await page.key('Enter');
    await page.evaluate('new Promise((r) => setTimeout(r, 1500))');
    assert.equal(await page.evaluate(`localStorage.getItem('mode')`), 'text');
  } finally {
    await page.close();
  }
});
