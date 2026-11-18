# Working on one scene at a time

Each scene can be worked on by itself, in its own session. This page says which files belong to each scene, the
loop for editing one, and what to paste into a new Claude session to start on it.

## The scenes and their files

| Scene | Page | Room (still) | Objects (`art/objects/…`) | Page source | Draw script |
|---|---|---|---|---|---|
| Home | `/` | `art/scenes/home.aseprite` | `home/`: mirror, guitar, console, camera, flag, trophy | `src/pages/index.astro`, `src/components/Mirror.astro` | `scripts/art/draw/home.lua` |
| School | `/about` | `art/scenes/school.aseprite` | `school/`: thesis (on the bookshelf) | `src/pages/about.astro` | `scripts/art/draw/school.lua` |
| Arcade | `/projects` | `art/scenes/arcade.aseprite` | `arcade/`: nova, odin, tako, algebrawl | `src/pages/projects.astro`, `src/content/projects/*.md` | `scripts/art/draw/arcade.lua` |
| Tools: the computer shop (was the sari-sari store) | `/tools` | `art/scenes/store.aseprite` | none (four boards: a TV, a monitor, a terminal, a whiteboard) | `src/pages/tools.astro` | `scripts/art/draw/store.lua` |
| Trophy shop | `/credentials` | `art/scenes/trophy-shop.aseprite` | none (boards only) | `src/pages/credentials.astro` | `scripts/art/draw/trophy-shop.lua` |
| Post office | `/contact` | `art/scenes/post-office.aseprite` | `post-office/`: counter | `src/pages/contact.astro` | `scripts/art/draw/post-office.lua` |
| The street | `/map` | `art/hub.aseprite` | `art/hub-objects/`: the six fronts | `src/pages/map.astro` | `scripts/art/draw/hub.lua` (`--script-param only=<id>` redraws one front and leaves `hub.aseprite` alone) |

Every room's moving layers (rain, lights; the street's jeepney and road reflections too) are in
`art/anim/<scene>.aseprite` (`art/anim/hub.aseprite`). The room file itself is one still frame: edit it once and
every frame of the game gets it.

Shared by every scene, so change them in one session at a time: `src/game/*.ts` (the engine), `src/styles/game.css`,
`src/data/site.ts` (the words), `art/palette.gpl`, `scripts/art/draw/kit.lua`, `art/README.md`.

## The loop

1. Open the file in Aseprite (`C:\aseprite\build\bin\aseprite.exe`): the room (still, one frame), what moves in
   it (`art/anim/<scene>.aseprite`), or one object in `art/objects/<scene>/`. Use `art/palette.gpl`.
2. Edit and save. Keep to the rules in `art/README.md`: the layer names and their user data, the slices, the
   180-row safe band. In an object file, keep its `base` slice and its `idle` tag (add `hover` if you like).
3. Export just that scene:

   ```
   npm run art -- scenes/home objects/home/
   ```

   (`scenes/<scene>` is the room, still and moving parts together; `objects/<scene>/` its objects, with the
   trailing slash so the street's `hub-objects` are left alone. For the street: `npm run art -- hub.aseprite`.)
   The export checks the files and says what is wrong.
4. Look at it: `astro dev --background`, then open the page. After **adding** a file (a new object), restart the
   dev server (`astro dev stop`, then start it again); it only picks up new files on start.
5. Note what changed in `art/HANDOFF.md` (one line: date, who, file, what).

## Don't re-run the draw scripts after hand edits

`scripts/art/draw/<scene>.lua` drew each room from code and **rewrites the whole room file, and its anim file**,
when run. Once you
have edited a room in Aseprite by hand, that file is the source: do not run its draw script again (or ask Claude
to change the script and redraw, knowing your hand edits to the room go). The object files are safe either way:
a draw script never writes an existing object file.

### Hand-edited so far (keep this list up to date)

| File | Hand edit | So never run |
|---|---|---|
| `art/hub.aseprite`, `art/anim/hub.aseprite` | Russell's edits to the street | `hub.lua` (except `--script-param only=<id>` for one hub object) |
| `art/scenes/home.aseprite`, `art/anim/home.aseprite` | Russell's edits to his room | `home.lua` |
| `art/anim/arcade.aseprite` | Russell removed the animated people's sprites from the `life` layer | `arcade.lua` (it would draw them back) |
| `art/anim/store.aseprite` | Russell removed the animated people's sprites from the `life` layer | `store.lua` (it would draw them back) |
| `art/anim/post-office.aseprite` | Russell removed the people | `post-office.lua` (it would draw them back) |

If a change to one of these rooms really needs its draw script, change the script first so it no longer draws
what Russell removed (for the arcade and store: no people on `life`), ask Russell, and only then run it. Otherwise
edit the `.aseprite` files directly. Don't add people or characters to any scene: Russell removed them from the
arcade, the store and the post office, and doesn't want them generated anywhere.

## Adding an interactable

1. In the room, add the slice: `prop:<id>` with `tip=<id>` (shows a card when pointed at) or `object:<id>` with
   `opens=<panel id>; prompt=<word>` (opens a panel with E).
2. Make `art/objects/<scene>/<id>.aseprite`: the object on a transparent canvas, a `base` slice along the bottom
   edge of where it stands in the room (as wide as the room's slice), and an `idle` tag.
3. Give it its words: a prop's card is an entry in `interests` in `src/data/site.ts` (home) or a `<Tip>` on the
   page; an object needs a `<Panel id>` on the page.
4. Export, restart the dev server, check.

## Starting a session on one scene

Paste this into a new Claude session, with the scene filled in:

```
I'm working on the <SCENE> scene only (<PAGE>). Read art/WORKFLOW.md, art/README.md and the last entries of
art/HANDOFF.md first. Its files: art/scenes/<scene>.aseprite, art/objects/<scene>/ and <PAGE SOURCE>.
I edit the art by hand in Aseprite now, so don't run scripts/art/draw/<scene>.lua unless I ask.
Don't touch other scenes' files. If a change needs the engine (src/game/) or shared files, tell me first:
another session may be working on them.
Check your changes with headless Edge screenshots (see your memory notes), keep the build passing, and
don't commit unless I ask.

Here is what I want: <WHAT>
```
