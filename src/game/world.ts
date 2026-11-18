/**
 * Content shown in the scene itself: each show:<id> slice gets the page's
 * <Show id> block, laid over the art at the slice and moving with the camera
 * (a poster's text, the PC's screen, the tools on a shelf).
 *
 * The block is moved, not copied: in the game it lives in the stage, and in the
 * text version it goes back to its place in the page.
 */
import type { Slice } from './types';
import type { View } from './view';
import { gameOn } from './view';

/** A phone held upright: the same test as the upright layout in src/styles/game.css. */
const UPRIGHT = matchMedia('(orientation: portrait) and (max-width: 820px)');

interface Placed {
  slice: Slice;
  el: HTMLElement;
  home: HTMLElement;
  last: string;
  /** The device scale its text was last fitted at (data-fit boards), 0 for not yet. */
  fitAt: number;
}

export class World {
  private placed: Placed[] = [];

  constructor(
    private readonly layer: HTMLElement,
    slices: Slice[],
  ) {
    for (const slice of slices) {
      const id = slice.name.slice('show:'.length);
      const el = document.querySelector<HTMLElement>(`[data-show="${CSS.escape(id)}"]`);
      const home = document.querySelector<HTMLElement>(`[data-show-home="${CSS.escape(id)}"]`);
      if (!el || !home) {
        console.warn(`${slice.name}: no <Show id="${id}"> on this page`);
        continue;
      }
      el.dataset.look = String(slice.data.look ?? el.dataset.look ?? 'paper');
      this.placed.push({ slice, el, home, last: '', fitAt: 0 });
    }
    // Text measured before the pixel font arrives fits the fallback font: fit again once it is in.
    document.fonts?.ready.then(() => this.placed.forEach((p) => (p.fitAt = 0)));
    this.sync();
    document.addEventListener('game-mode', () => this.sync());
    UPRIGHT.addEventListener('change', () => this.sync());
  }

  /** The show under a point of the stage, if the point lands on one. */
  forEach(fn: (slice: Slice, el: HTMLElement) => void) {
    this.placed.forEach((p) => fn(p.slice, p.el));
  }

  /**
   * In the game the blocks sit in the stage. In the text version, and on a phone held
   * upright (where a board on the wall would be too small to read), they stay in the
   * page, under the scene.
   */
  private sync() {
    const game = gameOn() && !UPRIGHT.matches;
    for (const p of this.placed) {
      if (game && p.el.parentElement !== this.layer) {
        this.layer.append(p.el);
        p.el.classList.add('in-world');
        p.last = '';
        p.fitAt = 0;
      } else if (!game && p.el.parentElement !== p.home) {
        p.home.append(p.el);
        p.el.classList.remove('in-world');
        p.el.removeAttribute('style');
      }
    }
  }

  /** Puts every block over its slice for this frame. */
  place(view: View, camX: number, camY: number) {
    this.layer.style.setProperty('--px', `${view.cssScale}px`);
    for (const p of this.placed) {
      if (p.el.parentElement !== this.layer) continue;
      const s = p.slice;
      const at = view.toStage(s.x - camX, s.y - camY);
      const key = `${Math.round(at.x)},${Math.round(at.y)},${view.cssScale}`;
      if (key !== p.last) {
        p.last = key;
        p.el.style.translate = `${Math.round(at.x)}px ${Math.round(at.y)}px`;
        p.el.style.width = `${s.width * view.cssScale}px`;
        p.el.style.height = `${s.height * view.cssScale}px`;
      }
      if (p.el.dataset.fit !== undefined && p.fitAt !== view.cssScale) {
        p.fitAt = view.cssScale;
        fit(p.el, view.scale);
      }
    }
  }
}

/**
 * The largest letter size (in art pixels, as --fs) at which the board's text fits inside it,
 * up to its data-fit cap. Rounded down to whole device pixels so the pixel font stays sharp.
 * The board scales with the art, so this only changes when the art's scale does.
 */
function fit(el: HTMLElement, scale: number) {
  const cap = Number(el.dataset.fit) || 8;
  const fits = (u: number) => {
    el.style.setProperty('--fs', String(u));
    return el.scrollHeight <= el.clientHeight + 1 && el.scrollWidth <= el.clientWidth + 1;
  };
  if (fits(cap)) return;
  let lo = 1;
  let hi = cap;
  for (let i = 0; i < 12; i++) {
    const mid = (lo + hi) / 2;
    if (fits(mid)) lo = mid;
    else hi = mid;
  }
  // --fs * scale is the font size in device pixels: keep it a whole number.
  fits(Math.max(1, Math.floor(lo * scale)) / scale);
}
