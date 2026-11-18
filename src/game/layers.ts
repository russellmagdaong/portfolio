import type { Layer, Slice } from './types';
import { reducedMotion } from './view';
import { loadImage } from './view';
import type { Panels } from './panels';

export interface Ui {
  stage: HTMLElement;
  canvas: HTMLCanvasElement;
  /** Where the page's in-world content (<Show>) is placed over the scene. */
  world: HTMLElement;
  /** The key prompt over the thing in reach ("E Play"). */
  prompt: HTMLElement;
  /** The card over a prop (interests), or the name tag over a building on the map. */
  label: HTMLElement;
  exit: HTMLButtonElement | null;
  /** In a scene, the HUD's Back to street button: he warps out to the street from wherever he is. */
  warp: HTMLButtonElement | null;
  panels: Panels;
  /** Buttons that go to a thing (data-go="<panel id>") or a building (data-go="<place id>"). */
  goButtons: HTMLButtonElement[];
  /** Whether the visitor is using touch, which changes the prompts. */
  touch: () => boolean;
}

export async function loadLayers(layers: Layer[]) {
  return Promise.all(layers.map((layer) => loadImage(layer.src)));
}

/** Where the player is, for the layers that change sides (`sort` and `stair`). */
export interface Standing {
  y: number;
  onStair?: boolean;
}

/** Whether a layer is drawn in front of the player right now. */
export const inFront = (layer: Layer, at: Standing) =>
  layer.over || (layer.sort !== undefined && at.y < layer.sort) || (layer.stair === true && at.onStair === true);

/** Which frame of an animated layer shows at time `now` (always the first with reduced motion). */
export function frameOf(layer: Layer, now: number) {
  let frame = 0;
  if (layer.frames > 1 && !reducedMotion()) {
    const total = layer.durations.reduce((a, b) => a + b, 0);
    let t = now % total;
    while (t >= layer.durations[frame]) t -= layer.durations[frame++];
  }
  return frame;
}

const HIGHLIGHT = [255, 233, 31];

/**
 * The outline of whatever a layer draws inside a slice (on one of its frames): every see-through
 * pixel next to a drawn one, one pixel round, in the highlight yellow. The canvas returned is the
 * slice plus a pixel on each side; it is shown while the thing is pointed at.
 */
export function outlineOf(slice: Slice, layer: Layer | undefined, image: HTMLImageElement | undefined, frame = 0) {
  if (!layer || !image) return null;
  return outlineOfCell(image, frame * layer.width + slice.x - layer.x, slice.y - layer.y, slice.width, slice.height);
}

/** The same outline round one cell of an image (a frame of a sprite sheet). */
export function outlineOfCell(image: HTMLImageElement, sx: number, sy: number, width: number, height: number) {
  const w = width + 2;
  const h = height + 2;
  const c = document.createElement('canvas');
  c.width = w;
  c.height = h;
  const g = c.getContext('2d', { willReadFrequently: true });
  if (!g) return null;
  // The cell, one pixel in from the edge.
  g.drawImage(image, sx, sy, width, height, 1, 1, width, height);
  const src = g.getImageData(0, 0, w, h);
  const out = g.createImageData(w, h);
  const solid = (x: number, y: number) => x >= 0 && y >= 0 && x < w && y < h && src.data[(y * w + x) * 4 + 3] > 0;
  for (let y = 0; y < h; y++)
    for (let x = 0; x < w; x++) {
      if (solid(x, y) || !(solid(x - 1, y) || solid(x + 1, y) || solid(x, y - 1) || solid(x, y + 1))) continue;
      out.data.set([...HIGHLIGHT, 255], (y * w + x) * 4);
    }
  g.putImageData(out, 0, 0);
  return c;
}

/** Draws the layers that are (or are not) in front of the player. */
export function drawLayers(
  ctx: CanvasRenderingContext2D,
  layers: Layer[],
  images: HTMLImageElement[],
  camX: number,
  camY: number,
  now: number,
  over: boolean,
  at: Standing = { y: Infinity },
  /**
   * Called after each layer's place in the stack, whether or not this pass drew it (the scene's
   * objects go just in front of `props`, on whichever side of the player they are).
   */
  after?: (layer: Layer) => void,
) {
  layers.forEach((layer, i) => {
    if (inFront(layer, at) === over) {
      const frame = frameOf(layer, now);
      const x = Math.round(layer.x - camX * layer.speed);
      const y = Math.round(layer.y - camY);
      ctx.drawImage(images[i], frame * layer.width, 0, layer.width, layer.height, x, y, layer.width, layer.height);
    }
    after?.(layer);
  });
}

export const slicesNamed = (slices: Slice[], name: string) => slices.filter((s) => s.name === name);
export const sliceStarting = (slices: Slice[], prefix: string) => slices.filter((s) => s.name.startsWith(prefix));

export const contains = (s: Slice, x: number, y: number) =>
  x >= s.x && x < s.x + s.width && y >= s.y && y < s.y + s.height;

export const clamp = (v: number, lo: number, hi: number) => Math.max(lo, Math.min(hi, v));
