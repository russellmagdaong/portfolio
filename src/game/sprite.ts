import type { Sheet } from './types';

/**
 * Back to street (src/game/scene.ts): he warps out with the sheet's `death` (kneels, flashes
 * white, rises away as sparks), played this much faster than drawn. The street (hub.ts) plays it
 * backwards from the sparks to WARP_FORMED as he arrives.
 */
export const WARP_SPEED = 1.5;
/** The first frame of `death` where he stands whole again (before it, he kneels). */
export const WARP_FORMED = 7;
/** The frames of `death` (it has `frames` of them) played backwards, from the sparks until he stands whole: the warp in. */
export const warpInOrder = (frames: number) =>
  [...Array(Math.max(1, frames - WARP_FORMED)).keys()].map((i) => frames - 1 - i);
/** Whether a page was reached by a warp to it (to 'street' or a scene's id); forgets it either way. */
export function warpedTo(id: string) {
  try {
    const to = sessionStorage.getItem('warp');
    sessionStorage.removeItem('warp');
    return to === id;
  } catch {
    return false;
  }
}
/** Marks the page about to load as reached by a warp (it plays the warp in). */
export function warpTo(id: string) {
  try {
    sessionStorage.setItem('warp', id);
  } catch {}
}
/** How much of his shadow shows at a frame of `death`: all of it until he turns to light, none once he is sparks. */
export const warpShadow = (frame: number) => Math.min(1, Math.max(0, (20 - frame) / 8));

/** Plays the tags of a sprite sheet, with the frame durations set in Aseprite. */
export class Animator {
  tag = '';
  /** Index into the tag's frames. */
  frame = 0;
  /** True once a tag played without looping has shown its last frame for its full time. */
  done = false;
  private loop = true;
  private time = 0;
  private order: number[] = [0];
  private step = 0;

  constructor(
    readonly sheet: Sheet,
    readonly image: HTMLImageElement,
  ) {}

  has(tag: string) {
    return tag in this.sheet.tags;
  }

  /**
   * Starts a tag, unless it is already playing (pass restart to start it over). `order` plays the
   * tag's frames in that order instead of its own (the warp plays the death backwards).
   */
  play(tag: string, { loop = true, from = 0, restart = false, order }: { loop?: boolean; from?: number; restart?: boolean; order?: number[] } = {}) {
    if (!this.has(tag)) return;
    if (this.tag === tag && !restart) {
      this.loop = loop;
      return;
    }
    const info = this.sheet.tags[tag];
    const frames = [...Array(info.frames).keys()];
    // Aseprite's directions; ping-pong does not repeat its end frames.
    if (info.direction === 'reverse') frames.reverse();
    if (info.direction.startsWith('pingpong') && frames.length > 2) frames.push(...frames.slice(1, -1).reverse());
    if (info.direction === 'pingpong-reverse') frames.reverse();
    this.tag = tag;
    this.order = order?.filter((f) => f >= 0 && f < info.frames) ?? frames;
    if (!this.order.length) this.order = [0];
    this.step = Math.min(from, this.order.length - 1);
    this.frame = this.order[this.step];
    this.time = 0;
    this.loop = loop;
    this.done = false;
  }

  /** Shows one frame and holds it. */
  hold(tag: string, frame = 0) {
    this.play(tag, { loop: false });
    this.step = Math.min(frame, this.order.length - 1);
    this.frame = this.order[this.step];
    this.time = 0;
    this.done = true;
  }

  update(ms: number) {
    if (!this.tag || this.done) return;
    const durations = this.sheet.tags[this.tag].durations;
    this.time += ms;
    while (this.time >= durations[this.frame]) {
      this.time -= durations[this.frame];
      if (this.step + 1 < this.order.length) {
        this.step += 1;
      } else if (this.loop) {
        this.step = 0;
      } else {
        this.done = true;
        this.time = 0;
        return;
      }
      this.frame = this.order[this.step];
    }
  }

  /** Draws the current frame with its origin at (x, y) in view pixels. */
  draw(ctx: CanvasRenderingContext2D, x: number, y: number, flip = false) {
    if (!this.tag) return;
    const { width: w, height: h, origin } = this.sheet;
    const sx = this.frame * w;
    const sy = this.sheet.tags[this.tag].row * h;
    x = Math.round(x);
    y = Math.round(y);
    if (flip) {
      ctx.save();
      ctx.translate(x, 0);
      ctx.scale(-1, 1);
      ctx.drawImage(this.image, sx, sy, w, h, -(w - origin.x), y - origin.y, w, h);
      ctx.restore();
    } else {
      ctx.drawImage(this.image, sx, sy, w, h, x - origin.x, y - origin.y, w, h);
    }
  }
}
