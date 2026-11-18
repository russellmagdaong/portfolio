# Product

<!-- impeccable:product-schema 1 -->

## Platform

web

## Users

Two visitors, weighted equally (Russell, 2026-11-17):

- **Internship recruiters and screeners** for software engineering and game dev internships. They are in a rush, skim, want projects, stack and proof, and may never play. They mostly pick the text version.
- **Game studios and developers**, who judge the game itself as the proof: craft, feel and art. They pick the game version.

Each mode is built for its own visitor; neither is a fallback for the other.

## Product Purpose

The personal portfolio of Russell Magdaong, a 4th-year BS Computer Science (Software Engineering) student at FEU Tech and DOST-SEI scholar in the Philippines. It exists to land a software engineering or game dev internship. Success: a recruiter understands what he builds in under a minute, and a game person wants to keep walking around.

## Positioning

He builds games that teach (ODIN, TAKO, Algebrawl) with Godot on the front and plain, deterministic code behind it. The portfolio proves this by being one: a hand-drawn 2D pixel game of a made-up Manila street at night, where every building holds a part of the portfolio, with a sprite of Russell you walk around.

## Operating Context

- First page of a visit asks: text mode or game mode. Either can be switched to at any time, and switching keeps the visitor's place.
- Text mode is one long page. Game mode is a side-on street (the hub) with six places: Russell's room (home), School (about), Arcade (projects), PC repair shop (tools), Trophy shop (credentials), Post office (contact).
- Keys, mouse and touch all work in the game; phones get the game too.

## Capabilities and Constraints

- Astro site; content comes from `src/data/site.ts` and `src/content/projects/`.
- Art source of truth is Aseprite (`art/*.aseprite`), drawn on one shared palette (`art/palette.gpl`) and exported by `npm run art`. Russell hand-edits scenes; draw scripts are never re-run unasked.
- No scroll snapping, pinned sections or hijacked scrolling, anywhere.
- Existing animations Russell likes are kept unless he says otherwise.

## Brand Commitments

- The name on the site is **russm** (short) / **Russell Magdaong** (full).
- The shop signs say what each place serves, not invented names: HOME, ABOUT ME, PROJECTS, TOOLS, AWARDS, CONTACT.
- The setting is an original, made-up Manila at night (cyberpunk street). Scott Pilgrim's game is a reference for point of view and density only; nothing is copied from it.
- Must not read as AI-made or "vibe coded" (Russell's own words, Oct 2026). He rejected gradient borders, scrolling tickers, glows-on-everything and generic neon cyberpunk.
- Text mode should feel like a calm dossier for the skimmer, borrowing the street's art and sign colours, not the loud neon (2026-11-17). Its theme is dark (Russell, 2026-11-17).
- Titles and wordmark move to a pixel lettering drawn in the style of the shop signs (Claude draws it in Aseprite, Russell approves it).

## Evidence on Hand

- Projects: ODIN (undergraduate thesis, defended 2026, team of four), TAKO, Algebrawl, NOVA (now building), the Runner minigame. Galleries in `src/assets/projects/`.
- Awards, certificates, CTF and hackathon results, organizations: `src/data/site.ts`, images in `src/assets/certificates/`.
- A real photo (`src/assets/pics/updated pic.png`) and the pixel sprite of Russell (`art/russell.aseprite`).
- No testimonials yet ("still in the post"); none may be invented. No résumé PDF yet.

## Product Principles

1. The game is the proof: anything the site claims about making games, the site itself should demonstrate.
2. A recruiter in a rush is never made to play to get the facts.
3. Both modes are one place: same names and same colours for the same places. The text version's front is the real street; its chapters follow reading priority (About, Projects, Tools, Credentials, Contact).
4. Everything visual is drawn or derived from the game's own art, not from a web style kit.
5. Honest content only: no filler stats, fake status lights or invented proof.

## Accessibility & Inclusion

The text version is the fully accessible path (keyboard, screen reader, no JavaScript); the game describes its controls and points to it. Reduced motion is respected in both.
