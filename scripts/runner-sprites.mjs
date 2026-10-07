// Turns the runner's animations from GIFs into the one sprite sheet the minigame uses
// (src/components/Runner.astro). Run it again whenever the GIFs change:
//
//   node scripts/runner-sprites.mjs <folder holding the man_*.gif files listed in CLIPS below>
//
// Each animation becomes one row of src/assets/runner/man.png, one frame per column, shrunk back to
// one image pixel per pixel of the artwork and cropped to the space the character actually uses.
// man.json beside it records the frame size, where the character stands in a frame, and the
// length and speed of each row.
//
// The GIFs do not have to be the same size. They are lined up by the bottom edge, which is the
// ground, and by the middle of their width, which is where the character is drawn.
//
// sharp is not listed in package.json: it comes with Astro, which uses it for images.
import { mkdir, writeFile } from 'node:fs/promises';
import { join } from 'node:path';
import sharp from 'sharp';

const CLIPS = [
  { name: 'idle', file: 'man_idle.gif' },
  { name: 'run', file: 'man_run.gif' },
  // The game moves the sprite up and down itself, so the rise that is drawn into the jump is
  // taken out: each frame is dropped until its feet are on the ground.
  { name: 'jump', file: 'man_jump.gif', grounded: true },
  { name: 'slide', file: 'man_slide.gif' },
  { name: 'death', file: 'man_death.gif' },
];
const OUT = 'src/assets/runner';

const source = process.argv[2];
if (!source) {
  console.error('Usage: node scripts/runner-sprites.mjs <folder with the GIFs>');
  process.exit(1);
}

const gcd = (a, b) => (b ? gcd(b, a % b) : a);

// Reads a GIF as a stack of frames, one under the other, in RGBA.
const clips = [];
for (const clip of CLIPS) {
  const image = sharp(join(source, clip.file), { animated: true }).ensureAlpha();
  const { pages, pageHeight, delay } = await image.metadata();
  const { data, info } = await image.raw().toBuffer({ resolveWithObject: true });
  clips.push({ ...clip, data, width: info.width, height: pageHeight, count: pages, fps: Math.round(1000 / delay[0]) });
}

// The GIFs are exported enlarged, every pixel of the artwork a square block. The block size is
// the largest number that divides every unbroken run of one colour along a row.
let scale = 0;
for (const { data, width, height, count } of clips) {
  for (let row = 0; row < height * count; row += 1) {
    let run = 1;
    for (let x = 1; x < width; x += 1) {
      const i = (row * width + x) * 4;
      if (data.readUInt32LE(i) === data.readUInt32LE(i - 4)) run += 1;
      else {
        scale = gcd(scale, run);
        run = 1;
      }
    }
    scale = gcd(scale, run);
  }
}

/*
 * Shrinks every frame to one pixel per block, and notes the box its opaque pixels fall in.
 * The box is measured the way the game thinks: `left` and `right` are columns counted from the
 * middle of the artwork (so they can be negative), and `top` is how many rows up from the
 * ground the highest pixel is.
 */
for (const clip of clips) {
  const w = clip.width / scale;
  const h = clip.height / scale;
  clip.frames = [];
  for (let f = 0; f < clip.count; f += 1) {
    const pixels = Buffer.alloc(w * h * 4);
    const box = { left: Infinity, right: -Infinity, top: -1, gap: h };
    for (let y = 0; y < h; y += 1) {
      for (let x = 0; x < w; x += 1) {
        const from = ((f * clip.height + y * scale) * clip.width + x * scale) * 4;
        clip.data.copy(pixels, (y * w + x) * 4, from, from + 4);
        if (clip.data[from + 3] === 0) continue;
        box.left = Math.min(box.left, x - w / 2);
        box.right = Math.max(box.right, x - w / 2);
        box.top = Math.max(box.top, h - 1 - y);
        box.gap = Math.min(box.gap, h - 1 - y);
      }
    }
    // How many rows the frame is lowered by when it is copied into the sheet.
    const drop = clip.grounded ? box.gap : 0;
    clip.frames.push({ pixels, drop, box: { left: box.left, right: box.right, top: box.top - drop } });
  }
  clip.w = w;
  clip.h = h;
}

// One cell size for everything: the smallest box that holds every frame of every animation,
// so that the character does not shift when the game changes from one animation to another.
const boxes = clips.flatMap((clip) => clip.frames.map((frame) => frame.box));
const left = Math.min(...boxes.map((box) => box.left));
const cellWidth = Math.max(...boxes.map((box) => box.right)) - left + 1;
const cellHeight = Math.max(...boxes.map((box) => box.top)) + 1;
const columns = Math.max(...clips.map((clip) => clip.count));

const sheet = Buffer.alloc(columns * cellWidth * clips.length * cellHeight * 4);
clips.forEach((clip, row) => {
  clip.frames.forEach((frame, column) => {
    for (let y = 0; y < cellHeight; y += 1) {
      // The row of the shrunk frame that lands on this row of the cell, both counted from the top.
      const sourceY = clip.h - cellHeight + y - frame.drop;
      if (sourceY < 0 || sourceY >= clip.h) continue;
      const from = (sourceY * clip.w + left + clip.w / 2) * 4;
      const to = ((row * cellHeight + y) * columns * cellWidth + column * cellWidth) * 4;
      frame.pixels.copy(sheet, to, from, from + cellWidth * 4);
    }
  });
});

await mkdir(OUT, { recursive: true });
await sharp(sheet, { raw: { width: columns * cellWidth, height: clips.length * cellHeight, channels: 4 } })
  .png({ compressionLevel: 9 })
  .toFile(join(OUT, 'man.png'));

const info = {
  width: cellWidth,
  height: cellHeight,
  // The column of a frame that the middle of the artwork falls on. The game places him by this,
  // so he stays put on screen even if a new animation makes the frames wider.
  anchor: -left,
  clips: Object.fromEntries(clips.map((clip, row) => [clip.name, { row, frames: clip.count, fps: clip.fps }])),
};
await writeFile(join(OUT, 'man.json'), `${JSON.stringify(info, null, 2)}\n`);

console.log(`Artwork is enlarged ${scale}x. Frames are ${cellWidth}x${cellHeight}, with the middle at column ${-left}.`);
for (const clip of clips) console.log(`  ${clip.name}: ${clip.count} frames at ${clip.fps} a second`);
console.log(`Wrote ${join(OUT, 'man.png')} and man.json`);
