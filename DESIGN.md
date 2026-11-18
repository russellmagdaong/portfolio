---
name: RUSSM
description: A portfolio drawn as one street in a made-up Manila at night; the text version is its night-edition postcard.
colors:
  sign-home: "#46e6e1"
  sign-school: "#be6eff"
  sign-arcade: "#ff4f9a"
  sign-store: "#7cf05a"
  sign-trophy-shop: "#ffe24d"
  sign-post-office: "#ff463c"
  press-yellow: "#ffe91f"
  ink-ground: "#0d0b1a"
  night-card: "#171433"
  sky-high: "#221d4a"
  concrete-rule: "#35354c"
  concrete-reading: "#b3b6c9"
  concrete-soft: "#8c8fa8"
  heading-white: "#ffffff"
  plate-steel: "#1a1926"
  plate-line: "#4b4c64"
  plate-edge: "#686a84"
  sodium-label: "#ffcd78"
typography:
  display:
    fontFamily: "Jersey 10, sans-serif"
    fontSize: "64px"
    fontWeight: 400
    lineHeight: 1
  headline:
    fontFamily: "Jersey 10, sans-serif"
    fontSize: "48px"
    fontWeight: 400
    lineHeight: 1
  title:
    fontFamily: "Jersey 10, ui-sans-serif, sans-serif"
    fontSize: "24px"
    fontWeight: 400
    lineHeight: 1
  body-lead:
    fontFamily: "IBM Plex Sans Variable, ui-sans-serif, system-ui, sans-serif"
    fontSize: "19px"
    fontWeight: 400
    lineHeight: 1.6
  body:
    fontFamily: "IBM Plex Sans Variable, ui-sans-serif, system-ui, sans-serif"
    fontSize: "17px"
    fontWeight: 400
    lineHeight: 1.7
  body-small:
    fontFamily: "IBM Plex Sans Variable, ui-sans-serif, system-ui, sans-serif"
    fontSize: "14px"
    fontWeight: 400
    lineHeight: 1.5
  label:
    fontFamily: "Jersey 10, ui-sans-serif, sans-serif"
    fontSize: "20px"
    fontWeight: 400
    lineHeight: 1
rounded:
  none: "0px"
spacing:
  xs: "4px"
  sm: "8px"
  md: "16px"
  lg: "24px"
  xl: "40px"
  xxl: "56px"
  section: "96px"
components:
  button-primary:
    backgroundColor: "{colors.press-yellow}"
    textColor: "{colors.ink-ground}"
    typography: "{typography.label}"
    rounded: "{rounded.none}"
    padding: "0 16px"
    height: "44px"
  button-primary-hover:
    backgroundColor: "{colors.heading-white}"
    textColor: "{colors.ink-ground}"
  button-line:
    backgroundColor: "{colors.night-card}"
    textColor: "{colors.heading-white}"
    typography: "{typography.label}"
    rounded: "{rounded.none}"
    padding: "0 16px"
    height: "44px"
  nav-link:
    textColor: "{colors.concrete-reading}"
    typography: "{typography.label}"
    padding: "0 10px"
    height: "44px"
  nav-link-current:
    textColor: "{colors.heading-white}"
  postmark:
    backgroundColor: "{colors.ink-ground}"
    textColor: "{colors.sign-home}"
    typography: "{typography.label}"
    rounded: "{rounded.none}"
    padding: "6px 10px"
  plate:
    backgroundColor: "{colors.plate-steel}"
    textColor: "{colors.sodium-label}"
    rounded: "{rounded.none}"
    padding: "8px 12px"
  sidebar:
    backgroundColor: "{colors.ink-ground}"
    textColor: "{colors.heading-white}"
    typography: "{typography.label}"
    width: "248px"
  scene-panel:
    rounded: "{rounded.none}"
    padding: "8px"
    width: "500px to 740px"
    height: "at most 500px"
  field:
    backgroundColor: "{colors.ink-ground}"
    textColor: "{colors.heading-white}"
    rounded: "{rounded.none}"
    padding: "10px 12px"
---

# Design System: RUSSM

## Overview

**Creative North Star: "The Night-Edition Postcard"**

The site is a street in a made-up Manila at night, drawn in pixel art, and the web layer is the postcard sent from it. The street itself (hub sky, skyline, six shopfronts) is the front; everything below is the back: a letter on a night card, ruled lines, a stamp and a postmark. All colour comes from the game's own palette (`art/palette.gpl`): ink and night for the grounds, the concrete greys for text and rules, and each place's neon sign colour for that place's markers. The art carries the atmosphere so the reading surface can stay calm.

Every chapter is the place's own room from the game, drawn at 2x and shown whole (a scene stage), with a panel hung over its quiet side: the shop's sign as its header, a short list of what is inside, and one detail at a time. Each panel is made of its room's material (a corkboard at home, a chalkboard at school, an arcade cabinet, a pegboard, a display case, an airmail form), so the content reads as part of the place rather than a card laid over it. A click on an item, or on the thing in the room it stands for, shows its detail (Russell found hover-to-switch hard to steer, 2026-11-18); hover only previews: an arcade cabinet shows a brief of its game, a certificate in the case grows to twice its size. No panel scrolls except the arcade's, whose write-ups are one page each (overview, how it works, screens, stack); a detail too tall for its room is drawn smaller to fit (down to 75%), and past that the room's stage grows. A sidebar of the six shop signs runs down the left on wide screens and folds to a rail of their logos. Motion is stepped, never eased into glow: things wipe in with `steps()` clips, buttons press down a whole lip, a sign lights on hover by swapping to its lit frame.

The world rejects the retro-landing-page kit: full-width colour sheets, numbered eyebrows, offset-shadow cards, fake window chrome, and neon simulated with glows. The neon here is pixels in the art, not CSS effects on the text.

**Key Characteristics:**
- Pixel art from the game owns the frame, at whole-number scales only (2x, 3x).
- Flat ink and night planes, 2px concrete rules, square corners.
- Six sign colours, one per place, used as markers and never as running text.
- Pixel faces for titles and labels; IBM Plex Sans for anything read at length.
- Stepped motion: wipes, presses and frame swaps; nothing glows or blurs.

## Colors

A dark, cool night palette lifted straight from the game's art, with six saturated neon sign colours that each belong to one place, and one yellow that means "press me".

### Primary
- **Place Sign Colours** (`sign-home`, `sign-school`, `sign-arcade`, `sign-store`, `sign-trophy-shop`, `sign-post-office`): Home neon cyan, School neon violet, Arcade neon pink, Store neon green, Trophy Shop neon yellow, Post Office neon red; the palette's neon tube colours. Set `data-sign="<place>"` on a region and everything inside reads it as `--sign`. They mark: the chapter opener's 4px bottom rule, the postmark, the stamp's frame, nav squares and the current-nav underline, fact labels, tool squares, link underlines, focused field rules, certificate hover borders, the "Russell was here" mark.

### Secondary
- **Press Yellow** (`press-yellow`): the one colour for the thing to press: the primary button, the skip link, the focus ring, the mode chooser's seam and its Go buttons, the game's key prompts.

### Neutral
- **Ink Ground** (`ink-ground`): the page itself, the plate behind a chapter title and postmarks, the text on yellow buttons. Palette "ink".
- **Night Card** (`night-card`): the postcard's back, the nav bar, the footer, the street front's paper border, the line button. Palette "night".
- **Sky High** (`sky-high`): the night sky behind chapter strips and round the street front when the frame is wider than the art.
- **Concrete Rule** (`concrete-rule`): every 2px divider, list rule, field underline and the vertical rule between letter and address.
- **Concrete Reading** (`concrete-reading`): running body text.
- **Concrete Soft** (`concrete-soft`): captions, meta lines, closing lines, field labels, the footer.
- **Heading White** (`heading-white`): headings, lead paragraphs, values, strong text, nav on hover.
- **Plate Steel / Plate Line / Plate Edge / Sodium Label** (`plate-steel`, `plate-line`, `plate-edge`, `sodium-label`): the street's steel signage plates, shared by the game HUD, the chooser's title plate and the wordmark plate on the street front; a lighter top edge reads as a lit lip, labels in sodium streetlight.

### Named Rules
**The Own Your Sign Rule.** Each place owns exactly one sign colour, the same in the game and on the page. A chapter, its nav entry, its stamp and its markers all take that place's colour and no other place's.

**The Markers Not Prose Rule.** Sign colours are for markers, rules, stamps and short labels. Running body text is always concrete reading or white on ink or night; a paragraph is never set in a sign colour.

**The Press Me Rule.** Yellow (`press-yellow`) is reserved for what the visitor presses and for focus. A place's own yellow (`sign-trophy-shop`) marks the Trophy Shop and never stands in for an action.

## Typography

**Display Font:** Jersey 10 (stand-in; see below), with sans-serif fallback
**Body Font:** IBM Plex Sans Variable, with ui-sans-serif, system-ui
**Label Font:** Jersey 10, with ui-sans-serif

**Character:** A chunky pixel face for anything painted on a sign or scanned at a glance, set against a plain humanist sans for anything read at length, so the page reads like a letter written on a sign-maker's card.

**Pending approval:** titles and the wordmark are meant to switch `--font-title` to "Russm Sign", the sign lettering drawn in `art/font.aseprite` and built to `src/assets/fonts/russm-sign.woff2` by `npm run font`. It is declared but not yet in use: Russell has not approved it, so the shipped title face is Jersey 10. Once switched, title sizes are restricted to 16, 24, 32, 48 and 64px, the only sizes at which the lettering is crisp; the `Wordmark` component already only accepts those.

### Hierarchy
- **Display** (400, 64px, line-height 1, uppercase): the mode chooser's headings at wide screens (48px below 1280px, 32px on phones).
- **Headline** (400, 48px, line-height 1, uppercase, balanced): the letter's greeting, chapter titles, project names; 32px at 900px and below.
- **Title** (400, 24px, line-height 1): sub-headings inside a chapter ("Awards", "Send a letter"), the P.S. heading, the street front's caption.
- **Body Lead** (400, 19px, 1.6, white): the first paragraph of the letter and of each chapter's prose; project taglines at 600.
- **Body** (400, 17px, 1.7, concrete reading): letter and chapter prose, column capped at 64ch; project write-ups at 16px.
- **Body Small** (400, 14 to 15px, 1.45 to 1.5, concrete soft): meta lines, list details, certificate captions, form status.
- **Label** (400, 20 to 22px, line-height 1): nav links and buttons at 22px; postmarks, fact labels, field labels, footer and stack lines at 20px. Mixed case, no tracking.

### Named Rules
**The One Weight Rule.** The pixel faces have one weight; bold is never synthesized (`font-synthesis-weight: none`). Emphasis in a pixel face comes from colour or size, never weight.

**The Plain Heading Rule.** Headings carry no eyebrow label above them, no section number, and no trailing full stop.

## Layout

A single centred frame capped at 1240px, with a side gutter of `max(16px, 2vw)`. The street front spans the viewport inside a 12px night-card border; below 960px the street keeps its scale and scrolls sideways inside its frame (the page never scrolls sideways), and a plain list of the six destinations appears under it. One art pixel is 2 CSS pixels on a phone (where the street scrolls); wider, the street is zoomed to the smallest whole-number scale that covers the frame (3x from 960px, 4x from 1449px, 5x from 1929px, 6x from 2409px) and its ends are cropped evenly, so it always fills to the sides.

From 1181px the page is a two-column grid: a sticky 248px sidebar (the six places, each led by its shop sign's logo at 2x, with its one-line summary) beside the sections. The sidebar's fold button narrows it to a rail of the logos at 3x and is remembered; a room narrower than the space left sits centred on ink. Below 1181px the sidebar gives way to the fixed top bar. The whole page still scrolls normally: no snapping, pinning or scroll hijacking.

Each chapter is a scene stage exactly 540px tall (the room at 2x), cropped from a set focus when the room is wider than its column. Its panel hangs 20px from the top on the side the room leaves quiet, at most 500px tall and never taller than the room; long content splits into tabs instead. Rooms follow straight on from each other, divided by the stage's 2px rule. From 900 to 1180px the panel stays over the room at the room's width less 40px, and chapter titles step down to 32px. Below 900px the room keeps its 2x art and scrolls sideways inside its frame, opened at its focus, and the panel follows under it at full width, list first.

Spacing steps observed: 4, 8, 16, 24, 40, 56 and 96px. Hit targets are at least 44px tall (panel plaques and tabs at least 32px, with space between).

## Elevation & Depth

The reading surface is flat. Depth comes from tonal planes (ink ground under night card), 2px concrete rules, and the pixel art itself. There are no glows, no blurs, no text shadows and no drop shadows on cards.

### Shadow Vocabulary
- **Key lip** (`box-shadow: 0 4px 0 #000`): a straight 4px lip under a button, like the edge of a key; it collapses to none as the button moves down 4px when pressed.
- **Nav current** (`box-shadow: inset 0 -3px 0 var(--sign)`): the underline under the current chapter's nav link; a marker, not elevation.

### Named Rules
**The Scene Panel Exception.** A panel hung in a room is a made object in that room, so it is drawn with the room's own pixel-art depth: hard inset bevels (light top and left, dark bottom and right), stepped corners in whole art pixels, inset frames. These are drawn edges, never drop shadows, glows or blurs, and they stay inside the panel and its stage.

**The Only Things You Press Rule.** A hard shadow appears only as a straight 4px lip directly under something you press. Never offset sideways, never under a card, panel or image.

**The No Glow Rule.** Neon lives in the art's pixels. No CSS glow, blur, `drop-shadow` halo or text shadow on the reading surface.

## Shapes

Square corners throughout (0px radius): cards, buttons, fields, postmarks, thumbnails. Scene panels step their corners in whole art pixels (a 2px or 4px step clip-path), the only exception. Borders are 2px solid in concrete or in currentColor; place rules are 4px. The stamp is a photo in an 8px sign-coloured frame whose edge is punched by a dotted night-card outline (perforations). Small markers are solid squares (10px nav squares) or the shop signs' own pixel logos (in the sidebar and on each panel's sign), never icon-font glyphs. Pixel art is shown with `image-rendering: pixelated` at whole-number scales only.

## Components

### Buttons
Tactile keys: flat, square, with a lip.
- **Shape:** square corners (0px), 2px border, min-height 44px, 16px side padding, label face at 22px.
- **Primary:** press yellow with ink text and an ink border, 4px black lip.
- **Hover / Focus:** primary turns white on hover (fine pointers only); the line button's border turns white. Focus is a 3px press-yellow outline at 3px offset. Pressed: moves down 4px and the lip goes, in two steps over 90ms.
- **Line:** night card with white text and a concrete-rule border; same lip.
- **Text link:** 16px semibold white with a 2px underline in the place's sign colour, offset 6px.

### Cards / Containers
- **Corner Style:** square (0px).
- **Background:** night card on ink ground.
- **Shadow Strategy:** none (see Elevation).
- **Border:** none on the card; internal 2px concrete rules divide rows from each other. The 404's card takes a 4px top rule in the sign colour.
- **The chooser's text side:** behind its card, copies of the text page's six panels scroll slowly up in one column (70%, tilted -4deg, half opacity, 90s a loop), as if the page were being read; inert, hidden from screen readers, standing still under reduced motion, left out on a phone held upright. Built from the live panels in `src/game/landing.ts`, so it never shows stale content and loads nothing the page has not already.
- **Where they are left:** the 404, the chooser and the footer. Chapter content lives in scene panels (below), not cards.

### Inputs / Fields
- **Style:** ruled lines on a postcard: transparent background, no box, a 2px concrete underline, white text; label in the pixel face at 20px in concrete soft.
- **Focus:** the underline turns the place's sign colour.

### Navigation
- **Style:** a fixed 64px night-card bar with a 2px concrete bottom rule, hidden until the street front has scrolled out of view, then sliding in (240ms). The wordmark sits left; links are 22px pixel labels in concrete reading, each led by a 10px square in its place's sign colour; the current one turns white with a 3px sign-coloured underline. The press-yellow Change UI button ends the row.
- **Mobile:** at 1180px and below, a menu button opens a night-card dropdown with a 2px concrete border.
- **Sidebar (1181px and up):** replaces the bar. Ink, sticky, 248px: the wordmark on a plate, then the six places, each its sign logo at 2x, its sign word in the label face and a one-line summary in concrete soft; the current one carries a 4px stripe in its sign colour. At its foot, "Let's talk", Change UI and the "« Hide" button (a rail of the logos at 3x when hidden, remembered per visitor). With the sidebar showing, the footer drops its own Change UI and keeps to the second column.

### Scene Stage
The place's own room from the game at 2x (`src/components/text/SceneStage.astro`, plans in `src/data/stages.ts`): its layers, its objects, and one moving layer kept running (lights, or rain at school). The things in the room that stand for something in the panel are buttons: clicking one shows its detail, and it takes a 2px press-yellow outline at 2px offset (the home room's hobby props, moved out from under the panel on wide screens, all light up with Off the clock). Boards that only decorate are not buttons: the PC repair shop's screens show their group's logos on light tiles, and the trophy shop's frames each hold a real certificate from their folder. A pixel arrow points at the arcade's cabinets, its plate saying "Click" to a mouse and "Tap" to a touch screen. The panel's sign is the chapter's name. A title shows on an ink plate (36px, drawn per line so a wrapped title hugs its words) on the side away from the panel only when it is a sentence of its own ("Things I've built", "Tools I reach for", Contact's invitation); a title that would repeat the sign ("About me", "Awards and certificates") is kept for screen readers only. A room whose panel hangs on the left is cropped on the panel's side, so nothing is cut in half at the open edge. On a phone each room is a 368px strip (everything that can be pointed at stays above the cut).

### Scene Panels
Hung over a room (`src/components/text/ScenePanel.astro`, `src/game/textpanels.ts`): the shop's sign as its header (the logo at 4x and the sign word in the title face, sign colour on ink, inside the sign's double neon border), a list of items, and one detail at a time beside it, wiping in with `steps(6)`. Inactive details and tabs are hidden "until found", so find-in-page still opens them; without JavaScript every detail shows in order under the room. Each room draws it in its own material, from the palette only:
- **Corkboard (home):** wood frame (wood 3, lit wood 4, dark wood 2) around speckled cork; items are kraft index tabs, the shown one pulled out in cream with a cyan edge; the detail is ruled cream paper (a line every 28px, a neon-red margin) under a cyan pushpin.
- **Chalkboard (school):** dark green slate (leaf 2) in a wood frame with a chalk ledge; items chalked in concrete, the shown one in yellow chalk with a dashed underline; headings in chalk white, prose in pale steel.
- **Arcade cabinet (projects):** a violet cabinet with a row of square bulbs, a black CRT screen with stepped corners and a game-select list (a yellow cursor), and a control deck with the joystick logo, Play it and Source as arcade buttons, and a stack plate.
- **Pegboard (tools):** a steel frame around a plaster board with drilled holes; group names on black label-maker tape (green when its screen in the room is pointed at); each tool a cream tag hung from a peg. No list: all four groups show at once.
- **Display case (credentials):** navy velvet (`#263f6c`) in a gilt frame (`#dcb55a`, `#b29460`, `#96781e`); items are brass plaques with screws, the shown one polished. The four certificate plaques, and the frames on the shop's wall, open the certificate window (the same case, opened), which borrows the folder's grid and shows one certificate large with All, Prev and Next.
- **Airmail form (contact):** cream paper inside a red and blue chevron border (a 12-art-pixel tile, never a gradient), a stamp in the corner; the fields are ruled lines with labels in dim neon red.

### Postmark
The place's name or a date in a 2px currentColor box, 20px pixel label in the sign colour on ink. Used beside chapter titles, under the stamp, on the 404 and as the transient "Russell was here" mark.

### Steel Plate
Street signage shared with the game: plate steel fill, 2px plate-line border with a lighter plate-edge top, sodium label text. Carries the wordmark over the street art, the chooser's title and the game HUD.

### Game Panels (game art direction)
Inside the game (`html.game`), panels and popups are drawn from `--ui-*` custom properties in `src/styles/game.css`. The defaults (home, the street) are an ink body, a concrete-2 title bar, a plate-line border, a sodium title in the title face at 24px, and a press-yellow accent; the panel sits on a black ring with a 6px drop, like a sign board hung in the scene. Each scene (school, store, arcade, trophy shop, post office) restyles its panels in place as part of that scene's art (wood frames, shelf trim, cabinet bezels, airmail borders). These belong to the game's art direction, not to the reading surface: the Elevation rules above govern the text version, chooser and 404, and the scene themes are recorded here as they ship rather than redesigned.

### Open Directions
Not defects, unclaimed room within this world: postmarks are plain sign-coloured boxes and could become drawn cancellations; the panels' pins, screws and stamp are CSS pixels and could become drawn sprites; the sign word stays in Jersey 10 until `art/font.aseprite` is approved.

## Do's and Don'ts

### Do:
- **Do** give every place region `data-sign="<place>"` and draw its markers from `--sign`: home #46e6e1, school #be6eff, arcade #ff4f9a, store #7cf05a, trophy-shop #ffe24d, post-office #ff463c.
- **Do** set running text in concrete reading (#b3b6c9) or white on ink (#0d0b1a) or night (#171433), at 16 to 19px IBM Plex Sans with line-height 1.6 to 1.7.
- **Do** make "press me" press yellow (#ffe91f) with ink text and a straight 4px black lip.
- **Do** show pixel art at whole-number scales only (2x, 3x), `image-rendering: pixelated`, and let a wide street scroll inside its frame rather than scaling it to fit.
- **Do** animate in steps: clip wipes with `steps(6)`, button presses with `steps(2)`, frame swaps with `steps(1)`; honour reduced motion by removing them.
- **Do** keep title-face sizes to 16, 24, 32, 48 and 64px, ready for the sign lettering.

### Don't:
- **Don't** set body text or paragraphs in a sign colour.
- **Don't** use glows, blurs, drop-shadow halos or text shadows on the reading surface.
- **Don't** put a hard shadow under anything you don't press, or offset one sideways.
- **Don't** put an eyebrow label above a heading, number sections, or end a heading with a full stop.
- **Don't** scale pixel art by fractional amounts or smooth it.
- **Don't** round corners.
- **Don't** reach for full-width colour sheets, fake window chrome or offset-shadow cards.
