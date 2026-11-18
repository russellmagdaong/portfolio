# Rebrand: one place, drawn from the street

Date: 2026-11-17. Product facts are in `PRODUCT.md`; the text page's direction contract is in
`.impeccable/surfaces/src-components-text-textsite-astro.md`.

## Intent

Russell asked for the site to stop looking AI-made. An audit on 2026-11-17 found the pixel game's art is
not the problem: the street, the rooms and the shop signs are clearly authored. What reads as generic is
the web layer laid over it: the whole text version, the mode chooser and the game's HUD, built from a
stock "neo-brutalist retro landing page" kit (numbered eyebrows on everything, full-width colour sheets,
3px borders with 6px offset shadows on every box, fake window bars with traffic lights, a blinking LIVE
badge, dot grids, a rainbow of card colours picked by position, Press Start 2P headings at off-grid sizes,
roll-up hover labels, highlighter marks).

The fix is to make the game art the single source of the brand and derive every web surface from it, so
the text version and the game feel like one place.

Who it is for (Russell, 2026-11-17): internship recruiters, who mostly pick the text version and skim,
and game studios and developers, who play. Equal weight.

## Goals

- Every visual on the site is drawn or derived from the game's own art: its palette (`art/palette.gpl`),
  its sign colours, its shopfront sprites, its sky and skyline, and a new pixel lettering in the style of
  its shop signs.
- The text version is a calm, fast reading page for the recruiter in a rush, laid out as one big postcard
  (chosen on the decision page, 2026-11-17): the street is the front, the page below is the back.
- Same names and same colour for each place in both versions.
- The school's exterior on the street is redrawn (Russell, 2026-11-17).

## Non-goals

- No change to the game's scenes, rooms, controls, physics, or how content is shown inside rooms.
- No change to content (`src/data/site.ts`, `src/content/projects/`) beyond the copy edits listed below.
- No new features. Location sync, warp, the chooser's keys, the certificate dialog, galleries and the
  contact form keep working as they do.

## Anti-goals (a failure even if it works)

- Any of the audited tells coming back under another name: numbering things that have no order,
  decorative status lights or badges, boxes with offset shadows that are not buttons, colour picked by
  index, background dot grids or corner marks as filler, fake OS window chrome, headings ending in a full
  stop as a house style, copy that narrates the game's metaphor to a reader who can't see it.
- A look someone could guess from "retro pixel portfolio" alone.
- Scroll snapping, pinned sections or hijacked scrolling (Russell rejected these in October 2026).
- Losing Ctrl+F, text selection or screen-reader access to headings because they became images.

## Constraints

- Astro 7, Tailwind 4 already in place; CSS in `src/styles/*.css`.
- Art is edited in Aseprite (`C:\aseprite\build\bin\aseprite.exe`, not on PATH) and exported with
  `npm run art`; Russell hand-edits scenes, and draw scripts are never re-run on existing art unasked.
- The text page's `data-place` / `data-spot` attributes must keep matching the scene slices, or switching
  versions loses the visitor's place (`src/game/spot.ts`, `src/game/textsite.ts`).
- Existing animations Russell likes are kept unless listed below as removed with the element they belonged
  to.
- Reduced motion respected; the text page works without JavaScript.

## Approaches considered (text page layout)

Two hands were dealt on the decision page.

1. First hand: postcards (each section a postcard), the one-minute sheet first, the street as the
   contents. Russell asked instead for "a mix of both the post card and the street".
2. Second hand, all mixes: postcards hung in the shop windows (the street as contents with a summary card
   under each shop), a postcard rack (six postcard cards in a grid), and **one big postcard, front and
   back**. Russell chose **front and back**. Its stated risk: the postcard idea happens once, at the top,
   so the chapters below need their own way to stay on theme (answered under "Chapters" below).

## The system

### Colour

From `art/palette.gpl`. Each place owns its sign colour, everywhere:

| Place | Sign colour (fill, rule, stamp, and coloured text) |
|---|---|
| Home (Russell's room) | neon cyan `#46e6e1` |
| About (School) | neon violet `#be6eff` |
| Projects (Arcade) | neon pink `#ff4f9a` |
| Tools (PC repair shop) | neon green `#7cf05a` |
| Credentials (Trophy shop) | neon yellow `#ffe24d` |
| Contact (Post office) | neon red `#ff463c` |

**Dark theme (Russell, 2026-11-17, after approval):** the text style is dark, a night-edition postcard.
Ground `ink #0d0b1a` (the page), card `night #171433` (the postcard back, the chooser's mini card), rules
`concrete 3 #35354c`, body text `concrete 7 #b3b6c9`, headings white, soft text `concrete 6 #8c8fa8`. All
from the palette. On these grounds the sign colours themselves are readable as coloured text (each 4.5:1 or
better on the card), so there are no separate dark inks. No glows, blurs or text shadows anywhere: near-black
with glowing neon is the AI default this design must not fall into; the street art, the sign colours' jobs
and the lettering are what carry it. "Press me" stays sodium/neon yellow, as now.

### Type

- **Titles and wordmark:** a new pixel lettering drawn by Claude in the style of the shop signs. See
  "Lettering" below.
- **Labels** (nav, buttons, small captions, postmarks): Jersey 10, as now.
- **Reading:** IBM Plex Sans, about 17px, measure 60 to 75 characters.
- **Removed from the text page and chooser:** Press Start 2P and IBM Plex Mono. (They stay loaded only
  where the game still uses them; the builder removes a `@fontsource` import if nothing uses it anymore.)

### Shadows and boxes

Hard offset shadows only on buttons, so a shadow means "you can press this". Content sits in the reading
column without boxes; groups are separated by space and thin `concrete 3` rules.

## Piece 1: the lettering

- Starts from the sign lettering that already exists: `art/lettering.aseprite` (drawn by
  `scripts/art/draw/lettering.lua`) holds a 3x5 small and a 5x7 large caps alphabet. The heading font is
  the **5x7 large** alphabet on an 8 px em with a 1 px letter gap, extended in the same style with 0-9 and
  `. , ' ’ : ; - – ! ? & / · ( ) "` (the 3x5 set already has digits and some marks to follow). Caps only,
  like the signs.
- Source of truth: a new `art/font.aseprite` (one glyph per cell, on the palette), seeded from the 5x7
  letters of `art/lettering.aseprite`, exported by `npm run art` to a sprite sheet plus metrics.
  `art/lettering.aseprite` and its draw script stay untouched.
- Shipped as a **real font file** (WOFF2) built from that export by a script, so headings stay real,
  selectable, findable text. Used only at sizes that are whole multiples of its 8 px em (16, 24, 32, 48,
  64 px), so each art pixel is a whole number of screen pixels. (Claude's call: a font file over CSS
  sprites, to keep Ctrl+F and screen readers working. The builder picks the generator; a small dev
  dependency such as a font-writing library is acceptable.)
- Russell approves the alphabet (an exported sheet at 4x) before anything uses it.
- Wordmark: RUSSM in this lettering. Whether it gets a 7x7 icon over it, like the shop signs, is shown to
  Russell with the alphabet.

## Piece 2: the text version (the postcard)

Same file trio (`TextSite.astro`, `text.css`, `textsite.ts`), same section ids, `data-place`, `data-spot`,
`data-goto`, `data-play` and `data-change-ui` hooks.

**The front (top of the page).** The street at night, framed by a card-coloured (`night`) border like a postcard: hub sky,
far skyline, the sidewalk, and the six shopfront sprites (`src/assets/hub-objects/*`) at 3x on desktop
(real street or flat row: open question below). Each shopfront is a link to its chapter; pointing at or focusing one shows its hover tag
(the lit sign), as the current "Pick a door" cards do. Russell's sprite stands idle on the sidewalk outside
the place the visitor last was in the game (Home by default). The wordmark sits top left inside the frame,
Change UI top right. Under the frame, in lettering: GREETINGS FROM A MADE-UP MANILA. On a phone the street
is wider than the screen: it scrolls sideways inside its frame at 2x (the page itself never scrolls
sideways), and the six places are also listed as plain links under the frame.

**The back (the letter).** A card (`night`) split by a vertical rule. Left: "Hi, I'm Russell Magdaong" in
lettering, then a short letter in Plex Sans built from `site.description` and the first About paragraph
(4th-year CS at FEU Tech, DOST-SEI scholar, games that teach, ODIN defended, building NOVA), and one line
offering the game ("Walk the street any time from the button up top"). Right: a stamp (Russell's sprite
head in a perforated frame, cyan), a postmark line ("Manila · November 2026", from data, not hard-coded in
markup), then address-style lines: Open to (internships), Email, GitHub, Facebook, and Résumé when
`site.resumeUrl` is set.

**Navigation.** Once the front scrolls away, a slim sticky bar: wordmark, the six places as links each with
its sign-colour square, Change UI. The current place is marked (`aria-current`). No scroll meter.

**Chapters** (About, Projects, Tools, Credentials, Contact; order is an open question below). Each opens with a strip of its
own postcard front: a narrow band of night sky with that shop's sprite, the place's title in lettering, and
a postmark-style label with the place's game name ("SCHOOL", "ARCADE"). The strip's bottom rule is the
sign colour. Below it, a calm reading column on the dark ground. This is how the theme carries below the letter
without boxing the content.

- **About:** the About paragraphs, then the profile facts as a plain two-column definition list, then the
  thesis link to ODIN as a line, not a banner.
- **Off the clock** (music, gaming, video, CTFs, hackathons, with the CTF and hackathon results) becomes a
  short "P.S." list at the end of the letter, not five rainbow cards. (Changed while planning: these are
  props in Russell's room, so they must stay in the Home section for game-to-text switching to land on
  them.)
- **Projects:** each project is an entry, not a window: title in lettering, meta line, tagline, gallery
  (`Gallery.astro`) beside the text on desktop (alternating sides as now), prose, stack as a plain line,
  then Play / Source buttons and "Find it in the arcade". "Now building" is a text label with a pink square.
  The Runner minigame becomes a single line with its "Play it in the arcade" button.
- **Tools:** the four groups as plain columns of icon plus name.
- **Credentials:** awards as a list (title, where, year); organisations as a list; certificates as a
  thumbnail grid opening `CertificateDialog.astro`, as now.
- **Contact:** the form (`ContactForm.astro`) set like writing on the back of a postcard (ruled lines), next
  to the address lines. The "Testimonials: coming soon" postcard is removed until real testimonials exist
  (Claude's call; Russell can keep it).

**Footer.** Wordmark, the postmark line, Change UI.

**Kept behaviour.** Location sync both ways; the "Russell was here" mark stays, restyled as a postmark stamp
in the place's colour instead of an acid tag; section reveal on scroll stays as the stepped wipe (calm, one
grammar); reduced motion turns it off.

**Removed with their elements:** numbered eyebrows and pixel ornaments, X corner marks, dot-grid sheets,
fake window bars and lights, LIVE badge, "Field note", the tilted hero window and its terminal typer, the
letter-drop solid/outline headline with caret, "SAY://HI", outline card numbers, roll-up nav hover, the
XP-bar scroll meter, offset shadows on non-buttons.

**Copy.** Headings drop the trailing full stop. Remove lines that explain the game's metaphor ("Each of
these is a cabinet in the arcade", "grouped the way the shop shelves them", "The things lying around my
room..."). Factual copy is unchanged.

## Piece 3: the mode chooser

Keep its behaviour (`src/game/landing.ts`: first visit, Change UI, arrow keys, Enter, lean, the slanted
seam and the sweep on choosing). Restyle:

- Title "Choose your mode" and the side headings in the lettering; wordmark in the lettering.
- Text side: instead of grey placeholder bars, the postcard back itself (card, stamp, postmark, the
  first lines of the letter), so it previews what that choice gives.
- Game side: the live street canvas, which must draw on desktop too (it rendered empty in a 1469x887
  capture on 2026-11-17; the builder finds out why).
- Removed: highlighter marks, tag chips ("One page", "Quick skim", "Secrets inside"...), the OR badge, the
  grey dimming that makes the unleaned side look disabled (lean is shown by emphasis on the leaned side
  instead).
- Copy: "In a rush?" / "Got time to play?" stay; the button labels stay.

## Piece 4: the game HUD

Restyle only; no behaviour change. HUD buttons, the place name, the Here / Go to lists, prompts, the exit
tag and the tooltips move from navy boxes with violet borders to the street's own materials: a dark steel
plate from the concrete ramp with a lighter top edge (like the street's signage plates), labels in Jersey
10 in a warm sodium tone, the place name in the lettering. The yellow "press me" key caps stay. Panels
(`.gpanel`) follow the same plate style; per-scene panel themes in `game.css` stay as they are.

## Piece 5: the school's exterior

`art/hub-objects/school.aseprite` (idle and hover tags, `base` slice) is redrawn. Fixed by the hub: the
`building:school` slice is 67x59 at (301, 82) on the upper landing; its door (`door:school` at x 353) stays
44 px tall with 42 clear so Russell fits; the sign keeps saying ABOUT ME with the open-book icon in neon
violet; idle and hover tags keep their meaning (hover lights the sign); palette only. The hub art around it
is not touched.

Must have (Russell): the sign's 7x7 icon reads unmistakably as an **open book** (two pages, a spine, page
lines), at 1x on the street. The rest of the redraw (Claude's call, Russell can correct): the facade reads
as a school rather than a shuttered shop, so the full-width barred grille goes, in favour of a school
front (an entrance with steps or a gate, windows with a classroom glow, a small bell or clock). The
workflow is the usual one: Codex writes a concept (`art/concept/`), Claude draws it in Aseprite, Russell
approves both.

## Also in scope

- `src/pages/404.astro` is restyled with the text version (dark ground, lettering, the street's colours); it
  still uses the old kit. (Claude's call.)
- The shared pieces in `global.css` that game panels still use (`.panel`, `.btn`, `.chip`, `.field`,
  `.keycap`) are restyled with the HUD; old-site styles nothing uses are deleted. (Claude's call.)

## Order of work

Approvals don't stop the line: until Russell approves the alphabet, titles use Jersey 10 at the same
sizes, and the font is swapped in with one change once approved. (Claude's call.)

1. Lettering: Claude draws the extended alphabet; Russell approves it (and the wordmark) whenever ready.
2. School exterior concept, in parallel, since it is independent. Russell approves it, then Claude draws it.
3. HUD (barely depends on the lettering).
4. Text version and 404.
5. Chooser (previews the finished text page's postcard back).

Each piece is checked in headless Edge at 1469x887 and 390x844 before it is called done; the text page
ends with Impeccable's finish review and a DESIGN.md recording the shipped system.

## Left to the builder

- Exact spacing scale, chapter-strip height.
- How the street front is composed in code (CSS layers or a canvas) and the 3x / 2x breakpoints.
- The font generator and the WOFF2 build step.
- Why the chooser's street is blank on desktop, and the fix.
- Removing dead CSS from the old site (`global.css` deck, horizon, holo, entry styles) only if nothing uses it.

## Decided after review (Russell, 2026-11-17)

- **The postcard front is the real street,** not a flat row: the hub's own layers (`src/assets/hub/`:
  sky, far, buildings, street, front, and the skyway, jeepney and rain where they help) with the six
  shopfront sprites placed by their `building:<id>` slices, two levels and stairs as in the game. The
  480x270 hub at 3x (1440 px) on desktop; narrower windows show it at 2x inside the frame, scrolling
  sideways within the frame only. Russell's sprite stands at the `door:<id>` of the place the visitor last
  was (upper landing for Home and School).
- **Chapter order stays as now:** About, Projects, Tools, Credentials, Contact (recruiter priority). The
  front shows the street as it really is; the nav lists places in chapter order. "Same order in both
  versions" is dropped as a goal; same names and colours stay.
- **The school's problem:** its sign icon doesn't look like a book.
