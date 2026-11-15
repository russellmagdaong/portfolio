# Art brief

The rules every scene and the map follow, so that scenes drawn by different hands (Russell, Claude, helper
agents, Codex) look like one place. How the files are set up is in [README.md](README.md).

## The place

A made-up neighbourhood in Manila, at night. Warm windows and sodium streetlights against a deep violet sky,
neon over the shops, wires everywhere. It is lived in and a little cluttered, never grim.

The point of view and density come from the Scott Pilgrim game: side-on, slightly from above, every surface busy
with small things. Take the **view and the density only**. Its levels, characters, signs and Toronto are not to be
copied, and nothing should look traced from it or from any other game.

Things that belong here (pick, don't use all of them at once): sari-sari stores with a grille and snack strips
hanging in it, jeepneys and tricycles, electric posts with tangled wires, capiz-shell windows, corrugated roofs
with rust, potted plants on every ledge, a karinderya with pots on the counter, a basketball hoop nailed to a
post, banderitas (fiesta bunting), plastic chairs, stray cats, a water tank on a roof.

## Pixel scale

- One art pixel is one pixel in the file. Never scale, rotate or blur art inside a file (no mixed pixel sizes).
  The site enlarges everything in whole steps (4x on a 1469x887 window).
- **Russell is about 32 px tall** side-on (20x32). Size everything from him:

  | Thing | Size |
  |---|---|
  | Door | 44 px tall |
  | Ceiling of a room | 70 px above the floor |
  | Counter, table | 16 px tall |
  | Arcade cabinet | 40 px tall |
  | Plastic chair | 14 px tall |
  | Jeepney | 40 px tall, 90 px long |

- A screen is 320x180. Scenes are 270 tall and two or three screens wide (640 or 960). Only y 45-224 is sure to
  show; the strips above and below are filler (see README.md).
- On the map, Russell is 14x19 (`russell-map.aseprite`); a building is about 48-80 px wide.

## The view

- **Scenes:** the back wall faces you flat, with no vanishing point. The floor is a band you look down onto,
  from its back edge at y 176 to y 224, and Russell can walk up and down inside it.
  - Things standing on the floor show a thin top face, about a third of their depth.
  - Edges that go back into depth are drawn at a 1:2 slope (one across for every two up) and lean the same
    way across the whole scene.
  - Russell does not get smaller with depth, so neither do props.
- **The map:** seen from above at an angle, like the map sprite: roofs from above, with the front wall of each
  building showing below its roof, facing the viewer. Paths run between the buildings.

## Light

- The base light is **cool night**: shadows lean violet and blue (towards the sky colours), never towards black
  or grey.
- Lit surfaces lean **warm**, towards the sodium colours. Each scene has one main light (a streetlight, a shop
  window, a screen) and that light decides which side of things is lit. Write it in the layer user data or in a
  note on the `_guide` layer so whoever touches the scene next keeps it.
- Light from above unless a source says otherwise. Floors get pools of light under lamps.
- Neon throws its colour onto the wall right around the tube (one ring of the dim shade), no further.
- Russell's colours are fixed, so the floor band he walks over must stay mid-dark (concrete 3 to 5, wood 2 to 3),
  so his black outline and khaki trousers read against it.

## Colour

- Use **only `palette.gpl`**. Load it in Aseprite (Palette options > Load Palette). `npm run art` lists any
  colour that is not in it.
- If a colour is really missing, add it at the **end** of the palette and say so; never insert or reorder,
  because the first 18 entries must match `russell.aseprite`.
- Distance flattens colour: `far` uses only the sky colours and concrete 1-3; `mid` goes up to concrete 4;
  the near layers use the full range. The brightest colours (sodium 5, neon tubes, white) are for light sources
  and small glints only.

## Lines and shading

- **Characters:** a 1 px black outline (`K`) all round, as on the sprite.
- **Things that open** (cabinets, the mirror, the PC, the mailbox, ...): a 1 px `ink` outline and one glint, so
  they read as something to touch.
- **Everything else:** no black outline. Edges are a darker shade of the object's own colour, or no line at all.
- Flat shading in 2-3 tones per material, in clean clusters. No gradients, no pillow shading, no anti-aliasing
  against transparency, no stray single pixels except on purpose (stars, glints, rivets).
- The sky may be stepped bands of the sky colours, with a 2-pixel checker dither where two bands meet.

## Lettering

- Signs are hand-painted in style: blocky, slightly uneven, painted, not printed.
- Use a pixel alphabet: **3x5 capitals** for small text, **5x7** for big signs, 1 px between letters.
  Keep one alphabet per size across all scenes (copy the letters from a scene that has them).
- Tagalog and Taglish signs are welcome: "SARI-SARI STORE", "BAWAL TUMAMBAY DITO", "PASADA", jeepney route boards
  ("QUIAPO - CUBAO").
- **No real brands, logos, trademarks or real businesses.** Invent names.
- Text the visitor has to read (project names, descriptions, links) goes in the HTML panels, not in the art.
  Building names on signs are fine.

## Movement

- Keep background animation sparse: a few things per screen (a flickering sign, a fan, a blinking light).
- Flicker with uneven frame durations (for example 900, 80, 600, 80 ms); nothing faster than 80 ms per frame.
- Animate inside one layer across the sprite's frames; the export picks up the frames and durations.
- With "reduce motion" on, the site stops these, so nothing important may depend on them.

## Files and handing over

- One file per scene. Whoever draws a scene owns that file until it is handed over; don't edit someone else's.
- Start with `scripts/art/new-scene.lua` and keep its layers, slices and `_guide` layer.
- Put reference images on a hidden layer whose name starts with `_`. They are never exported, but copyrighted
  references must still stay in `art/_work/`, not in a committed file.
- Before handing over: `npm run art -- scenes/<name>`, read its warnings, and look at the exported PNGs.
