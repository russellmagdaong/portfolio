// Makes the two icon files that cannot be SVG, from public/favicon.svg: favicon.ico, for the
// browsers and tools that only ever look for that, and apple-touch-icon.png, for iPhone and
// iPad home screens and bookmarks. Run it again after changing the SVG:
//
//   node scripts/favicons.mjs
//
// sharp is not listed in package.json: it comes with Astro, which uses it for images.
import { readFile, writeFile } from 'node:fs/promises';
import sharp from 'sharp';

const svg = await readFile('public/favicon.svg');
// The SVG is drawn 32 units square. Raising the density makes sharp draw it at the size asked
// for, instead of drawing it small and stretching it.
const draw = (size) => sharp(svg, { density: (72 * size) / 32 }).resize(size, size).png();

// An .ico file is a small table of contents followed by the images. One 32px PNG is enough.
const small = await draw(32).toBuffer();
const header = Buffer.alloc(22);
header.writeUInt16LE(1, 2); // type: icon
header.writeUInt16LE(1, 4); // one image
header.writeUInt8(32, 6); // width
header.writeUInt8(32, 7); // height
header.writeUInt16LE(1, 10); // colour planes
header.writeUInt16LE(32, 12); // bits per pixel
header.writeUInt32LE(small.length, 14);
header.writeUInt32LE(header.length, 18); // where the image starts
await writeFile('public/favicon.ico', Buffer.concat([header, small]));

// iOS does not keep transparency, and rounds the corners itself, so the icon sits on the
// page's own black with a little room around it.
const SIZE = 180;
const MARGIN = 14;
await sharp({ create: { width: SIZE, height: SIZE, channels: 4, background: '#050508' } })
  .composite([{ input: await draw(SIZE - MARGIN * 2).toBuffer(), left: MARGIN, top: MARGIN }])
  .png({ compressionLevel: 9 })
  .toFile('public/apple-touch-icon.png');

console.log('Wrote public/favicon.ico and public/apple-touch-icon.png');
