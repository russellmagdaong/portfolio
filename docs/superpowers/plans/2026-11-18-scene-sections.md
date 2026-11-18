# Scene Sections Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task by task, inline, in one session. Russell chose inline execution in `docs/superpowers/next-session.md`: no subagents. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Turn the text version's five chapters plus Home into six scene stages (each place's interior, flat, at 2×), each with a hover-driven panel drawn from that room's material, and replace the top nav on wide screens with an Aki-style sidebar that folds into a rail.

**Architecture:** Each section renders its room from `sceneConfig(id)` (`src/game/config.ts`) as stacked layer images at 2×, with real buttons over the game's `object:` / `show:` / `prop:` slices. Over the room sits one `ScenePanel`: a list of items and one detail per item, rendered by Astro (all details in the page, so it works without JavaScript). `src/game/textpanels.ts` then makes it live: it shows one detail, switches on hover (120ms intent), click or focus, and syncs with the game through the existing `data-spot` ids. The sidebar is a sticky `<aside>` driven by the same scroll tracking `textsite.ts` already does for the top nav.

**Tech Stack:** Astro 5, TypeScript, plain CSS in `src/styles/text.css`, Aseprite CLI (Lua) for one art export, checks in `node:test` driving headless Edge (`scripts/check/browser.mjs`).

**Spec:** `docs/superpowers/specs/2026-11-18-scene-sections-design.md`. Read it first, especially "Shape outcome". The approved look is in the mockup generator `mock/gen2.mjs` in the 2026-11-18 session scratchpad. Where the scratchpad is gone, the spec's tables are the reference.

## Global Constraints

- **Never commit.** Russell commits. Leave every change in the working tree.
- **Don't re-run the art draw scripts** (`scripts/art/draw/`). `npm run art` exports are fine.
- **Colours only from `art/palette.gpl`**, plus the existing DESIGN.md tokens.
- **Pixel art at whole-number scales only** (2× rooms, 2× and 3× sidebar logos, 4× panel-sign logos), with `image-rendering: pixelated`.
- **No scroll hijacking, snapping or pinning.** The sidebar is `position: sticky` and never controls the scroll.
- **Title face** stays Jersey 10 until Russell approves `art/font.aseprite`. Anything read at length is in IBM Plex Sans.
- **Glow and blur:** no `text-shadow`, no blur or `drop-shadow` filters, no glow.
- **Hard shadows:** only on pressable things (straight 4px lip) and on the scene panels' own frames (the spec's game-panel exception).
- **Body text contrast** is at least 4.5:1 on its panel.
- **Spot ids stay:** every `data-place` and `data-spot` id that exists today stays on the page exactly once (`text-chapters.test.mjs` already pins the list).
- **Shop sign words**, exactly: HOME, ABOUT ME, PROJECTS, TOOLS, AWARDS, CONTACT.
- **Reduced motion** removes the room loops, panel wipes and the fold wipe.
- **Keep the animations Russell likes:**
  - the top bar's slide-in below 1181px
  - button presses
  - the "Russell was here" mark
- **Checks** run with `npm run check` against Russell's dev server on http://localhost:4321. Don't start a second server. Run `npm run check` once before Task 1 and note anything already failing. The handoff says two earlier fixes were never re-tested.

## Review Focus

1. **Ctrl+F on text in an unselected detail.** The browser should find it and show that detail. Inactive details use `hidden="until-found"`, and `beforematch` selects them (Task 4).
2. **Arriving from the game at a spot inside an unselected detail** (for example `tako`, or the `music` prop). The page should land on that section with that detail showing and the spot marked (Task 4).
3. **The longest write-up** (NOVA, about 300 words). It should still fit inside its room at 1469×887, with no panel taller than the art (Task 5).
4. **Widths between 900 and 1180px and phones** (390px). There should be no sideways page scroll, and the panel should never spill out of its stage (Task 6).
5. **A stored fold state that is junk, or storage that throws.** The sidebar should open by default without errors (Task 2).

---

### Task 1: Export the shop sign logos

**Files:**
- Create: `scripts/art/sign-logos.lua`
- Modify: `scripts/art/export.mjs` (after the hub-objects jobs, near line 64; and the header comment's "what goes where" list)
- Modify: `art/README.md` (one line under the exports list)
- Create (generated): `src/assets/sign-logos/<place>.png` for home, school, arcade, store, trophy-shop, post-office
- Test: `scripts/check/sign-logos.test.mjs`

**Interfaces:**
- Produces: `src/assets/sign-logos/<placeId>.png`. Each is the icon above the sign word on that place's shopfront, frame 0, transparent background, cropped to its pixels. Expected sizes: 8×8, except post-office at 8×6.

- [ ] **Step 1: Write the failing test** `scripts/check/sign-logos.test.mjs`. For each place id, read the PNG's IHDR width and height (bytes 16 to 23) and assert:

```js
assert.ok(w >= 6 && w <= 10 && h >= 5 && h <= 10, `${id} ${w}x${h}`);
```

- [ ] **Step 2:** Run `node --test scripts/check/sign-logos.test.mjs`. Expected: FAIL with ENOENT.
- [ ] **Step 3: Write `scripts/art/sign-logos.lua`.**
  - Params: `root`, `out`.
  - For each place, open `art/hub-objects/<id>.aseprite` and draw frame 0 into an `Image`.
  - Scan the box `{x, y, w}` with height 8:
    - home `51, 12, 14`
    - school `20, 9, 9`
    - arcade, store, trophy-shop, post-office `16, 9, 14`
  - Keep pixels with alpha > 0 and luminance > 45. Drop the rest.
  - Trim to the kept pixels' bounding box and save as `<out>/<id>.png`.
  - The session scratchpad's `icons.lua` is this script.
- [ ] **Step 4: Hook it into `export.mjs`.** Once the hub-objects jobs have run, if any ran, call Aseprite with `-b --script-param root=<ROOT> --script-param out=<ASSETS>/sign-logos --script scripts/art/sign-logos.lua`. Then run `npm run art -- hub-objects`.
- [ ] **Step 5:** Run `node --test scripts/check/sign-logos.test.mjs`. Expected: PASS. Open the six PNGs at 8× and check each is the icon alone: no sign border and no letters.

---

### Task 2: The sidebar

**Files:**
- Create: `src/components/text/Sidebar.astro`
- Modify: `src/data/site.ts` (add `placeLines`)
- Modify: `src/components/text/TextSite.astro` (render `<Sidebar />`, keep the `t-header` for below 1181px)
- Modify: `src/game/textsite.ts` (current-entry marking also covers the sidebar links; the fold button)
- Modify: `src/styles/text.css` (`.t-side*` and the page grid)
- Test: `scripts/check/text-sidebar.test.mjs`

**Interfaces:**
- Consumes: `src/assets/sign-logos/<place>.png` (Task 1).
- Produces:
  - `export const placeLines: Record<'home' | 'school' | 'arcade' | 'store' | 'trophy-shop' | 'post-office', string>` in `site.ts`.
  - Sidebar links are `<a href="#sec-…" data-goto="<place>">`. The existing `[data-goto]` click handling covers them.
  - `html[data-side="folded"]` while folded.
  - localStorage key `t-side`, with value `'folded'` or `'open'`.

**Details:**
- **The one-liners**, verbatim from the mockup (Russell may edit them later):
  - home: "Who's writing, and what I'm open to"
  - school: "4th-year CS at FEU Tech, DOST scholar"
  - arcade: "Games that teach: ODIN, TAKO, Algebrawl"
  - store: "Godot, C#, TypeScript and the rest"
  - trophy-shop: "Dean's List, hackathons, CTFs"
  - post-office: "Write me a letter"
- **Open layout, top to bottom:**
  - the wordmark plate
  - six entries, each with the logo at 2×, the sign word in Jersey 22 and the one-liner in Plex 14 concrete-soft
  - the bottom block: "Have an internship in mind? Let's talk →" (a link to `#sec-contact`), then Change UI (`data-change-ui`) and the fold button (`aria-expanded`, `aria-controls`)
- **Current entry:** ink background, white word, and `box-shadow: inset 3px 0 0 var(--sign)`.
- **Size:** 248px wide, starting once the street front ends (the sidebar lives beside the sections, not beside the front).
- **Folded:** a 64px rail with logos at 3× and the words visually hidden but still in the accessibility tree. The width change is a `steps(4)` wipe.
- **Breakpoints:** shown from 1181px up. At 1180px and below it is `display: none` and the existing `t-header` takes over unchanged. The top header is hidden from 1181px up.
- **Fold state** is read and written inside try/catch. Any value other than `'folded'` means open.

- [ ] **Step 1: Write the failing tests** in `text-sidebar.test.mjs`:
  - `the sidebar lists the six places with their sign logos`: at 1469×887, `.t-side a[data-goto]` has 6 entries in nav order, and each holds an `img` whose `naturalWidth * 2 === img.width`.
  - `the current entry follows the section being read`: call `textAt({place:'store', id:null})`, wait 300ms, and the `aria-current="location"` link has `data-goto="store"`.
  - `folding is remembered, and junk in storage opens it`: click the fold button, then `html.dataset.side === 'folded'`. Reload via `about:blank`, and it's still folded. Set `localStorage.t-side='junk'`, reload, and it's open.
  - `below 1181px the top bar is back`: at 1100×887, `.t-side` is not displayed and `.t-header` is.
  - `the sidebar never moves the scroll`: `getComputedStyle(.t-side).position === 'sticky'`, and scrolling with `scrollTo(0, 3000)` leaves `scrollY === 3000`.
- [ ] **Step 2:** Run `node --test scripts/check/text-sidebar.test.mjs`. Expected: FAIL, with no `.t-side`.
- [ ] **Step 3:** Implement `Sidebar.astro`, `placeLines`, the CSS, and the fold and current-entry wiring in `textsite.ts`. Widen the `links` query to `'.t-nav [data-goto], .t-side [data-goto]'`.
- [ ] **Step 4:** Run `node --test scripts/check/text-sidebar.test.mjs`. Expected: PASS.

---

### Task 3: Scene stages replace the chapter openers

**Files:**
- Create: `src/data/stages.ts`
- Create: `src/components/text/SceneStage.astro`
- Modify: `src/components/text/Chapter.astro` (opener strip → `SceneStage`, column → panel slot)
- Modify: `src/components/text/PostcardBack.astro` (Home becomes a stage too; the letter content moves into its panel in Task 5)
- Modify: `src/styles/text.css` (`.t-stage*`; remove `.t-opener*`)
- Test: `scripts/check/text-stage.test.mjs`
- Modify: `scripts/check/text-chapters.test.mjs`. Replace the test "every chapter opens with its shopfront and a title" with the stage test below. In the shadow test, also allow elements inside `.t-panel` and `.t-stage`.

**Interfaces:**
- Consumes: `sceneConfig(id)` from `src/game/config.ts` (layers with `src, x, y, width, height, frames, durations`; `slices`; `objects[]` with `slice` and `sprite`).
- Produces:
  - In `stages.ts`:
    - `export interface StagePlan { focus: number; panel: 'left' | 'right'; panelWidth: number; loop: string | null; arrows: { x: number; y: number; label: string }[]; labels: Record<string, string> }`
    - `export const stages: Record<string, StagePlan>`, keyed by place id
    - `export function targetsOf(slices: Slice[]): { id: string; x: number; y: number; width: number; height: number }[]`. The id rule is the one in `spot.ts`: `object:<x>` → `data.opens`; `show:<id>` → id; `prop:<x>` → `data.tip`. The other slices are skipped.
  - `SceneStage.astro` props: `{ place: string; title: string; gameName: string; titleId: string }`. It renders `<div class="t-stage" data-stage>` holding:
    - `.t-stage-art`, sized to art width ×2 by 540
    - every layer at frame 0
    - object sprites at frame 0
    - one `<button class="t-target" data-target="<id>" aria-label="…">` per target, at slice ×2
    - board labels and arrows
    - the title plate (`h2#<titleId>`) and the postmark
    - a `<slot />` for the panel
- **Stage values** (art pixels; the panel sits 20px in from its side and 20px from the top):

| place | focus | panel | panelWidth | loop |
|---|---|---|---|---|
| home | 0 | right | 640 | lights (if present, else null) |
| school | 30 | left | 640 | lights / null |
| arcade | 0 | right | 660 | lights |
| store | 0 | left | 640 | lights |
| trophy-shop | 40 | left | 560 | lights / null |
| post-office | 0 | left | 640 | lights / null |

- **Arcade arrows:** `{x:139,y:104,label:'Hover a cabinet'}`. **Store arrows:** `{x:387,y:62,label:'Hover a screen'}`. Store labels: `{'tools-backend-and-data':'BACKEND AND DATA · 5','tools-also-comfortable-in':'ALSO COMFORTABLE IN · 3'}`. Derive the counts from `tools` rather than hard-coding them.
- **Art placement:**
  - Narrower stage: the art's left edge is `-focus × 2px`, clamped so the art's right edge never leaves a gap.
  - Wider stage: the art is centred on ink.
- **Loop layer:** a `steps(frames)` animation over its sheet, using the layer's `durations`. Other multi-frame layers show frame 0.

- [ ] **Step 1: Write the failing tests** in `text-stage.test.mjs`:
  - `every section is a room at 2x`:
    - Each `section[data-place]` other than `street` has one `.t-stage`.
    - `stage.offsetHeight === 540` at 1469×887.
    - Each `.t-stage-art img` has `width === naturalWidth * 2` (for multi-frame sheets, compare against the frame width from its wrapper).
    - Each has `image-rendering: pixelated`.
  - `the game's objects are buttons over the art`:
    - `#sec-projects .t-target` ids include `odin`, `tako`, `algebrawl` and `nova`.
    - Each is a `BUTTON` with a non-empty `aria-label`.
  - `no glow, no blur on the room`: filters and text-shadows are `none` inside `.t-stage-art`.
  - `reduced motion stills the room`: `openPage('/', { reducedMotion: true })`, then `document.getAnimations().filter(a => a.effect?.target?.closest?.('.t-stage')).length === 0`.
- [ ] **Step 2:** Run `node --test scripts/check/text-stage.test.mjs scripts/check/text-chapters.test.mjs`. Expected: the new tests FAIL.
- [ ] **Step 3:** Implement `stages.ts`, `SceneStage.astro`, the `Chapter.astro` change and the CSS. Keep each chapter's existing content in the slot for now. Task 5 moves it into panels.
- [ ] **Step 4:** Run the same command. Expected: PASS, and `text-chapters.test.mjs` passes as updated.

---

### Task 4: The live panel (list, detail, hover, sync)

**Files:**
- Create: `src/components/text/ScenePanel.astro`
- Create: `src/components/text/PanelSign.astro`
- Create: `src/game/textpanels.ts`
- Modify: `src/game/textsite.ts` (call `initPanels`; `showTextAt` calls `selectSpot` first; `textSpot` prefers `currentSpot`)
- Modify: `src/styles/text.css` (`.t-panel` structure only: list, detail, hidden and live states; materials come in Task 5)
- Test: `scripts/check/text-panels.test.mjs`

**Interfaces:**
- Consumes: `.t-target[data-target]` buttons (Task 3).
- Produces:
  - `PanelSign.astro` props `{ place: string; word: string }`: the logo at 4× and the word in Jersey 36, in a double neon border (sign colour, then its dark shade), on ink.
  - `ScenePanel.astro` props:
    - `place: string`
    - `word: string`
    - `material: 'cork' | 'chalk' | 'cabinet' | 'pegboard' | 'case' | 'airmail'`
    - `items: { key: string; label: string; line?: string; group?: string }[]`
    - `split?: boolean` (default `true`; `false` for Tools)
  - What `ScenePanel` renders:
    - `<div class="t-panel" data-panel data-material=…>`
    - the sign
    - a list of `<button class="t-item" data-item="<key>">` (when `split`)
    - one `<div class="t-detail" data-detail="<key>">` per item, from the named slot `<key>` via `await Astro.slots.render(key)`
  - The first item is the default.
  - In `src/game/textpanels.ts`:
    - `export function initPanels(root: HTMLElement): void`
    - `export function selectSpot(spotId: string): boolean`: selects the detail that holds `[data-spot=spotId]` (or is `data-detail=spotId`) in any panel. Returns false if none.
    - `export function currentSpot(section: HTMLElement): string | null`: the first `data-spot` in the shown detail.
- **Behaviour:**
  - **Live state:** `initPanels` sets `data-live` on each panel. Before that, all details are visible in order, so the page works without JavaScript.
  - **Inactive details** get `hidden="until-found"`. On `beforematch`, that detail is selected.
  - **Hover:** delegate `pointerover` on `.t-item` and `.t-target` with `pointerType === 'mouse'` and `matchMedia('(hover: hover) and (pointer: fine)')`. Start a 120ms timer and cancel it on `pointerout` of that element. When it fires, select that item. Leaving changes nothing.
  - **Click and focus:** `click` and `focusin` on `.t-item` and `.t-target` select at once and set `aria-live="polite"` on the detail column for that change. Hover changes set it to `off`.
  - **Selection marks:**
    - the item gets `aria-pressed="true"`
    - the matching `.t-target` gets `data-on`, shown as a 2px press-yellow outline at 2px offset
    - for an unsplit panel (Tools), hovering a target sets `data-on` on the group that holds that spot
  - **Esc** inside a panel, or with a target focused, selects the default item.
  - **Tabs:** a detail can hold `[data-tabs]` with `button[data-tab]` and `[data-tab-panel]`. These follow the same hover, click and focus rules within the detail. Inactive tab panels are also `hidden="until-found"`.
  - **Wipe:** the detail change is a `clip-path` wipe in `steps(6)` over 180ms. None under reduced motion.

- [ ] **Step 1: Write the failing tests** in `text-panels.test.mjs`. Use the arcade panel; hover is dispatched with `new PointerEvent('pointerover', {bubbles:true, pointerType:'mouse'})`.
  - `the first item shows by default and the rest are findable`: `[data-detail="odin"]` is not hidden, and `[data-detail="tako"]` has `hidden === 'until-found'`.
  - `resting on an item shows its detail; leaving keeps it`:
    1. Dispatch over `[data-item="tako"]`.
    2. After 60ms, odin is still shown.
    3. After 200ms total, tako is shown.
    4. Dispatch `pointerout`. After 200ms, tako is still shown.
  - `a cabinet does the same`: dispatch over `.t-target[data-target="algebrawl"]`, wait 200ms, and algebrawl is shown with `data-on` on the target.
  - `click and keyboard focus are instant`: `.focus()` on `[data-item="nova"]` shows nova at once (0ms).
  - `Esc goes back to the first`: with nova shown, focus inside, `page.key('Escape')`, and odin is shown.
  - `find-in-page opens the detail`: dispatch `new Event('beforematch', {bubbles:true})` on `[data-detail="tako"]`, and tako is shown.
  - `arriving from the game shows that thing`:
    - `textAt({place:'arcade', id:'tako'}, {mark:true})`: after 400ms, tako is shown and `[data-spot="tako"]` has `is-here`.
    - `textAt({place:'home', id:'music'})`: the detail holding `music` is shown.
  - `the text page reports the shown thing`: after selecting algebrawl, `textSpot()` (exposed in DEV like `textAt`) returns `{place:'arcade', id:'algebrawl'}`.
  - `without the script, every detail is in the page`: remove `data-live` from the panel and assert every `.t-detail` has non-zero height.
- [ ] **Step 2:** Run `node --test scripts/check/text-panels.test.mjs`. Expected: FAIL.
- [ ] **Step 3:** Implement `PanelSign.astro`, `ScenePanel.astro` and `textpanels.ts`, then wire them into `textsite.ts`. Expose `textSpot` on `window` in DEV next to `textAt`. Use `ScenePanel` for the arcade only, with Task 5's arcade content, so these tests have a subject.
- [ ] **Step 4:** Run `node --test scripts/check/text-panels.test.mjs scripts/check/text-chapters.test.mjs`. Expected: PASS.

---

### Task 5: The six rooms (content and material)

Build one room at a time in this order: arcade, store, home, school, trophy shop, post office. After each room, screenshot it at 1469×887 with the sidebar open and folded (`page.screenshot`). Show Russell the screenshots and wait for his yes before the next room. Arcade and store must match the approved mockup. The other four follow the spec's table, and Russell approves them here.

**Files:**
- Modify: `src/components/text/TextSite.astro`, `src/components/text/PostcardBack.astro`: each chapter's content moves into its `ScenePanel` slots, with every `data-spot` kept on the same content.
- Modify: `src/components/CertificateDialog.astro`, renamed in place to the certificate window (trophy shop).
- Modify: `src/styles/text.css`: one block per material, `.t-panel[data-material="…"]`.
- Test: `scripts/check/text-rooms.test.mjs`
- Modify: `scripts/check/text-back.test.mjs`, `text-final.test.mjs`, `text-review.test.mjs`. Where they assert the old letter card, address column or opener layout, update them to the room-and-panel layout. Keep every assertion about content and spots.

**Interfaces:**
- Consumes: `ScenePanel`, `PanelSign`, `selectSpot` (Task 4), `stages` (Task 3).
- Produces:
  - The certificate window: `[data-cert-category="<folder>"]` buttons open one modal `<dialog data-cert-window>`.
  - The category's in-page grid `[data-cert-grid="<folder>"]` (which holds `data-spot="certs-<folder>"`) is moved into the dialog on open and back on close, as `src/game/world.ts` does.
  - Inside the window, `[data-cert-open]` shows that certificate large, with back, previous and next buttons.
  - Esc and close return focus to the category button.

**Content per room.** The item keys are the existing spot ids where one exists:

| Room | Items (first = default) | Notes |
|---|---|---|
| arcade | `odin`, `tako`, `algebrawl` (group FINISHED); `nova`, `runner` (group NOW BUILDING) | Tabs per project: Overview (tagline, meta, first paragraph), How it works (the remaining paragraphs), Screens (`Gallery`), Stack. The deck has Play it (`.t-btn`, press yellow), Source, and the stack plate (first three of `stack`). "Find it in the arcade" stays. |
| store | (unsplit) four groups, `tools-<slug>` | Pegboard: label-maker tape for group names, tags with the `public/icons` logos (initials where no icon). |
| home | `letter` (holds `poster` and `pc`), `open-to`, `off-the-clock` (holds the five interest spots), `photo` (`mirror`) | Corkboard with the letter on ruled cream paper. The socials lines go in `open-to`. |
| school | `about`, `profile`, `thesis` | Chalkboard: chalk-white headings in Jersey, prose in Plex on dark slate. |
| trophy-shop | `achievements`, `organizations`, then four plaque buttons, one per certificate folder | Display case (navy `#263f6c`, gilt `#dcb55a` / `#b29460` / `#96781e`). The plaques open the certificate window. Hovering a plaque shows "<label> · <count>" in the detail column. The visible frames on the wall (`certs-*` targets) get the same "<label> · <count>" in `stages.labels`, and clicking one opens its window. |
| post-office | `contact` (the form), `socials` | Airmail: chevron border from a pixel SVG tile (red `#ff463c`, blue `#3c6198` on cream `#ffeebe`), ruled-line fields. |

**Copy moves, it doesn't change.** Text from `site.ts` and the project markdown moves as is.

**Copy that is removed or added:**
- "Walk the street any time from the button up top" is removed: the sidebar holds Change UI now.
- The only new copy is the item lines. Each is a short fact from existing data:
  - project lines from `meta` or `tagline`
  - "Thesis, defended 2026"
  - "Offline math RPG"
  - "Fight famous mathematicians"
  - "Voice assistant, Windows"
  - "The minigame on this site"

- [ ] **Step 1: Write the failing tests** in `text-rooms.test.mjs`, at 1469×887, with the sidebar open and then folded:
  - `every panel fits inside its room`: for every stage, `panel.getBoundingClientRect().bottom <= stage.getBoundingClientRect().bottom` and `panel.offsetHeight <= 500`. Select every item, and every tab of every project (NOVA included), checking after each.
  - `every room shows its material and sign`: each `.t-panel` has `data-material` per the table, and `.t-panel .t-sign` text is the sign word.
  - `panel text is readable`: for each detail's paragraphs, `contrast(color, panelBackground) >= 4.5`, using `contrast` from `browser.mjs`.
  - `the visible objects stay uncovered`:
    - Arcade's odin, tako and algebrawl targets don't intersect the arcade panel's rect.
    - The store's `tools-backend-and-data` and `tools-also-comfortable-in` targets don't intersect the store panel.
  - `a certificate category opens its window`:
    1. Click `[data-cert-category="ctfs"]`, and `dialog[data-cert-window][open]` holds `[data-spot="certs-ctfs"]`.
    2. Click its first `[data-cert-open]`, and the large view shows.
    3. Next moves to the second certificate.
    4. Escape closes, focus is back on the category button, and `[data-spot="certs-ctfs"]` is back in `#sec-credentials`.
  - `every spot the game knows is on the page once` (the existing test in `text-chapters.test.mjs`) still passes.
- [ ] **Step 2:** Run `node --test scripts/check/text-rooms.test.mjs`. Expected: FAIL.
- [ ] **Step 3:** Build the arcade, run the tests, screenshot and get Russell's yes. Then do the same for the store, home, school, trophy shop and post office, in that order.
- [ ] **Step 4:** Run `npm run check`. Expected: PASS, apart from anything already failing before Task 1.

---

### Task 6: Narrow screens

**Files:**
- Modify: `src/styles/text.css`
- Modify: `src/game/textpanels.ts` (tap → scroll the detail into view below 900px)
- Test: `scripts/check/text-narrow.test.mjs`

**Details:**
- **Below 900px:**
  - The stage keeps the art at 2× and scrolls sideways inside its frame (`overflow-x: auto`), with `scrollLeft` set to the focus on load.
  - The panel moves under the stage (static, full width), list first, then detail.
  - Selecting an item scrolls its detail into view with `block: 'nearest'`, instantly under reduced motion.
- **From 900px to 1180px:** the panel stays over the room, at `min(panelWidth, 100% - 40px)`.

- [ ] **Step 1: Write the failing tests:**
  - `no sideways page scroll`: at 1000×800, 640×900 and 390×844, `document.documentElement.scrollWidth <= innerWidth`.
  - `on a phone the panel sits under its room`: at 390×844, for each section, `panel.top >= stage.bottom - 1`.
  - `on a phone a tap shows the detail`: click `[data-item="tako"]`, and tako is shown and its top is within the viewport.
- [ ] **Step 2:** Run `node --test scripts/check/text-narrow.test.mjs`. Expected: FAIL.
- [ ] **Step 3:** Implement.
- [ ] **Step 4:** Run `npm run check`. Expected: PASS.

---

### Task 7: Record the design

**Files:**
- Modify: `DESIGN.md`
  - Overview and Layout: the sidebar and scene stages.
  - Navigation: the sidebar from 1181px up; the top bar below.
  - Chapter Opener → Scene Stage.
  - Elevation: add the scene-panel exception.
  - Add a component for each panel material.
  - The front matter's components: `sidebar`, `scene-panel`.
- Modify: `.impeccable/surfaces/src-components-text-textsite-astro.md` (direction contract: chapters are rooms with panels; the memorable moment adds hovering the room's objects)
- Modify: `CLAUDE.md` (remove the "Continuing the text-version rebrand" section, as it asks)
- Modify: `docs/superpowers/next-session.md` (mark items 1 and 2 done)

- [ ] **Step 1:** Make these edits. Every colour named must be one already in DESIGN.md or `art/palette.gpl`.
- [ ] **Step 2:** Run `npm run check`. Expected: PASS. Take final screenshots of all six rooms at 1469×887 and 390×844 and give Russell the paths. He commits.
