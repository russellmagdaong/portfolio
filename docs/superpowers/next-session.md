# Next session: text version, scene interiors and interactables

Written 2026-11-18 at the end of the rebrand session, for the session that continues it.

## How to work

Use these skills, in this order:

1. `superpowers:brainstorming`: ask Russell for his inspiration images FIRST, then lay out 2-3 approaches with text sketches in chat (no decision page, no browser tab).
2. `impeccable` with `shape`: plan the section-with-scene-background layout and the interactables. Planning only, no code.
3. `superpowers:writing-plans`, then `superpowers:executing-plans`: build the plan inline in that session (not subagent-driven).
4. `impeccable` with `polish`: only if Russell asks for a finish pass.

Keep token use low: read only the files listed below, don't re-explore the codebase, and don't spawn subagents (reviewers included) unless Russell asks.

## Read first, nothing else

- `PRODUCT.md`, `DESIGN.md`
- `docs/superpowers/specs/2026-11-17-rebrand-design.md` (the approved design)
- `.superpowers/sdd/2026-11-17-rebrand/progress.md` (the build ledger: what's done and the rulings)
- `src/components/text/TextSite.astro`, `Chapter.astro`, `PostcardBack.astro`, `src/styles/text.css`

## Where it stands

The text version is built as a dark "postcard":
- The front is the real game street; the back is a letter.
- Then one chapter per place (About, Projects, Tools, Credentials, Contact), each opening with a strip of its shopfront on a night skyline.

Nothing is committed: Russell commits himself, so never commit.

The last two fixes were never re-tested: the nav underline stripe in `text.css` and the EBUSY retry in `scripts/check/browser.mjs`. Run `npm run check` once, against Russell's dev server on :4321, before starting.

## What Russell wants changed

1. **Done (2026-11-18): scene interiors as backgrounds.** Built as scene stages: each chapter is its room at 2x, flat, with no blur (see DESIGN.md, Scene Stage; spec `docs/superpowers/specs/2026-11-18-scene-sections-design.md`; ledger `.superpowers/sdd/2026-11-18-scene-sections/progress.md`).

   The original ask: **Scene interiors as backgrounds.** Each section's background becomes the INTERIOR of that place's game scene, flat (no parallax):
   - home: Russell's room
   - about: the school
   - projects: the arcade
   - tools: the store
   - credentials: the trophy shop
   - contact: the post office

   The still art is in `src/assets/scenes/<scene>/`, with the layers listed in `<scene>.json`. A slight blur is fine if it reads better behind text. `DESIGN.md` currently says "no blurs", so update that rule if you go that way. Text must stay readable (4.5:1).
2. **Done (2026-11-18): interactables.** Built as scene panels in each room's material, with hover-to-show, and a certificate window (see DESIGN.md, Scene Panels).

   The original ask: **Interactables instead of long sections.** Sections take too much space. Use interactables like the game's objects (a cabinet, a shelf, a board) to open the longer parts: project write-ups, certificates, tool lists. Don't show everything at once. Keep every `data-place` / `data-spot` hook, so game<->text sync still works.

Both items are done. What is left is Russell's call: an `impeccable polish` pass if he asks for one, and the open items in DESIGN.md (Open Directions).

## Rules that still hold

- No commits.
- Don't re-run art draw scripts.
- Palette only (`art/palette.gpl`).
- Pixel art at whole-number scales only.
- No scroll hijacking, snapping or pinning.
- The sign font stays a stand-in (Jersey 10) until Russell approves `art/font.aseprite`.
- The school exterior redraw (plan Task 4) is still waiting on a Codex concept.
