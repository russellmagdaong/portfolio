# Text version: scene sections, sidebar and hover panels

Written 2026-11-18 with Russell. Continues `2026-11-17-rebrand-design.md`; the rules in `next-session.md`, `PRODUCT.md` and `DESIGN.md` still hold except where this says otherwise.

## Intent

The text version's chapters are too long and look like a web page with game art stuck on top. Russell wants each section to be the inside of its place in the game, with the longer parts tucked behind the objects in that room, and a sidebar index like Aki Yamin's (akiwip.work). The page stays an ordinary scrolling page.

The look is "static or flat with some animation". References: Pixel Metaverse (art as the page, letter text on the art's quiet areas), Portfolio 2026 #game (one frame used everywhere, things standing on a floor, labelled arrows), Deepy (tab strip, dark fade under the art), Corgi (side-on scene as the site), Aki Yamin (sidebar menu with a one-line description per item).

## Goals

- Each section is its place's interior, flat, as the section's background.
- The longer content opens from the room's own objects, so sections are short.
- A recruiter still gets the facts without playing: every section opens with its summary showing, and details appear on hover, not behind chains of clicks ("too many clicks = bad portfolio").
- A sidebar index with one-liners, which can fold into a slim rail.

## Non-goals

- No parallax, no scroll-triggered entrances, no new looping effects beyond the art's own.
- No change to the street front (top of the page), the game, or the art files' drawings.
- No new content: write-ups, certificates and tools come from `site.ts` and `src/content/projects/` as they are. The only new copy is the six sidebar one-liners.

## Anti-goals (a failure even if it works)

- Scroll hijacking, snapping, pinning, or sections that swap in place (rejected Oct 2026).
- Facts hidden so that a visitor must click around the scene to find them.
- Glow, blur, gradients, grunge texture, rounded CSS corners, pixel fonts for body text.
- Panels that flicker or jump as the cursor crosses the scene.

## Approaches considered

| Question | Options | Picked |
|---|---|---|
| Sidebar | A: full Aki sidebar, always open (scenes cropped). B: slim rail that opens on hover (scenes whole). | **Both, with a fold button**: open by default, folds to the rail, choice remembered. Chosen over switching by screen width, which would have shown Russell the rail on his own 1469px screen. |
| Where an object's content opens | Over the scene in the game's panel style. Below the scene's floor line (section grows). | **Over the scene**: the scene really is the background; write-ups are 150 to 300 words, so they fit with tabs. |
| What shows before any interaction | Summary panel already open. Bare scene with arrows only. | **Summary open** (Russell: "your pick"), so recruiters never have to play for facts. |
| How details open | Click. Accordion that expands on hover. **List and detail side by side, detail fills on hover.** | Russell asked for hover. Side by side is my call: an accordion moves the items under the cursor, and replacing the whole panel would hide the list. |

## The design

### Page structure (top to bottom)

1. **Street front**: unchanged (`PostcardFront`), full width.
2. **Sidebar plus sections**: once the street front has scrolled out of view, the sidebar is in place at the left, and the six sections run down the right: Home (room), About (school), Projects (arcade), Tools (store), Credentials (trophy shop), Contact (post office). Reading order stays About, Projects, Tools, Credentials, Contact after Home.
3. Footer: unchanged.

### Sidebar

- **Open** (default): about 248px wide, night card with a 2px concrete rule on its right edge. The wordmark plate sits at the top. Six entries follow, each with:
  - its 10px sign-colour square
  - the name as on the sign: HOME, ABOUT ME, PROJECTS, TOOLS, AWARDS, CONTACT
  - one line in body-small (concrete soft)
- **Current entry**: the section in view fills ink with a 3px sign-colour marker, like Aki's black HOME row.
- **Bottom**: a "Let's talk" block linking to the post office section, plus the press-yellow Change UI button (moved from the nav bar).
- **Folded**: a 64px rail of the six sign squares with the current one marked, and a button to open it again.
  - Folding and opening are a stepped wipe (`steps()`), removed under reduced motion.
  - The choice is kept in `localStorage`, read inside try/catch. Without storage it opens by default.
- **Behaviour**: `position: sticky` beside the sections. It never controls the scroll. Clicking an entry is an ordinary anchor jump.
- **Below about 1180px**: no sidebar. The existing top bar and menu button return.
- **The one-liners**: Claude drafts them from `site.ts`, Russell edits them. Stored in `site.ts`, next to the places.
- **Replaces** the fixed top nav bar on wide screens.

### Scene stage (each section)

- **Art**: the place's interior stills from `src/assets/scenes/<scene>/` (layers stacked by `<scene>.json`), plus the object sprites from `src/assets/objects/<scene>/`, at 2× (whole-number scale, pixelated). Flat: no parallax, no blur.
- **Width**: the interiors are 624 to 758 art pixels wide (1248 to 1516px at 2×), wider than the space beside the sidebar. Each scene gets a hand-picked crop (an `object-position` focus), chosen so that every clickable object stays in view with the sidebar open. Folding the sidebar shows more of the scene.
- **Heading**: the chapter title on its ink plate and the place's postmark sit on the scene's ceiling or wall band. This replaces the current chapter opener strip (shopfront on skyline).
- **Motion**: one looping layer from the art per scene, where it has one (`lights` or `rain`). Removed under reduced motion.

### Clickable objects

- **Which objects**: the ones the game already marks, the `object:*` slices in `<scene>.json` (for example `object:odin`, `object:tako`, `object:algebrawl`, `object:nova` in the arcade). Their `data.opens` names the content, which matches the page's existing `data-spot` ids. Hit areas come from those slice rectangles scaled 2×.
- **Element**: each is a real `<button>` over the art, with an accessible name (the content it shows).
- **Hover, focus or selected**: the object shows an outline frame, the same idea as a sign swapping to its lit frame.
- **Arrows**: a static labelled arrow (`art/arrow.aseprite`) points at the clickable objects, Portfolio 2026 style. No bobbing.

### The panel

- **Placement**: one panel per section, placed over the scene's quiet area. The spot is chosen per scene so it doesn't cover the clickable objects.
- **Frame**: drawn in that scene's game panel style (`--ui-*` themes in `src/styles/game.css`: cabinet bezel, wood frame, shelf trim, airmail border).
- **Body**: opaque, so text keeps 4.5:1 contrast.
- **Two parts, side by side**:
  - **List** (left): the section's summary, a list of buttons (projects, tool groups, award groups, and so on), each with its one-line fact. Always visible.
  - **Detail** (right): starts on the section's intro (About's prose, the letter on Home, the thesis line on Projects, and so on). It shows the detail of whatever the visitor last pointed at.
- **Hover rule**:
  - Resting the pointer on a list item or a scene object for about 120ms shows its detail.
  - Moving away does not revert it. The last one stays until another is chosen, so the detail doesn't flicker while the cursor travels into the panel.
  - Hover only works on fine pointers. Tap, click, Enter and keyboard focus show it at once.
  - Changes caused by hover are not announced to screen readers. Focus and click changes are.
- **Long details**: a Deepy-style tab strip inside the detail (▶ Overview //Screens //Stack for a project). Each tab is short.
- **Certificates** (Russell, 2026-11-18): the certificates are not shown in the panel.
  - Each certificate category (one per folder in `src/assets/certificates/`) has a button in the trophy shop panel. Hovering it shows the category's text summary in the detail.
  - Clicking the button opens a window (a modal `<dialog>`, framed in the trophy shop's panel style) showing that category's certificates as a grid with captions.
  - Clicking a certificate inside the window shows it large in the same window, with back, previous and next. This is my call: no second dialog stacked on top.
  - Esc or the close button closes the window and returns focus to the category button.
  - The existing `CertificateDialog` is reused or reshaped for this.
  - Without JavaScript, the grids render in order under the panel.
- **Change animation**: a stepped wipe on the detail area (`steps(6)`). None under reduced motion.
- **Closing**: Esc returns the detail to the section's intro. There is nothing to close: the panel itself always stays.

### Small screens

Below about 900px:
- The scene sits as a strip at whole-number scale. It scrolls sideways inside its frame, like the street front does today, with the crop focus on the objects.
- The panel sits under the scene instead of over it: list first, then detail.
- Tapping a list item or object fills in the detail and scrolls it into view.

### Without JavaScript

- Every detail block renders in order under its list, so the page is complete and readable.
- The scene objects are plain anchors to those blocks.
- The sidebar is open, with no fold button.

### Game and text sync

- **Hooks kept**: every `data-place` and `data-spot` stays, on the section and on each detail block.
- **Arriving from the game at a spot** (`src/game/spot.ts`): the page scrolls to that section and shows that spot's detail in the panel.
- **Reading position**: the panel's current detail counts as "where the visitor is" when switching back to the game.

### Rules that change in DESIGN.md

- **Navigation**: the sidebar replaces the fixed top bar on wide screens.
- **Chapter opener**: replaced by the scene stage.
- **Elevation**: the game panels' black ring and 6px drop are now also allowed on the text version, for these scene panels only. They are signs hung in the room, not cards.
- **No blur**: unchanged. The scenes are not blurred, and readability comes from the opaque panel.

## Shape outcome (approved by Russell, 2026-11-18, from the mockups)

The reference mockups (arcade and store) are in that session's scratchpad: `mock/gen2.mjs` builds them. Russell approved them after these corrections.

### Settled by the mockups

- **Sidebar markers are the shop sign logos**, cut from the hub shopfronts (`art/hub-objects/<place>.aseprite`, frame 0, the icon above the sign word): house, book, joystick, monitor, trophy, envelope.
  - Shown at 2× in the open sidebar and 3× in the folded rail.
  - They are exported as real sprites by the art pipeline, not cropped at runtime. See the plan.
- **A panel never makes the room taller.** The stage is exactly the art's height (540px at 2×), and the panel fits inside it (top 20px, at most about 500px tall). Long content splits into more tabs; ODIN's Overview, for example, becomes Overview and How it works. No floor is extended or repeated.
- **Folded sidebar**: a room narrower than the stage sits centred on ink.
- **Every panel wears its shop's sign as its header**: the logo at 4× and the sign word in Jersey 36 in the sign colour, on ink, with the sign's double neon border (sign colour, then its dark shade).
- **Panels are drawn from each room's own material**, with stepped corners in whole art pixels (2px steps), hard bevels (light top/left, dark bottom/right), no smooth gradients, and no glow. Colours come from `art/palette.gpl` only.
- **Hovered objects** get a 2px press-yellow outline at 2px offset.
- **Blank wall boards** left visible get a pixel-face label (for example "BACKEND AND DATA · 5").
- **Tools has no list-and-detail split.** All four groups show at once, and hovering a screen in the store highlights its group.

### The six panels

| Room | Panel position (sidebar open) | Material | Contents |
|---|---|---|---|
| Home (room) | right, over the PC and shelves | the room's corkboard: cork with whole-pixel speckle, the letter on ruled cream paper held by cyan pushpins, list items as index tabs | Letter (shown first), Open to, the hobby props, Photo (mirror) |
| About (school) | left, over the chalkboard and whiteboard | the chalkboard: dark green slate in a wood frame with a chalk ledge; headings in chalk-white pixel face, prose in Plex | About me (shown first), Profile facts, Thesis |
| Projects (arcade) | right, over the claw, prize shelf and NOW BUILDING | **as mocked**: a cabinet with sign marquee and square bulbs, a stepped CRT screen with a game-select list (▶ cursor), and a control deck with the joystick logo, PLAY IT and SOURCE arcade buttons, and a stack plate | ODIN, TAKO, Algebrawl, NOVA, Runner; tabs Overview / How it works / Screens / Stack as content needs |
| Tools (store) | left, over the CRT and browser | **as mocked**: the pegboard, groups on label-maker tape, tools as hanging tags with their logos | four groups |
| Credentials (trophy shop) | left, over the awards board (narrower panel) | a display case: navy (`#263f6c`) in a gilt frame (`#dcb55a`, `#b29460`, `#96781e`), group names on brass plaques | Awards (shown first), Organizations, four category plaques that open the certificate window (museum frame, cream mat) |
| Contact (post office) | left, over the socials board and counter | an airmail form: cream paper with a red and blue chevron border (a pixel tile, not a diagonal gradient), ruled-line fields, a stamp corner | the form (shown first), socials and contact lines |

Home, About, Credentials and Contact were not mocked. They are built to this table and shown to Russell room by room for approval.

## Constraints (unchanged)

- No commits (Russell commits).
- Don't re-run the art draw scripts.
- Palette only.
- Whole-number pixel scales.
- No scroll hijacking.
- Jersey 10 stays as the title face until `art/font.aseprite` is approved.
- IBM Plex Sans for anything read at length.
- Keep the existing animations Russell likes.

## Left to the builder (the `impeccable shape` step)

- The crop focus and panel position for each of the six scenes, checked at 1469px with the sidebar open and folded.
- Which list items each section's panel holds, and which detail each scene object shows, where the game has no object for it (for example, tool groups in the store).
- The outline-frame style for hovered objects (CSS outline in the sign colour, or a drawn frame).
- The exact sidebar width, between about 232 and 264px, chosen so the crops work.
