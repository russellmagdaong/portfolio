/**
 * The low-resolution canvas and how it is enlarged.
 *
 * Art is drawn one art pixel to one canvas pixel, and the canvas is enlarged by
 * a whole number of *device* pixels, so every art pixel is a crisp square on any
 * screen (including Windows' 125% and 150% scaling). The window size changes how
 * much of the scene shows, never how sharp it is.
 */
export class View {
  readonly ctx: CanvasRenderingContext2D;
  /** Device pixels per art pixel. */
  scale = 1;
  /** CSS pixels per art pixel. */
  cssScale = 1;
  /** How much of the world shows, in art pixels. */
  width = 320;
  height = 180;
  /** Where the canvas sits in the stage, in CSS pixels (it is centred when the world is smaller). */
  left = 0;
  top = 0;
  onResize?: () => void;

  constructor(
    readonly stage: HTMLElement,
    readonly canvas: HTMLCanvasElement,
    /** The world's size: the view never grows past it. */
    readonly world: { width: number; height: number },
  ) {
    const ctx = canvas.getContext('2d', { alpha: false });
    if (!ctx) throw new Error('No 2D canvas');
    this.ctx = ctx;
    new ResizeObserver(() => this.resize()).observe(stage);
    matchMedia('(resolution: 1dppx)').addEventListener?.('change', () => this.resize());
    this.resize();
  }

  resize() {
    const box = this.stage.getBoundingClientRect();
    if (box.width === 0 || box.height === 0) return;
    const dpr = window.devicePixelRatio || 1;
    const devW = Math.round(box.width * dpr);
    const devH = Math.round(box.height * dpr);
    // At least 320x180 art pixels must fit (240 wide on a phone held upright, where the
    // scene is a square on top of the text and would otherwise be tiny).
    const minW = window.innerWidth < window.innerHeight ? 240 : 320;
    this.scale = Math.max(1, Math.floor(Math.min(devW / minW, devH / 180)));
    this.cssScale = this.scale / dpr;
    this.width = Math.min(this.world.width, Math.ceil(devW / this.scale));
    this.height = Math.min(this.world.height, Math.ceil(devH / this.scale));

    this.canvas.width = this.width;
    this.canvas.height = this.height;
    this.ctx.imageSmoothingEnabled = false;
    const cssW = (this.width * this.scale) / dpr;
    const cssH = (this.height * this.scale) / dpr;
    // Centre on a whole device pixel.
    this.left = Math.max(0, Math.round((devW - this.width * this.scale) / 2)) / dpr;
    this.top = Math.max(0, Math.round((devH - this.height * this.scale) / 2)) / dpr;
    Object.assign(this.canvas.style, {
      width: `${cssW}px`,
      height: `${cssH}px`,
      left: `${this.left}px`,
      top: `${this.top}px`,
    });
    this.onResize?.();
  }

  /** A pointer position, in art pixels from the view's top-left. */
  toArt(clientX: number, clientY: number) {
    const box = this.canvas.getBoundingClientRect();
    return { x: (clientX - box.left) / this.cssScale, y: (clientY - box.top) / this.cssScale };
  }

  /** An art-pixel position in the view, in CSS pixels from the stage's top-left. */
  toStage(x: number, y: number) {
    return { x: this.left + x * this.cssScale, y: this.top + y * this.cssScale };
  }
}

export function loadImage(src: string): Promise<HTMLImageElement> {
  return new Promise((resolve, reject) => {
    const image = new Image();
    image.decoding = 'async';
    image.onload = () => resolve(image);
    image.onerror = () => reject(new Error(`Could not load ${src}`));
    image.src = src;
  });
}

export const reducedMotion = () => matchMedia('(prefers-reduced-motion: reduce)').matches;

/** Whether the game is showing (not the text version, nor under the mode chooser, src/game/landing.ts). */
export const gameOn = () => {
  const list = document.documentElement.classList;
  return list.contains('game') && !list.contains('choosing');
};
