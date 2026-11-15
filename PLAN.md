# Portfolio revamp: a pixel town you walk around

Agreed with Russell on 2026-11-15. Keep this file up to date as phases finish (see Status at the bottom).

## The idea

The site becomes a small 2D pixel game:
- A **top-down town map** of a made-up Manila neighbourhood at night works as the dashboard.
- Each building on the map opens a **side-on scene** for one part of the portfolio.
- The scenes use the Scott Pilgrim game as the reference for point of view and environment building: side-on, slightly from above, with a visible floor you can move along in depth, and dense street detail. Take the view and the density from it, not its levels, characters or Toronto. The place is original.
- The player is a pixel sprite of Russell.

## Buildings and scenes

| Building | Scene | Content |
|---|---|---|
| **Home** (the player starts here) | Russell's room | **The mirror** (De-pixelate, see below), name and role on a poster, the PC typing out the `dialogue` lines, interest objects (guitar or keyboard = music, console = gaming, editing setup = video), a corkboard with the controls, a résumé on the desk if `resumeUrl` is set, and the door out to the map |
| **School** | A made-up campus (the text still names FEU Tech) | About: the profile stats on a bulletin board, a DOST-SEI banner |
| **Arcade** | One cabinet per project | NOVA by the door ("now building"), ODIN (thesis, **defended**), TAKO, Algebrawl. Each opens a panel with its gallery, stack and play/source links. Plus **the runner minigame cabinet**, which is playable and uses the new sprite |
| **Sari-sari store** | Shelves behind the grille | Tools: the tool icons as goods |
| **Trophy shop** | Walls and shelves | Credentials: certificates framed on the wall, CTF flags on banderitas (fiesta bunting), hackathon trophies |
| **Post office** | The counter | Contact: the form, written as a letter. Socials are also always in the HUD |

All content comes from `src/data/site.ts` and `src/content/projects/`, as it does today.

## Controls

**Map:**
- Click or tap a building: the player walks there along the paths and goes in.
- Arrows/WASD move between buildings; Enter or Space goes in.

**Scenes:**
- A/D or ←/→ walk; W/S or ↑/↓ move along the floor's depth; Shift runs; **Space jumps**.
- **Mouse wheel / trackpad walks too:** scroll down = walk right, scroll up = walk left (the sprite turns to face the way it moves).
- Scenes are wider than the screen. Each has a **pixel-art scroll bar** at the bottom; **dragging it makes the player run**.
- Things that open show a key prompt when the player is near. E or Enter opens them; clicking or tapping one walks the player up to it and opens it.
- Content opens in HTML panels. With the pointer over a panel, the wheel scrolls the panel, not the player.
- **Leaving:** walk out the exit, press Esc, or use the **Exit button**, which walks the sprite to the exit and goes back to the map. The Exit button is for mouse and phone users.

**Phones get the game:**
- Tap the floor to walk, tap a thing to open it, Exit button to leave.
- Held sideways is best. In portrait, the scene goes on top and the text below.

**No page scrolling at all:** nothing is pinned, snapped, or hijacked. Russell rejected scroll snapping and pinned sections in October 2026.

## The sprite

- **Template:** the Ozzbit Games "male hero" pack in `C:\RUSSDM\Projects\GameDev_Templates\template_pro`.
  - `individual_sheets/*.png`: 128x128 cells; the character is about 20x32 px with 7-8 colours.
  - Repaint Russell's look over every frame, so the movement stays the template's animation.
- **Moves to make:** idle, idle_turn, walk, walk_turn, run, run_turn, run_to_idle, jump, fall (+ fall_loop), slide, hurt, death.
  - Skip combo_1-3 (sword attacks), dash, ledge_*, wall_*.
  - The runner cabinet needs idle, run, jump, slide and death.
- **Likeness:** from `C:\Users\Russell Magdaong\Downloads\Portrait Against a Warm Beige Backdrop.png` (1024x1536).
  - Hair: black mod cut with curtain bangs (parted, not a straight fringe), and a bit of a mullet behind the head.
  - Eyes: keep the template's eyes as they are.
  - Jacket: mid-blue denim chore jacket with a lighter patterned patch pocket on the left.
  - Shirt: rust/orange patterned, with an open collar showing at the front.
  - Small silver hoop earrings and a thin chain with a cross (1px glints at most).
  - Wide straight khaki/sand trousers, black socks, chunky dark-brown loafers with a gold bit.
- **Map sprite:** a small top-down version of him, facing front, back and sideways, with a short walk each.
- **Licence:**
  - Ozzbit's paid licence allows use and changes in personal or commercial projects; reselling as an asset is not allowed; credit is optional.
  - Never commit the template files, or any file that still contains template pixels (for example a guide layer). Keep working files that hold them in a git-ignored folder.
  - Commit only the repainted result. Credit "Ozzbit Games" in the README.
- **The old sprites are retired:** the pink runner (`src/assets/runner/man.*`, built by `scripts/runner-sprites.mjs`) and the ODIN `src/assets/hero/player.png`.

## The mirror (in Home)

- The mirror's reflection is live: it walks with the player, flipped, and stands idle with him.
- **De-pixelate** zooms in on the mirror, and the reflection resolves into the photo as the pixel blocks shrink: 16 → 8 → 4 → 2 → 1. **Pixelate** runs it backwards.
- The new photo replaces `src/assets/pics/juIYtZ3o1.jpg`.

## Aseprite holds the settings

Aseprite is at `C:\aseprite\build\bin\aseprite.exe` (self-built 1.3.16, not on PATH; batch mode and `--script` Lua work). Russell wants to adjust things in Aseprite, not in code.

- `art/russell.aseprite`:
  - tags = moves; frame durations = speed;
  - slice `feet` = where he stands;
  - slice `body` = the runner game's hit box while he is up; slice `slide` = the hit box while he slides.
  - Frames edited by hand in Aseprite are kept when `scripts/sprite/build-russell.lua` runs again.
- `art/russell-map.aseprite`: the top-down map sprite (Russell drew it himself, 2026-11-16).
- `art/map.aseprite`:
  - one slice per building (`building:arcade`, user data `scene=arcade`);
  - slices for the points on the paths.
- `art/scenes/<scene>.aseprite`:
  - layers by depth; layer user data like `speed=0.3` for background layers that move more slowly;
  - slices: `spawn`, `exit`, `floor` (where you can walk), `platform` (things you can jump onto), and `object:<id>` with user data naming what it opens (for example `opens=project:odin`).
- One shared palette file: `art/palette.gpl`.
- `npm run art` (`scripts/art/export.mjs`) exports PNG sheets plus JSON into `src/assets/` through the Aseprite CLI.
  - The path comes from an `ASEPRITE` environment variable, defaulting to the one above.
  - The exports are committed, so building and deploying never need Aseprite.
- **One file per scene**, so scenes can be drawn in parallel (by Claude, Fable helper agents or Codex) without clashing. A written art brief keeps them consistent: palette, pixel scale, light direction, outline rules, sign lettering.

## Pixel scale and rendering

- Scenes are drawn at roughly 320x180 and enlarged in whole steps only (4x on Russell's 1469x887 window). The 32 px character is about a fifth of the screen tall.
- Extra sky and floor are drawn beyond the frame, so the window size changes how much shows, never how sharp it is.
- One low-resolution canvas per scene, scaled with `image-rendering: pixelated`. The camera snaps to whole art pixels.
- The HUD and all content panels are HTML on top.

## Pages and fallbacks

- Each scene is its own Astro page (`/` Home, `/map`, `/about`, `/projects`, `/tools`, `/credentials`, `/contact`). Links and the Back button work, and every page's content is plain HTML for search engines, screen readers and visitors without JavaScript.
- Pages change with a pixel-wipe view transition. Leaving a building puts the player outside its door on the map.
- A **"Text version"** link shows the same page without the game, for recruiters in a hurry.
- With "reduce motion" on, the game still works, but background animation and wipes are off.
- **Retired:** the arcade-CRT hero, the horizon grid, the section arrivals and the character-select deck. Keep the content data, the Gallery logic and the contact-form logic.

## Content updates

- **NOVA** (`C:\RUSSDM\Projects\Personal Voice Assistant`, now **public** at https://github.com/russellmagdaong/nova-voice-assistant):
  - Add it as a project, written from its README: "Hey Nova" Windows voice assistant answering with Claude, offline wake word, Whisper, Kokoro voices, pixel-mascot notch.
  - Screenshots can come from its `samples/notch_preview_*.png` and `samples/mascot_frames.png`, or a fresh capture of NOVA's window.
- **ODIN** has been **defended**. Update `about.stats` ("Now building") and the `dialogue` lines, and make NOVA the "now building" project.

## Model and effort per phase

Revised 2026-11-16: phase 1 used about 40% of Russell's Fable allowance, so Fable is kept for drawing only.

| Phase | Model | Effort |
|---|---|---|
| 1, review fixes | Fable 5.2 | high (all of Russell's notes in one message) |
| 2. Aseprite setup | Opus 5.5 | medium |
| 3. Engine with placeholders | Opus 5.5 | high |
| 4. Home and Arcade | Fable 5.2 draws the scenes and the mirror; Opus 5.5 does the wiring (slices to engine, panels, runner cabinet) | high |
| 5. Content | Opus 5.5 | medium |
| 5. Other scenes and map art | Opus 5.5 draws to the art brief; Fable 5.2 only reworks a scene that falls short. No parallel helper agents | high |
| 6. Polish | Opus 5.5 | high |

To use less Fable:
- Start a fresh session for each phase. `PLAN.md` and memory carry the state.
- Send review notes in one batch.
- Make one contact sheet per round, not re-renders of every move.
- Stay at high effort. Use xhigh only for a frame that keeps coming out wrong.

## Build order

Each phase ends with screenshots for Russell. Use headless Edge as described in memory: no browser tool is attached.

1. **Sprite.**
   - Palette, then **two test frames** (idle and one walk frame) shown at 1x and 4x next to the photo. **Stop for Russell's OK.**
   - Then every move listed above, plus the map sprite.
   - Put the sheet into the current runner game straight away (`src/components/Runner.astro` reads frame size, anchor and clips from JSON; retune its `BODY`/`SLIDING_BODY` hit boxes).
2. **Aseprite setup.** The `art/` layout, the export script (`npm run art`), the git-ignored working folder and the art brief.
3. **Engine with grey placeholder boxes:**
   - the map and one scene;
   - every control (keys, wheel, drag-to-run bar, click/tap, Exit, Esc);
   - panels, pages and addresses, the text version, and the phone layout.
   Russell judges how it feels here, before any art.
4. **Home and Arcade in full art,** with the mirror, the project cabinets and the playable runner cabinet. Russell's review sets the bar.
5. **The other four scenes and the map art,** drawn in parallel, plus the content updates.
6. **Polish:**
   - background life (flickering signs, a jeepney passing on the map);
   - a frame-rate check on Russell's Intel UHD graphics;
   - a new `public/og.png` link preview;
   - the README rewritten for the new structure.

## Status

- [x] 1. Sprite (2026-11-16: Russell redrew the map sprite himself and moved on to phase 2)
- [x] 2. Aseprite setup (2026-11-16: `art/palette.gpl`, `npm run art`, `scripts/art/new-scene.lua`, `art/README.md` and `art/BRIEF.md`)
- [ ] 3. Engine with placeholders
- [ ] 4. Home and Arcade art
- [ ] 5. Other scenes, map art, content
- [ ] 6. Polish
