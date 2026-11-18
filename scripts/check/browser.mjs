/**
 * Drives headless Edge over the DevTools protocol for the checks in this folder (npm run check).
 * No dependencies: Node 22's fetch and WebSocket are enough. The checks run against the dev server
 * that is already running (CHECK_BASE, default http://localhost:4321).
 */
import { spawn } from 'node:child_process';
import { existsSync, mkdtempSync, mkdirSync, readFileSync, rmSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join, resolve } from 'node:path';

const EDGE = 'C:/Program Files (x86)/Microsoft/Edge/Application/msedge.exe';
export const BASE = process.env.CHECK_BASE ?? 'http://localhost:4321';
const REVIEW = resolve('.impeccable/review');
/** How long one protocol call may take before the check gives up (a crashed Edge never answers). */
const CALL_TIMEOUT = 60_000;
const wait = (ms) => new Promise((r) => setTimeout(r, ms));

/**
 * @param {string} path  a path on the dev server ("/projects"), or a full URL (file:///...)
 * @param {{ width?: number, height?: number, mode?: 'text' | 'game', reducedMotion?: boolean }} [opts]
 */
export async function openPage(path, opts = {}) {
  const { width = 1469, height = 887, mode = 'text', reducedMotion = false } = opts;
  const profile = mkdtempSync(join(tmpdir(), 'check-edge-'));
  // Port 0: Edge picks a free port and writes it to DevToolsActivePort in its profile, so two
  // check files running at once can never reach each other's browser.
  const edge = spawn(EDGE, ['--headless=new', '--hide-scrollbars', '--remote-debugging-port=0', `--user-data-dir=${profile}`, 'about:blank'], { stdio: 'ignore' });
  let ws;
  const cleanup = async () => {
    try {
      ws?.close();
    } catch {}
    edge.kill();
    await wait(800);
    try {
      rmSync(profile, { recursive: true, force: true });
    } catch {}
  };

  try {
    let target;
    const portFile = join(profile, 'DevToolsActivePort');
    for (let i = 0; i < 80 && !target; i++) {
      await wait(250);
      if (!existsSync(portFile)) continue;
      const port = readFileSync(portFile, 'utf8').split('\n')[0].trim();
      try {
        target = (await (await fetch(`http://127.0.0.1:${port}/json/list`)).json()).find((t) => t.type === 'page');
      } catch {}
    }
    if (!target) throw new Error('headless Edge did not start');

    ws = new WebSocket(target.webSocketDebuggerUrl);
    await new Promise((r, j) => {
      ws.addEventListener('open', r);
      ws.addEventListener('error', j);
    });
  } catch (error) {
    await cleanup();
    throw error;
  }

  let id = 0;
  const pending = new Map();
  ws.addEventListener('message', (e) => {
    const m = JSON.parse(e.data);
    if (m.id && pending.has(m.id)) {
      pending.get(m.id)(m);
      pending.delete(m.id);
    }
  });
  const send = (method, params = {}) =>
    new Promise((r, j) => {
      const i = ++id;
      const timer = setTimeout(() => {
        pending.delete(i);
        j(new Error(`${method}: no answer from Edge in ${CALL_TIMEOUT / 1000} s`));
      }, CALL_TIMEOUT);
      pending.set(i, (m) => {
        clearTimeout(timer);
        r(m);
      });
      ws.send(JSON.stringify({ id: i, method, params }));
    });
  const evaluate = async (expression) => {
    const m = await send('Runtime.evaluate', { expression, awaitPromise: true, returnByValue: true });
    if (m.result?.exceptionDetails) throw new Error(`in page: ${m.result.exceptionDetails.exception?.description ?? m.result.exceptionDetails.text}`);
    return m.result?.result?.value;
  };
  const navigate = async (url) => {
    await send('Page.navigate', { url: 'about:blank' });
    await wait(100);
    await send('Page.navigate', { url });
    for (let i = 0; i < 80; i++) {
      await wait(100);
      if ((await evaluate('document.readyState')) === 'complete') break;
    }
  };

  try {
    await send('Page.enable');
    await send('Runtime.enable');
    await send('Emulation.setDeviceMetricsOverride', { width, height, deviceScaleFactor: 1, mobile: width < 600 });
    if (reducedMotion) await send('Emulation.setEmulatedMedia', { features: [{ name: 'prefers-reduced-motion', value: 'reduce' }] });

    const url = /^[a-z]+:/.test(path) ? path : BASE + path;
    if (!url.startsWith('file:')) {
      await navigate(BASE + '/404-check');
      await evaluate(`localStorage.setItem('mode', ${JSON.stringify(mode)}); sessionStorage.setItem('mode-chosen', '1'); 1`);
    }
    await navigate(url);
    // Let fonts, pictures and the page's own scripts settle.
    await evaluate('document.fonts.ready.then(() => 1)');
    await wait(600);
  } catch (error) {
    await cleanup();
    throw error;
  }

  return {
    evaluate,
    /** Loads a page in the same browser (same storage), via about:blank so it is a real load. */
    navigate,
    async key(key) {
      const codes = { Tab: 9, Enter: 13, Escape: 27, ArrowLeft: 37, ArrowUp: 38, ArrowRight: 39, ArrowDown: 40 };
      const base = { key, code: key, windowsVirtualKeyCode: codes[key] ?? 0 };
      await send('Input.dispatchKeyEvent', { type: 'keyDown', ...base });
      await send('Input.dispatchKeyEvent', { type: 'keyUp', ...base });
      await wait(150);
    },
    /**
     * full: the whole page from the top. Or pass { from, to } (page y) for one band of it: a page
     * taller than ~16000 px is past what one capture can hold, and the picture wraps round.
     */
    async screenshot(name, full = false) {
      mkdirSync(REVIEW, { recursive: true });
      const params = { format: 'png' };
      if (full) {
        const h = await evaluate('document.documentElement.scrollHeight');
        const from = typeof full === 'object' ? full.from : 0;
        const to = typeof full === 'object' ? Math.min(full.to, h) : h;
        params.clip = { x: 0, y: from, width, height: to - from, scale: 1 };
        params.captureBeyondViewport = true;
      }
      const r = await send('Page.captureScreenshot', params);
      const file = join(REVIEW, `${name}.png`);
      writeFileSync(file, Buffer.from(r.result.data, 'base64'));
      return file;
    },
    close: cleanup,
  };
}

/** WCAG contrast ratio of two "#rrggbb" colours. */
export function contrast(a, b) {
  const lum = (hex) => {
    const [r, g, bl] = [1, 3, 5].map((i) => parseInt(hex.slice(i, i + 2), 16) / 255).map((c) => (c <= 0.03928 ? c / 12.92 : ((c + 0.055) / 1.055) ** 2.4));
    return 0.2126 * r + 0.7152 * g + 0.0722 * bl;
  };
  const [x, y] = [lum(a), lum(b)].sort((p, q) => q - p);
  return (x + 0.05) / (y + 0.05);
}
