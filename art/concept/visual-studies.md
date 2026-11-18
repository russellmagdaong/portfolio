# Cyberpunk Manila — visual concept set

2026-11-16 · Codex · Built-in imagegen

Russell approved the Home study's **visual direction**, then requested concept images for every scene and the map together. This expands the image exploration beyond the original one-at-a-time order. Images here establish mood, density, materials and lighting. They are not final Aseprite art or exact slice-aligned block-outs. Review the complete set before translating it into Claude's detailed drawing handoffs. No Aseprite, palette, application or export files were changed.

## Images and prompts

Paths are relative to this document. All generated studies and generation prompts remain in the permitted working directory.

| Place | Visual concept | Exact generation prompt | Direction |
|---|---|---|---|
| Home | [Home study](../_work/concept/home-study-v1.png) | [Prompt](../_work/concept/home-study-v1-prompt.txt) | Warm capiz, a personal maker's room, cyan electronics and rainy blue-teal city; visual direction approved |
| Arcade | [Moth Byte](../_work/concept/scenes-arcade-study-v1.png) | [Prompt](../_work/concept/scenes-arcade-study-v1-prompt.txt) | Pink sign; five project cabinets; repair bench, vending machine and spare parts |
| School | [Rainlamp Campus](../_work/concept/scenes-school-study-v1.png) | [Prompt](../_work/concept/scenes-school-study-v1-prompt.txt) | Covered campus corridor, violet accent, breeze blocks and rain-soaked courtyard |
| Sari-sari store | [Leafwire Goods](../_work/concept/scenes-store-study-v1.png) | [Prompt](../_work/concept/scenes-store-study-v1-prompt.txt) | Green sign, snack strips, jars, card reader, rolled grille and patched awning |
| Trophy shop | [Brass Kite — corrected](../_work/concept/scenes-trophy-shop-study-v2.png) | [Initial prompt](../_work/concept/scenes-trophy-shop-study-v1-prompt.txt), [motif correction](../_work/concept/scenes-trophy-shop-study-v2-prompt.txt) | Violet sign, varied brass trophies, framing workshop, blank credential frames |
| Post office | [Moonrelay Post](../_work/concept/scenes-post-office-study-v1.png) | [Prompt](../_work/concept/scenes-post-office-study-v1-prompt.txt) | Warm writing counter and mail cubbies; cyan letterbox sign; parcels and twine |
| Town map | [Whole neighbourhood](../_work/concept/map-study-v1.png) | [Prompt](../_work/concept/map-study-v1-prompt.txt) | All six buildings, winding lanes, corrugated roofs, wet streets and overhead cables |

## Shared art direction

Warm sodium light falls on repaired wood, old plaster, capiz, plants, corrugated metal and practical objects. Violet shadows tie the interiors together; muted blue-teal fog flattens the city outside. Each interior has one principal neon family. Small uneven lights, conduits, fans, fasteners, packets, shelves and patches supply detail at several scales. Floors are calmer, with wet reflections confined to exterior ground.

The original reference lessons remain fog-separated depth from `skyline-rain.png` and densely interlocking big/medium/small equipment from `market-street.png`. No reference files were supplied to imagegen or copied into these studies.

Blank boards, screens and frames are intentional HTML content surfaces. The store's four empty recesses will receive tool icons/content; the school's boards receive the actual profile and institution information; trophy frames receive the actual credentials. Do not fabricate text, brands, qualifications or logos inside them.

## Exact English lettering

Use the shared 3x5 capitals for small words and 5x7 for main signs when drawn at final game scale. Business names below are invented for the concept. Project names are the supplied portfolio projects. Line breaks are deliberate.

| Image | Exhaustive sign wording (a slash indicates a line break) |
|---|---|
| Home | `ROOM`; `NIGHT / FERN` |
| Arcade | `MOTH BYTE`; `NOVA`; `ODIN`; `TAKO`; `ALGE / BRAWL`; `RUNNER`; `BUILDING`; `REPAIR` |
| School | `RAINLAMP / CAMPUS`; `NIGHT LAB`; `LEARN` |
| Store | `LEAFWIRE / GOODS`; `OPEN`; `DAILY / NEEDS`; `PAY` |
| Trophy shop | `BRASS KITE`; `FRAMES`; `REPAIRS` |
| Post office | `MOONRELAY / POST`; `LETTERS`; `PARCELS`; `WRITE / HERE` |
| Map | `ROOM`; `RAINLAMP`; `MOTH BYTE`; `LEAFWIRE`; `BRASS KITE`; `MOONRELAY` |

No additional pseudo-lettering should be carried into final art from tiny generated texture. The trophy study's original three-triangle pennant was identified during review and corrected to a simple original flower motif in v2; use v2.

## Translation to game assets

Generated art is a mood reference, not a palette-verified source sheet. Use only `art/palette.gpl` in final art, with the five atmospheric additions in `palette.md` appended by Claude only once approved. Approval of Home's visual mood does not by itself record numerical RGB approval. Do not quantise and paste these images as finished backgrounds; Claude draws the final assets at native scale.

Source canvases and slices were read directly through Aseprite in batch mode, without saving source files. Inventory: `art/_work/concept/home-source-inventory.txt` and `art/_work/concept/scene-source-inventory.txt`. Native sizes: Home **680x270**, Arcade **640x270**, School **480x270**, Store **552x270**, Trophy shop **758x270**, Post office **480x270**, map **480x270**. Preserve every slice and layer's user data when drawing. Generated compositions only approximate these regions and must be reconciled in the detailed handoffs.

Home's old exported metadata was stale: the current source places its corkboard on the left and exit on the right. The approved first image predates that discovery. Adapt its mood to the current source rather than moving the source slices to copy its arrangement.

The map study shows buildings integrated for review. In production the map background holds only noninteractive scenery; each clickable building remains its own transparent `map-objects/<id>.aseprite` sprite, positioned by the existing building/base slices. Keep connected walk routes clear. This whole-town image is not a replacement background to export directly.

All studies are static. Any eventual loops require the later frame/timing specifications, a few per screen, and at least 80 ms per frame. No final animation, scene approval or permission to redraw Russell's edited source files is implied by this image set.
