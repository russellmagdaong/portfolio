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
| `arrow.aseprite` | The marker over where Russell runs to after a click: tag `bob` (its animation and speed), slice `base` (the middle of its bottom edge sits on the spot). First drawn by `scripts/art/new-arrow.lua` | `src/assets/sprites/arrow.*` |
| `map.aseprite` | The town map's background and its slices (nothing you can click is painted in it) | `src/assets/map/` |
| `map-objects/<id>.aseprite` | Each building (and anything else on the map that reacts) as its own sprite | `src/assets/map-objects/<id>.*` |
| `hub.aseprite` | The front-view street that replaces the map: a 480x270 side-on view of the neighbourhood, in depth layers, with the floors, stairs and doors as slices (see "The hub"). One still frame; what moves is in `anim/hub.aseprite` | `src/assets/hub/` |
| `hub-objects/<id>.aseprite` | The six destinations on the hub (each shopfront, the house, the school gate) as sprites with idle/hover tags | `src/assets/hub-objects/<id>.*`, and the icon on its sign as `src/assets/sign-logos/<id>.png` (`scripts/art/sign-logos.lua`) |
| `font.aseprite` | The sign lettering as a font, for the site's titles and wordmark: the 5x7 capitals of the shop signs plus digits and marks, one glyph per 8x9 cell, 16 to a row, in the order of `scripts/art/font/chars.txt` (rows 1-7 the capitals, row 8 the one row of descent; any opaque pixel is ink). First drawn by `scripts/art/draw/font.lua`; edit it by hand from then on. Built with `npm run font` (not `npm run art`) | `src/assets/fonts/russm-sign.woff2` |
| `scenes/<scene>.aseprite` | One file per building's scene: the room's **still** art, one frame, with all its slices (its interactables are not painted in it) | `src/assets/scenes/<scene>/` |
| `anim/<scene>.aseprite`, `anim/hub.aseprite` | What moves in that room (rain, lights, the jeepney...), all frames (see "Still and moving layers") | put together with the still file, then exported with it |
| `objects/<scene>/<id>.aseprite` | A scene's interactables, one file each: the `object:<id>` and `prop:<id>` things (see "Scene objects") | `src/assets/objects/<scene>/<id>.*` |

The map, the buildings and the six scenes are grey placeholders for now (phase 3), made by
`bash scripts/art/placeholders.sh` (which runs `scripts/art/new-map.lua` and `scripts/art/new-scene.lua`). Drawing over them is phases 4
and 5. Each scene's `object:` slices are named after what its page shows: for example the arcade has
`object:odin` with `opens=odin`, which opens the panel with the id `odin` on `/projects`.
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

**Still and moving layers.** A room is two files, so its still art is edited once instead of on every frame:
`scenes/<scene>.aseprite` (or `hub.aseprite`) holds every layer that does not move, in one frame, and all the
slices; `anim/<scene>.aseprite` holds only the layers that move, with all their frames and durations. Each layer
in the anim file has `after=<layer>` in its user data: the layer it sits just above in the room (a still layer,
or another moving one). `npm run art -- scenes/<scene>` puts the two together (`scripts/art/combine-stills.lua`,
into `_work/combined/`) and exports that, so the game gets the layers in the same order as one file would give.
Keep the still file to one frame; to add something that moves, add a layer to the anim file with its `after=`.
To edit the still art with the moving layers in view, open both files side by side. `scripts/art/split-stills.lua`
made the split; the draw scripts split again whenever they redraw a room.

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
- `sort=<y>` draws the layer in front of the player only while his feet are behind that line (y less than it): for a thing standing out on the floor that he can walk behind, like the couch at home (`sort=207`, the back of its seat). Give such a thing its own layer. For something he can jump onto, use its `platform` slice's back edge (top + height - depth): the store's boxes, the arcade's dance pad, the trophy shop's pedestal and the post office's parcels are all `sort=204`. To move a thing already painted on `props` onto a layer of its own without redrawing it, run `scripts/art/sort-layer.lua` on the still file (it cuts the pixels inside a rectangle onto a new layer just above, with `sort=` set; the header of the script has the command).
- `stair` (hub) draws the layer in front of the player only while he is on a stairway (the railings: he climbs
  behind the handrail). His feet follow the `stairs:` diagonal, which runs along the tread tops.
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
| `platform` | `depth=10` | Something he can jump onto: its top edge is the surface |
| `show:<id>` | `look=paper` (or `screen`, `shelf`) | Content that is part of the scene: the page's `<Show id>` block is laid over this rectangle and moves with it (a poster's text, the PC screen, the tools on a shelf). Draw the poster, board or screen itself in the art; leave its middle plain so the text reads |
| `prop:<id>` | `tip=<id>` | A prop that shows the page's `<Tip id>` card when pointed at or walked up to (the guitar, the console) |
| `object:<id>` | `opens=<id>; prompt=<word>` | One of the few things that open a panel (arcade cabinets, the mirror, the counter), e.g. `object:odin` with `opens=odin; prompt=Play` |

Several slices may share a name (several `platform`s).

Most content is a `show:`: the visitor reads it in the room without opening anything. Keep `object:` for things
that are used, like playing a cabinet. The text in a `show:` is HTML, sized with the art (3.5 art pixels per
letter height), so size the slice for the text it holds.

A `platform` slice covers the front face of the thing: its top edge is the surface he lands on, its bottom edge is
where the thing meets the floor, and `depth=10` says how far back it reaches. He cannot walk through a platform;
he jumps onto it, and when sent somewhere with a click he finds his way round it.

**Scene objects** (`objects/<scene>/<id>.aseprite`): each `object:<id>` or `prop:<id>` slice of a scene can have its
own sprite file, named after the slice (`prop:guitar` in `scenes/home` is `objects/home/guitar.aseprite`). The game
draws it just in front of the scene's `props` layer, and its outline (the yellow one when pointed at) follows the
sprite. In the file:

- a `base` slice: its bottom edge is where the bottom of the scene slice falls. The game stands the middle of
  `base` on the middle of the scene slice's bottom edge. Grow or shrink the canvas freely (Sprite > Canvas Size
  moves the slice along); to move the object in the room, move the scene slice (or `base`).
- a tag `idle` (one frame or an animation), and optionally `hover`, played while it is pointed at or he is in
  reach.

The scene slice is still what he walks up to and what is clicked, so if the object gets much bigger or smaller,
resize the slice in the scene to match. An object is drawn in front of him while his feet are behind the bottom edge of its scene
slice (where it stands), or behind the slice's `sort=<y>` if it has one: one that stands out on the floor sorts
itself, and one against the wall (bottom edge above the floor band) is always behind him. The objects were cut off the `props` layers by
`scripts/art/split-objects.lua`, with the boxes listed in `scripts/art/objects.lua`. Re-running a scene's draw
script cuts those boxes again and never touches an existing object file. Scenes without objects (school, store,
trophy shop) have no folder: their content is all `show:` boards.

**The map** (`map.aseprite`, 480x270, with the 320x180 middle always on screen) is only the background: ground,
roads, scenery nobody uses. Its layers work as in a scene. Its slices:

| Slice | User data | Meaning |
|---|---|---|
| `building:<id>` | `scene=<id>; door=<point id>` | Where the building's sprite stands (the middle of the slice's bottom edge) and what you can click; `door` names the point he walks to. `<id>` is a place in `src/game/places.ts` |
| `point:<id>` | `links=<id>,<id>` | A spot on the paths (the middle of its bottom edge); `links` lists the points a straight path joins it to. Links work both ways |
| `spawn` | `at=<point id>` | Where he starts on a first visit |

**The hub** (`hub.aseprite`, 480x270, the middle 320x180 always on screen) is the front view of the street that
replaces the map: one side-on picture, drawn by `scripts/art/draw/hub.lua` from Codex's concept D. Its layers,
back to front, are `sky` (`speed=0.1`), `far` (the city through the gap and above the skyway, `speed=0.3`),
`skyway` (the deck, what stands on it, and the side blocks it passes in front of), `buildings` (pillars,
landings, the footbridge, the shops' wall, the stairs), `street` (sidewalk and road),
`reflections` (the signs' light on the wet road, animated), `jeepney` (animated, parked on the road; `sort=230`, so
always in front of him on the sidewalk), `front` (`over`: the near railings of the bridge and
the stairs) and `rain` (`over`, animated). The destinations are not painted in it; they are `hub-objects/<id>`
sprites. Russell walks on **two levels**, each with its own `floor` slice:

| Slice | User data | Meaning |
|---|---|---|
| `floor` | `level=street` or `level=upper` | Where his feet can go on that level (the sidewalk; the two landings and the footbridge between them, one continuous band) |
| `stairs:<id>` | `lower=street; upper=upper; up=right` (or `up=left`) | A stairway. The slice's diagonal is the line his feet follow: from its bottom corner on the low side (on the lower level's floor band) to its top corner on the high side (on the upper one's), so draw it from the foot of the steps to the landing, over the step tops. `up` says which end is the top. Walking into it from either end carries him along that line to the other level |
| `spawn` | `level=street` | Where he appears: the middle of its bottom edge |
| `building:<id>` | `scene=<id>; level=...` | Where the destination's sprite stands (the middle of its bottom edge) and what you can click |
| `door:<id>` | `level=street` or `level=upper` | Where he walks to in front of that destination (the middle of its bottom edge); Home and School are on the upper level |
| `jeep` | | The jeepney: clicking inside it (or E on the sidewalk beside it) puts him aboard; it drives off to the right and the text version of the site fades in. Back in the game it drives in from the left and he gets off. It is outlined while pointed at |

Every doorway is taller than Russell (33 px standing, 35 at the top of his walk): the shop doors are 40 px with
38-39 px clear, the Home and School doors 44 px with 42 clear, so his head stays under the lintel even at the back
of the floor band. `art/_work/claude/hub-doors.png` shows him at all six.

**Hub objects** (`hub-objects/<id>.aseprite`): one sprite per destination, on a transparent canvas, in the same
shape as the map objects: tags `idle` (a steady sign, or a few frames with uneven durations for a sign that
flickers: the arcade and the post office) and `hover` (the sign's letters white, its box lit, and a one-pixel rim
in the sign's colour round the whole sprite), and a `base` slice whose bottom middle sits on the `building:` slice.

**Map objects** (`map-objects/<id>.aseprite`): one sprite per building, on a transparent canvas.

- Tags: `idle`, and `hover` (shown while it is pointed at, picked with the arrow keys, or he stands at its door).
  More tags (a door opening, a sign flickering) can be added later.
- Slice `base`: the middle of its bottom edge sits on the building's spot on the map. The engine sorts sprites
  and Russell by that line, so he can walk behind things.

## What `npm run art` checks

- Every exported colour should be in `palette.gpl`. Colours that are not are listed with the tags or layers
  they are in. Effects may break this on purpose (the red hurt flash and the fade in `russell.aseprite`).
- It never changes a `.aseprite` file.

## The template and the licence

`russell.aseprite` is repainted over the Ozzbit Games "male hero" template. The template itself, and any file that
still holds its pixels (like a reference layer), stays in `art/_work/` or outside the repository: the licence
allows using and changing the art, not handing the template on.
