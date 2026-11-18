"""
The site's icons, from pixel-me's head (Russell, 2026-11-18): the first idle frame of
src/assets/sprites/russell.png, a 16x16 crop round the head, on beige (the corkboard's
tabs, #dcbb85, Russell's pick): on the night card his black hair was lost in a dark tab bar.

Writes public/favicon.svg (one square per pixel, sharp at any size), public/favicon.ico
(16, 32 and 48, each a whole-number enlargement) and public/apple-touch-icon.png (180).

    python scripts/art/icons.py
"""
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
SPRITE = ROOT / 'src/assets/sprites/russell.png'
PUBLIC = ROOT / 'public'

FRAME = (46, 70)  # one frame of the sheet (russell.json)
HEAD = (15, 36, 31, 52)  # x0, y0, x1, y1 in the frame: hair to shoulders
CARD = (0xDC, 0xBB, 0x85, 255)  # beige, the corkboard's tabs: the background

frame = Image.open(SPRITE).convert('RGBA').crop((0, 0, *FRAME))
head = frame.crop(HEAD)
icon = Image.new('RGBA', head.size, CARD)
icon.alpha_composite(head)


def scaled(size: int, pad: int = 0) -> Image.Image:
    """The icon at a whole-number scale, centred on the background."""
    k = (size - 2 * pad) // icon.width
    big = icon.resize((icon.width * k, icon.height * k), Image.NEAREST)
    out = Image.new('RGBA', (size, size), CARD)
    out.alpha_composite(big, ((size - big.width) // 2, (size - big.height) // 2))
    return out


# favicon.ico: 16, 32 and 48.
scaled(48).save(PUBLIC / 'favicon.ico', sizes=[(16, 16), (32, 32), (48, 48)], append_images=[scaled(16), scaled(32)])

# apple-touch-icon: 160 px of head (10x) in 180, so iOS's rounded corners do not cut the hair.
scaled(180, pad=10).convert('RGB').save(PUBLIC / 'apple-touch-icon.png', optimize=True)

# favicon.svg: a run of squares per row, same colours merged along the row.
rows = []
for y in range(icon.height):
    x = 0
    while x < icon.width:
        c = icon.getpixel((x, y))
        end = x
        while end + 1 < icon.width and icon.getpixel((end + 1, y)) == c:
            end += 1
        if c != CARD:
            rows.append(f'<rect x="{x}" y="{y}" width="{end - x + 1}" height="1" fill="#{c[0]:02x}{c[1]:02x}{c[2]:02x}"/>')
        x = end + 1
svg = (
    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 16 16" shape-rendering="crispEdges">\n'
    '  <!-- Pixel-me\'s head, from the game sprite (scripts/art/icons.py). -->\n'
    f'  <rect width="16" height="16" fill="#{CARD[0]:02x}{CARD[1]:02x}{CARD[2]:02x}"/>\n  '
    + '\n  '.join(rows)
    + '\n</svg>\n'
)
(PUBLIC / 'favicon.svg').write_text(svg, encoding='utf-8')
print('wrote favicon.svg, favicon.ico, apple-touch-icon.png')
