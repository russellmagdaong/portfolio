# art/

Every piece of pixel art on the site is drawn here in Aseprite. The `.aseprite` files are the source of truth:
the site reads its settings from them (tags, frame durations, slices, layer user data), so most tuning happens
in Aseprite, not in code. `npm run art` exports them into `src/assets/` (see the repo README). The style rules
for drawing are in [BRIEF.md](BRIEF.md).

## The files

| File | What it is | Exported to |
|---|---|---|
| `palette.gpl` | The one shared palette | (nothing; load it in Aseprite) |
| `russell.aseprite` | Russell side-on, every move (128x128 frames) | `src/assets/sprites/russell.*`, and the runner minigame's sheet in `src/assets/runner/` |
| `russell-map.aseprite` | Russell top-down, for the town map (16x24 frames) | `src/assets/sprites/russell-map.*` |
| `map.aseprite` | The town map (from phase 3 on) | `src/assets/map/` |
| `scenes/<scene>.aseprite` | One file per building's scene (from phase 3 on) | `src/assets/scenes/<scene>/` |
| `_work/` | Git-ignored working files. Anything that still holds template pixels lives here and is never committed or exported. | |

Any other `art/<name>.aseprite` is exported as a sprite to `src/assets/sprites/<name>.*`.

## Settings the site reads

### User data

Layers and slices carry settings in their **user data** (double-click the layer, or the slice with the slice tool,
and fill in "User Data"). Write `key=value` pairs separated by `;` or new lines. A word on its own means "on":

```
speed=0.3; over
```

### Sprites (`russell.aseprite`, `russell-map.aseprite`, ...)

- **Tags** are the animations. Each becomes one row of the exported sheet; a tag's name is what the code asks for
  (`idle`, `run`, `down`, `side`, ...). The tag's direction (forward, reverse, ping-pong) is exported too.
- **Frame durations** are the speed, frame by frame.
- **Slice `feet`**: where he stands is the middle of its bottom edge. Without it, he stands at the bottom of the
  drawing, in the middle of the canvas (`npm run art` says so).
- Other slices are exported with their user data. In `russell.aseprite`, `body` is the runner game's hit box
  while he is up and `slide` the one while he slides.
- The exported frame is the smallest box that holds every frame, so frames can be drawn anywhere on the canvas.
- Frames of `russell.aseprite` you edit by hand are kept when `scripts/sprite/build-russell.lua` runs again.

### Scenes (`scenes/<scene>.aseprite`) and the map

Start a new scene with the script, so it has the standard canvas, layers, slices and guide:

```
"C:\aseprite\build\bin\aseprite.exe" -b --script-param name=arcade --script scripts/art/new-scene.lua
```

(`width=960` makes it three screens wide; `placeholder=1` fills it with grey boxes for testing.)

**The canvas** is 270 px tall and as wide as the scene. Only the band from y 45 to 224 (180 rows) is sure to be
on screen; the rest shows on wider or taller windows, so fill it with more sky and more floor, never with anything
the visitor needs. The `_guide` layer marks that band (cyan), the floor's back edge (pink) and each 320 px
screen width (yellow).

**Layers**, bottom to top, are back to front. Each visible layer becomes its own PNG, trimmed to what is drawn.

| Layer | User data | |
|---|---|---|
| `sky` | `speed=0.1` | Moves past slowest |
| `far` | `speed=0.3` | Distant skyline |
| `mid` | `speed=0.6` | Nearer buildings, wires |
| `back` | | The scene's back wall; moves with the floor (speed 1) |
| `floor` | | The ground he walks on |
| `props` | | Things on the floor, behind him |
| `front` | `speed=1.2; over` | Foreground drawn in front of him |

- `speed` is how fast a layer moves past compared with the floor (1). Below 1 is further away.
- `over` draws the layer in front of the player.
- Add, rename or split layers freely; the code goes by the user data, not the names.
- **Hidden layers, and any layer whose name starts with `_`, are never exported.** Use them for guides and
  reference images.
- A layer that changes across frames (a flickering sign) is exported as a strip of its frames with their
  durations. A layer that is the same in every frame is exported as one image.
- Groups are exported as one image.

**Slices** in a scene (the slice tool, `C`):

| Slice | User data | Meaning |
|---|---|---|
| `floor` | | Where his feet can go (he walks left/right and up/down in depth inside it) |
| `spawn` | | Where he appears: the middle of its bottom edge |
| `exit` | `to=map` | Walking into it leaves the scene |
| `platform` | | Something he can jump onto: its top edge is the surface |
| `object:<id>` | `opens=<what>; prompt=<word>` | A thing that opens a panel, e.g. `object:odin` with `opens=project:odin; prompt=Play` |

Several slices may share a name (several `platform`s).

**The map** (`map.aseprite`) works the same way, with these slices:

| Slice | User data | Meaning |
|---|---|---|
| `building:<id>` | `scene=<id>; door=<point id>` | A building you can click; `door` names the point he walks to |
| `point:<id>` | `links=<id>,<id>` | A spot on the paths; `links` lists the points a straight path joins it to |
| `spawn` | | Where he stands when the site opens |

The exact slice set may still change while the engine is built in phase 3; this file will be kept in step.

## What `npm run art` checks

- Every exported colour should be in `palette.gpl`. Colours that are not are listed with the tags or layers
  they are in. Effects may break this on purpose (the red hurt flash and the fade in `russell.aseprite`).
- It never changes a `.aseprite` file.

## The template and the licence

`russell.aseprite` is repainted over the Ozzbit Games "male hero" template. The template itself, and any file that
still holds its pixels (like a reference layer), stays in `art/_work/` or outside the repository: the licence
allows using and changing the art, not handing the template on.
