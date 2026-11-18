# Palette concept — fog between the lights

Status: **concept ready · awaiting Russell's OK**  
Prepared: 2026-11-16 · Codex  
Scope: proposal only. Claude appends approved entries to `art/palette.gpl`; this concept does not change that file or any Aseprite source.

## Mood and reference reading

A warm, occupied Manila neighbourhood sits below a damp, blue-teal city. The distance should feel full of buildings without making every building equally loud. In `skyline-rain.png`, the useful lesson is the broad, low-contrast fog behind overlapping tower silhouettes, the thinning window lights with distance, and the abrupt return of contrast on nearby infrastructure. In `market-street.png`, it is the cool shared shadow colour that holds together a very crowded arrangement of shop boxes, machines, conduits, tiled panels and awnings. Borrow those colour relationships and density principles only. Do not sample, trace, reproduce their layouts, or reuse their sign names. Retain our violet shadows, warm sodium light and Filipino domestic materials.

## Why add colours

The existing sky ramp moves through saturated purple; the concrete ramp is also violet-biased. `neon cyan dim` is a coloured light, too saturated to serve as neutral atmospheric distance. `holo dim` and `screen glow` are likewise source colours. None gives us a restrained blue-teal fog ramp. Recolouring everything purple or using neon cyan for distant buildings would flatten the warm/cool separation seen in the references.

Add **five** atmospheric colours. Existing colours already cover warm light, materials, tube highlights and deep violet occlusion. No new neon, warm, black, white or character colours are needed.

## Proposed append-only entries

Listed darkest to lightest. Names below are the exact proposed GPL names. Their roles are environmental colour, not extra neon accents.

| Name | Hex | RGB | Intended use |
|---|---|---|---|
| `mist 1` | `#24343F` | 36, 52, 63 | Nearest atmospheric silhouette; cool recesses in exterior infrastructure |
| `mist 2` | `#304550` | 48, 69, 80 | Middle skyline mass; dim rail or rooftop silhouette |
| `mist 3` | `#3E5660` | 62, 86, 96 | Farthest tower mass against fog; middle-distance lit plane |
| `mist 4` | `#506A73` | 80, 106, 115 | Fog bank/sky field behind the farthest skyline |
| `mist 5` | `#667F86` | 102, 127, 134 | Small distant window groups, isolated damp edges; use sparingly |

After approval, append these after the current final entry, `neon haze (a sky tint where signs light the air)`. Never insert or reorder entries; preserve the character indices, including entries 0–17. Claude should check for an identical RGB already present before appending.

```text
# --- Approved atmospheric distance ramp (date of approval)
 36  52  63 mist 1
 48  69  80 mist 2
 62  86  96 mist 3
 80 106 115 mist 4
102 127 134 mist 5
```

## Depth and light assignment

Approval includes permission to use this ramp in `sky`, `far` and `mid`, extending the brief's existing sky/concrete restriction for distance. All other brief rules remain applicable. This is a proposal to approve, not an instruction to change `BRIEF.md`.

| Depth, back to front | Colour assignment | Contrast and detail |
|---|---|---|
| `sky` | Existing `night`/`sky high` above; a flat `mist 4` bank behind the skyline | Broad stepped shapes; no gradient or translucent fog overlay |
| `far`, farthest silhouette | `mist 3` against `mist 4` | One silhouette tone; almost no windows, no readable lettering |
| `far`, second silhouette | `mist 2`; at most a few `mist 3` windows | Interrupt the outline with uneven heights; no tiny high-contrast machinery |
| `mid`, third silhouette | `mist 1`, with `mist 2` planes and sparse `mist 4`/`mist 5` windows | Rooftop tanks, rail supports and antennas become identifiable; withhold bright tubes |
| `back` / `props` | Existing concrete, plaster, wood, iron and sodium ramps | Full material separation; large, medium and small detail clusters on exposed walls |
| `floor` | Existing concrete 3–5 or wood 2–3 indoors | Calm mid-dark walking band; atmospheric ramp must not wash out Russell |
| `front` | Existing `ink`, deep violet and dark material shades | Cable/canopy silhouettes frame the view; selective coloured edges, no all-round black outlines |

These are depth roles, not a compulsory skyline in every room. A window or open doorway can reveal them; solid indoor walls occlude them. Do not add five equally distinct horizontal building strips. Overlap irregular silhouettes, compress the distant values, and let fog remove small details.

Warm main light remains above-left unless the approved scene specifies another source. Home is intended to use cyan locally; Arcade pink locally. Their exact fixtures, placements and secondary accents belong to their later concepts. Each screen keeps the brief's maximum of two neon colours. Sodium 5, tube colours and white remain tiny light sources or glints. Atmospheric `mist 5` is not a replacement for these highlights.

Outdoors, broken horizontal strokes of the existing **dim sign colour** reflect directly below that sign. Rain can use restrained `mist 3`/`mist 4` strokes against darker exterior shapes. Keep indoor floors dry. Use opaque palette pixels only: no blur, alpha glow, additive blending or generated in-between colours. Neon retains its one-pixel dim ring; do not copy the reference's broad bloom.

## Density commitment for the scene concepts

The new ramp supplies depth, not detail by itself. Each later scene concept must budget big, medium and small forms in each occupied wall bay: for example a window or sign; a shelf, fan or junction box; then cable clips, panel seams and small marks. Signs should vary in mounting and scale, with some unlit. Include uneven small lights and overhead clutter. Maintain plain HTML content interiors, clear object silhouettes and a quieter walking band. The block-outs will group this detail into masses; Claude's final art must resolve the listed objects rather than leave those masses as empty rectangles.

## Lettering and motion

This palette sheet introduces **no in-world signs or invented businesses**. Preview labels are review annotations only. Every later scene concept must provide an exhaustive English sign schedule with exact invented wording, 3x5 or 5x7 glyph size, pixel position and colour. No placeholder script, copied reference lettering, or decorative pseudo-text. Project/content labels belong to their specified content surfaces and must not be renamed for decoration.

There is no animation in the palette concept. Scene concepts will specify only a few loops per screen, durations at least 80 ms, with no essential information dependent on motion.

## Review image and handoff

See `art/_work/concept/palette-preview.png`, reproducible with `palette-preview.py` beside it. This is a **640x320 colour diagnostic**, not a scene block-out: paired, identical abstract value arrangements compare the existing violet ramp with the proposed atmosphere while retaining the same near-light colours. Five swatches below identify the additions. It contains flat colours only, using existing GPL colours plus the five explicitly proposed additions. It is not an exportable art asset and contains no reference pixels.

The palette has no scene canvas, slices, objects or platforms. Their exact layer placement, slice inventory and real-size PNG block-outs will be supplied only when each scene's turn is approved.

On approval: Claude appends the five entries, then loads the palette for final drawing. Codex proceeds to `scenes/home` only after Russell's OK. `scenes/arcade` requires a separate subsequent OK.
