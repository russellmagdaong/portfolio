/**
 * The mode chooser (src/components/Landing.astro) on the first page of a visit: text on one side,
 * the game on the other. Pointing at a side (or ← and →) leans the split towards it; clicking it
 * (or Enter) sweeps that side across the screen and opens the page in that mode.
 *
 * Behind the game side the street (art/hub.aseprite) plays live: Russell runs up and down the
 * sidewalk, hopping now and then, past the shopfronts.
 */
import { Animator } from './sprite';
import { loadImage, reducedMotion } from './view';
import { clamp, drawLayers, loadLayers } from './layers';
import type { HubConfig } from './types';

type Side = 'text' | 'game';

/** How long the chosen side takes to sweep across, then the chooser to fade (ms; landing.css matches). */
const SWEEP = 620;
const FADE = 480;
/** His run and hop on the street, as in the game (art px/s, px/s²). */
const RUN = 132;
const HOP = 190;
const GRAVITY = 620;

/** Phones held upright split the screen top and bottom (landing.css uses the same query). */
const upright = () => matchMedia('(orientation: portrait) and (max-width: 820px)').matches;

/**
 * The text side's moving picture: the text page's six panels (corkboard, chalkboard, cabinet,
 * pegboard, display case, airmail form) scrolling slowly up behind its card, as if someone were
 * reading down the page. As many columns as cover the side at its widest, each starting on a
 * different panel and running at its own speed, so the side reads as a wall of pages. Copied from the page itself, so it always shows what the page says; only
 * the panels, not the rooms, so nothing heavy loads for a visitor about to pick the game. Inert and
 * hidden from screen readers. On a phone held upright the side is the top half, the full width:
 * the columns are smaller there (landing.css) and enough of them to cross it.
 */
function buildReel(el: HTMLElement) {
  const side = el.querySelector<HTMLElement>('[data-side="text"]');
  if (!side || side.querySelector('.landing-reel')) return;
  const panels = [...document.querySelectorAll<HTMLElement>('[data-text-site] [data-panel]')];
  if (!panels.length) return;
  const reel = document.createElement('div');
  reel.className = 'landing-reel tsite';
  reel.setAttribute('aria-hidden', 'true');
  reel.inert = true;
  // A column is 448px at 70% plus a 24px gutter; the side is at most 56% of the screen (leaning
  // towards text), plus the bleed past its slanted edge.
  // Upright, a column is 320px at 50% plus a 16px gutter, across the whole width.
  const columns = upright()
    ? Math.max(1, Math.ceil((innerWidth + 80) / 336))
    : Math.max(1, Math.ceil((innerWidth * 0.56 + 120) / 472));
  for (let col = 0; col < columns; col++) {
    const track = document.createElement('div');
    track.className = 'landing-reel-track';
    track.style.setProperty('--col', String(col));
    // Each column starts on a later panel than the one before it.
    const order = panels.map((_, i) => panels[(i + col * 2) % panels.length]);
    fillTrack(track, order);
    reel.append(track);
  }
  side.prepend(reel);
}

function fillTrack(track: HTMLElement, panels: HTMLElement[]) {
  // Twice over, so the loop can jump back by exactly half without a seam.
  for (let pass = 0; pass < 2; pass++)
    for (const panel of panels) {
      const copy = panel.cloneNode(true) as HTMLElement;
      copy.querySelectorAll('[id]').forEach((e) => e.removeAttribute('id'));
      copy.querySelectorAll('[name]').forEach((e) => e.removeAttribute('name'));
      copy.setAttribute('data-live', '');
      // The game hides every [data-panel] that is not open (game.css); a copy is no panel of the game's.
      copy.removeAttribute('data-panel');
      // Each panel at its first detail, at full size.
      const details = [...copy.querySelectorAll<HTMLElement>('.t-detail')];
      if (copy.hasAttribute('data-split'))
        details.forEach((d, i) => (i === 0 ? d.removeAttribute('hidden') : d.setAttribute('hidden', '')));
      details.forEach((d) => d.style.removeProperty('zoom'));
      copy.querySelectorAll<HTMLElement>('.t-item').forEach((b, i) => b.setAttribute('aria-pressed', String(i === 0)));
      track.append(copy);
    }
}

export function runLanding(setMode: (game: boolean) => void, { reopened = false } = {}) {
  const root = document.documentElement;
  const el = document.querySelector<HTMLElement>('[data-landing]');
  if (!el) {
    root.classList.remove('choosing');
    return;
  }
  // On a phone held upright the reel's copied pages would load before the street and hold it up:
  // there it waits until the street is drawn (or three seconds, whichever comes first).
  const streetCanvas = el.querySelector<HTMLCanvasElement>('[data-landing-street]');
  if (upright() && streetCanvas && !streetCanvas.classList.contains('is-ready')) {
    let built = false;
    const build = () => {
      if (built) return;
      built = true;
      watch.disconnect();
      buildReel(el);
    };
    const watch = new MutationObserver(() => streetCanvas.classList.contains('is-ready') && build());
    watch.observe(streetCanvas, { attributes: true, attributeFilter: ['class'] });
    setTimeout(build, 3000);
  } else buildReel(el);
  const buttons: Record<Side, HTMLButtonElement | null> = {
    text: el.querySelector('[data-choose="text"]'),
    game: el.querySelector('[data-choose="game"]'),
  };

  // The side picked last time (if any) starts leaned towards, and says so. Opened again (Change UI,
  // the jeepney), that is the version showing, and Esc goes back to it.
  let last: Side | null = reopened ? (root.classList.contains('game') ? 'game' : 'text') : null;
  try {
    const mode = localStorage.getItem('mode');
    if (!last) last = mode === 'text' || mode === 'game' ? mode : null;
  } catch {}
  if (last) {
    const tag = el.querySelector<HTMLElement>(`[data-side="${last}"] .landing-last`);
    tag?.removeAttribute('hidden');
    if (tag && reopened) tag.textContent = 'You are here · Esc to stay';
  }

  let picked: Side | null = null;
  const lean = (side: Side, focus = false) => {
    if (picked) return;
    el.dataset.lean = side;
    if (focus) buttons[side]?.focus({ preventScroll: true });
  };
  lean(last ?? 'game');
  // After the entrance, so focusing does not scroll or flash the outline mid-slide.
  setTimeout(() => !picked && buttons[(el.dataset.lean as Side) ?? 'game']?.focus({ preventScroll: true }), reducedMotion() ? 0 : 900);

  let stop = () => {};
  const choose = (side: Side) => {
    if (picked) return;
    picked = side;
    el.dataset.lean = side;
    el.dataset.picked = side;
    try {
      sessionStorage.setItem('mode-chosen', side);
    } catch {}
    window.removeEventListener('keydown', onKey, true);
    const open = () => {
      setMode(side === 'game');
      // The game starts drawing behind the chooser as it fades.
      root.classList.remove('choosing');
      el.classList.add('is-leaving');
      setTimeout(() => {
        el.hidden = true;
        stop();
      }, reducedMotion() ? 0 : FADE);
    };
    if (reducedMotion()) open();
    else setTimeout(open, SWEEP);
  };

  el.querySelectorAll<HTMLElement>('[data-side]').forEach((half) => {
    const side = half.dataset.side as Side;
    half.addEventListener('pointerenter', (event) => event.pointerType === 'mouse' && lean(side));
    half.addEventListener('click', () => choose(side));
    buttons[side]?.addEventListener('focus', () => lean(side));
  });

  const onKey = (event: KeyboardEvent) => {
    if (event.ctrlKey || event.metaKey || event.altKey) return;
    const back = upright() ? ['ArrowUp', 'KeyW'] : ['ArrowLeft', 'KeyA'];
    const next = upright() ? ['ArrowDown', 'KeyS'] : ['ArrowRight', 'KeyD'];
    if (back.includes(event.code)) lean('text', true);
    else if (next.includes(event.code)) lean('game', true);
    else if (event.code === 'Enter' || event.code === 'Space' || event.code === 'NumpadEnter') {
      // The focused choice, or else the side leaned towards.
      const focused = event.target instanceof HTMLElement ? (event.target.dataset.choose as Side | undefined) : undefined;
      choose(focused ?? (el.dataset.lean as Side) ?? 'game');
    } else if (event.code === 'Escape' && reopened && last) {
      choose(last);
    } else if (event.code === 'Tab') {
      // Keep Tab between the two choices.
      event.preventDefault();
      lean(el.dataset.lean === 'text' ? 'game' : 'text', true);
      return;
    } else return;
    // The game's keys (arrows, Space) must not reach it, nor scroll the page underneath.
    event.preventDefault();
    event.stopPropagation();
  };
  window.addEventListener('keydown', onKey, true);

  typeHeads(el);

  const canvas = el.querySelector<HTMLCanvasElement>('[data-landing-street]');
  const json = (el.querySelector('[data-landing-street-config]') ?? document.getElementById('game-config'))?.textContent;
  const street = json ? (JSON.parse(json) as HubConfig) : null;
  if (canvas && street?.kind === 'hub') {
    streetLoop(canvas, street)
      .then((s) => {
        if (el.hidden) s();
        else stop = s;
      })
      .catch((error) => console.error(error));
  }
}

/** The text side's heading types itself out, with a caret that stays and blinks. */
function typeHeads(el: HTMLElement) {
  el.querySelectorAll<HTMLElement>('[data-type]').forEach((head) => {
    const text = head.textContent?.trim() ?? '';
    head.setAttribute('aria-label', text);
    if (reducedMotion()) return;
    const shown = document.createElement('span');
    shown.setAttribute('aria-hidden', 'true');
    const caret = document.createElement('span');
    caret.className = 'landing-caret';
    caret.setAttribute('aria-hidden', 'true');
    head.replaceChildren(shown, caret);
    let i = 0;
    const tick = () => {
      shown.textContent = text.slice(0, i);
      if (i++ < text.length) setTimeout(tick, i === 1 ? 900 : 70 + Math.random() * 60);
    };
    tick();
  });
}

/** The street behind the game side; resolves to a function that stops it. */
async function streetLoop(canvas: HTMLCanvasElement, cfg: HubConfig) {
  const [images, playerImage, signImages] = await Promise.all([
    loadLayers(cfg.layers),
    loadImage(cfg.player.src),
    Promise.all(cfg.buildings.map((b) => loadImage(b.sprite.src))),
  ]);
  const ctx = canvas.getContext('2d')!;
  const anim = new Animator(cfg.player, playerImage);
  const signs = cfg.buildings.map((b, i) => {
    const a = new Animator(b.sprite, signImages[i]);
    a.play('idle');
    return { a, x: b.slice.x + b.slice.width / 2, y: b.slice.y + b.slice.height };
  });
  const sidewalk = cfg.slices.find((s) => s.name === 'floor' && String(s.data.level ?? 'street') === 'street');
  const feet = sidewalk ? sidewalk.y + sidewalk.height - 3 : cfg.height - 55;

  // The canvas covers the whole chooser; its art size keeps the street's height (or width) whole.
  let w = cfg.width;
  let h = cfg.height;
  const fit = () => {
    const box = canvas.getBoundingClientRect();
    if (!box.width || !box.height) return;
    const aspect = box.width / box.height;
    if (cfg.height * aspect <= cfg.width) [w, h] = [Math.round(cfg.height * aspect), cfg.height];
    else [w, h] = [cfg.width, Math.round(cfg.width / aspect)];
    canvas.width = w;
    canvas.height = h;
    ctx.imageSmoothingEnabled = false;
  };
  const watch = new ResizeObserver(fit);
  watch.observe(canvas);
  fit();

  /** The part of the view the game side shows, as fractions of its width. */
  const shown = () => (upright() ? [0.08, 0.92] : [0.54, 0.96]);
  let x = cfg.width * 0.75;
  let dir = -1;
  let z = 0;
  let vz = 0;
  let turning = false;
  let hopIn = 1.2;
  let camX = Math.max(0, cfg.width - w);
  anim.play('run');

  const draw = (now: number, dt: number) => {
    const [f0, f1] = shown();
    const camMax = Math.max(0, cfg.width - w);
    // He runs to and fro within what the game side shows, turning at each end.
    const lo = clamp(w * f0 + 16, 16, cfg.width - 16);
    const hi = clamp(camMax + w * f1 - 16, lo + 1, cfg.width - 16);
    if (reducedMotion()) {
      x = (lo + hi) / 2;
      anim.hold('idle', 0);
    } else {
      x += dir * RUN * dt;
      if ((dir > 0 && x >= hi) || (dir < 0 && x <= lo)) {
        x = clamp(x, lo, hi);
        dir = -dir;
        if (z === 0) {
          anim.play('run_turn', { loop: false, restart: true });
          turning = anim.tag === 'run_turn';
        }
      }
      hopIn -= dt;
      if (hopIn <= 0 && z === 0 && !turning) {
        vz = HOP;
        hopIn = 1.8 + Math.random() * 2.6;
      }
      if (vz > 0 || z > 0) {
        vz -= GRAVITY * dt;
        z = Math.max(0, z + vz * dt);
        if (z === 0) vz = 0;
      }
      if (z > 0) {
        turning = false;
        if (vz > 0) anim.play('jump', { loop: false, from: 1 });
        else if (anim.tag !== 'fall' && anim.tag !== 'fall_loop') anim.play('fall', { loop: false });
        else if (anim.tag === 'fall' && anim.done) anim.play('fall_loop');
      } else if (!(turning && !anim.done)) {
        turning = false;
        anim.play('run');
      }
      anim.update(dt * 1000);
      signs.forEach((s) => s.a.update(dt * 1000));
    }

    const want = clamp(x - w * ((f0 + f1) / 2), 0, camMax);
    camX += (want - camX) * (1 - Math.exp(-dt * 3));
    const cx = Math.round(camX);
    // Where his feet sit in the view. On an upright phone the top of the canvas is under the text
    // side, so the street drops low, and he runs below the card rather than behind it.
    const footAt = upright() ? 0.95 : feet / cfg.height;
    const camY = Math.min(Math.round(feet - h * footAt), Math.max(0, cfg.height - h));

    ctx.fillStyle = '#0d0b1a';
    ctx.fillRect(0, 0, w, h);
    drawLayers(ctx, cfg.layers, images, cx, camY, now, false, { y: feet }, (layer) => {
      if (layer.name === 'buildings') signs.forEach((s) => s.a.draw(ctx, s.x - cx, s.y - camY));
    });
    // His shadow, smaller as he hops.
    const k = clamp(1 - z / 48, 0.4, 1);
    const sw = Math.round(16 * k);
    ctx.fillStyle = `rgba(13, 11, 26, ${(0.55 * k).toFixed(2)})`;
    ctx.fillRect(Math.round(x - cx - sw / 2), feet - camY - 1, sw, 2);
    const flip = turning ? dir > 0 : dir < 0;
    anim.draw(ctx, x - cx, feet - z - camY, flip);
    drawLayers(ctx, cfg.layers, images, cx, camY, now, true, { y: feet });
  };

  let running = true;
  let last = performance.now();
  const frame = (now: number) => {
    if (!running) return;
    const dt = Math.min(0.05, (now - last) / 1000);
    last = now;
    draw(now, dt);
    // Drawn once: it fades in (landing.css).
    if (!canvas.classList.contains('is-ready')) canvas.classList.add('is-ready');
    requestAnimationFrame(frame);
  };
  requestAnimationFrame(frame);
  return () => {
    running = false;
    watch.disconnect();
  };
}
