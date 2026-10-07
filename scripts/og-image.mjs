// Draws the link-preview image (public/og.png, 1200 x 630) that sites like Facebook, Discord and
// X show when the portfolio is shared. Run it again after changing the design below:
//
//   node scripts/og-image.mjs
//
// It renders the HTML below in Chromium through Playwright, which is not listed in package.json:
// install it on its own (npm i -g playwright) or point PLAYWRIGHT_MODULE at an existing copy.
import { readFile } from 'node:fs/promises';
import { createRequire } from 'node:module';

const require = createRequire(import.meta.url);
const { chromium } = await import(process.env.PLAYWRIGHT_MODULE ?? 'playwright');

const font = async (pkg, file) =>
  (await readFile(require.resolve(`${pkg}/files/${file}`))).toString('base64');
const pixel = await font('@fontsource/press-start-2p', 'press-start-2p-latin-400-normal.woff2');
const mono = await font('@fontsource/ibm-plex-mono', 'ibm-plex-mono-latin-500-normal.woff2');

// Scattered from a fixed seed, so the image comes out the same every run.
function stars() {
  let seed = 7;
  const rand = () => ((seed = (seed * 16807) % 2147483647) / 2147483647);
  return Array.from({ length: 46 }, () => {
    const x = Math.round(rand() * 1200), y = Math.round(40 + rand() * 270);
    return `<i style="left:${x}px;top:${y}px;opacity:${(0.25 + rand() * 0.75).toFixed(2)}"></i>`;
  }).join('');
}

// The same colours as src/styles/global.css.
const html = /* html */ `<!doctype html>
<style>
  @font-face { font-family: Pixel; src: url(data:font/woff2;base64,${pixel}); }
  @font-face { font-family: Mono; src: url(data:font/woff2;base64,${mono}); }
  * { margin: 0; box-sizing: border-box; }
  body {
    width: 1200px; height: 630px; overflow: hidden; position: relative;
    background: radial-gradient(ellipse 70% 60% at 50% 38%, #141a33 0%, #050508 70%);
    font-family: Mono; color: #d5dbea;
  }
  /* The receding floor grid. */
  .floor {
    position: absolute; left: -50%; right: -50%; top: 330px; height: 420px;
    background-image:
      linear-gradient(rgba(45,226,246,.55) 2px, transparent 2px),
      linear-gradient(90deg, rgba(45,226,246,.55) 2px, transparent 2px);
    background-size: 60px 44px;
    transform: perspective(300px) rotateX(62deg);
    transform-origin: top;
    mask-image: linear-gradient(to bottom, transparent 0%, #000 35%);
  }
  .horizon {
    position: absolute; left: 0; right: 0; top: 328px; height: 3px;
    background: #ff2e8b; box-shadow: 0 0 24px 4px rgba(255,46,139,.7);
  }
  /* The sun, sliced. */
  .sun {
    position: absolute; left: 50%; top: 108px; width: 340px; height: 220px; translate: -50% 0;
    border-radius: 170px 170px 0 0;
    background: linear-gradient(#ffe91f, #ff2e8b 85%);
    mask-image: linear-gradient(to top, transparent 0 6px, #000 6px 18px, transparent 18px 28px, #000 28px 42px, transparent 42px 50px, #000 50px);
    opacity: .9;
  }
  .stars i { position: absolute; width: 4px; height: 4px; background: #d5dbea; }
  .name {
    position: absolute; left: 0; right: 0; top: 372px; text-align: center;
    font-family: Pixel; font-size: 132px; letter-spacing: 4px; color: #fff;
    text-shadow: 6px 6px 0 #ff2e8b, 12px 12px 0 #2de2f6, 0 0 48px rgba(5,5,8,.9);
  }
  .name b { color: #ffe91f; font-weight: normal; }
  .scan {
    position: absolute; inset: 0; pointer-events: none;
    background: repeating-linear-gradient(to bottom, rgba(0,0,0,.14) 0 2px, transparent 2px 4px);
  }
  .tag {
    position: absolute; top: 64px; left: 72px; font-size: 22px; letter-spacing: 3px; color: #8690a8;
  }
  .tag span { color: #2de2f6; }
  .coin {
    position: absolute; top: 64px; right: 72px; font-family: Pixel; font-size: 18px; color: #ffe91f;
  }
</style>
<div class="stars">${stars()}</div>
<div class="sun"></div>
<div class="floor"></div>
<div class="horizon"></div>
<div class="name">russm<b>.</b></div>
<div class="tag"><span>&gt;</span> PLAYER 1</div>
<div class="coin">INSERT COIN</div>
<!-- The cut-corner panel the site uses, as a frame. -->
<svg style="position:absolute;inset:0" width="1200" height="630">
  <path d="M30 30H1134L1170 66V600H66L30 564Z" fill="none" stroke="#2de2f6" stroke-width="4" />
</svg>
<div class="scan"></div>`;

const browser = await chromium.launch();
const page = await browser.newPage({ viewport: { width: 1200, height: 630 } });
await page.setContent(html);
await page.evaluate(() => document.fonts.ready);
await page.screenshot({ path: 'public/og.png' });
await browser.close();
console.log('Wrote public/og.png');
