# City hub — four front-view concepts

2026-11-16 · Codex · **Concept art for selection**

These replace only the proposed top-down navigation map. The six building scenes and their content remain exactly as planned; no interiors are designed here. Each image is one connected city view, with exterior destination cues. A and B use direct pointing/clicking with a still rear-view figure; C and D provide a walking strip. All six destination signs and entry cues sit within the central **320x180**, coordinates **x80–399, y45–224**, of the **480x270** canvas. Outer scenery is expendable framing. The six neon identities intentionally follow this hub request rather than the brief's usual two-accent limit.

| Concept | Native 480x270 | Nearest-neighbour 4x, 1920x1080 |
|---|---|---|
| A · Open rooftop panorama | [hub-a.png](../_work/concept/hub/hub-a.png) | [hub-a-4x.png](../_work/concept/hub/hub-a-4x.png) |
| B · Fenced canyon overlook | [hub-b.png](../_work/concept/hub/hub-b.png) | [hub-b-4x.png](../_work/concept/hub/hub-b-4x.png) |
| C · Street beneath the skyline | [hub-c.png](../_work/concept/hub/hub-c.png) | [hub-c-4x.png](../_work/concept/hub/hub-c-4x.png) |
| D · Market under a skyway | [hub-d.png](../_work/concept/hub/hub-d.png) | [hub-d-4x.png](../_work/concept/hub/hub-d-4x.png) |

**A — Open rooftop panorama.** A broad, blue-teal city stretches behind an irregular connected residential/commercial block, with an elevated train and successively fogged tower layers establishing a much larger Manila beyond the clickable landmarks. Home is the cyan capiz doorway at lower left; School the violet gated terrace above-left; Arcade the pink entrance on the central-right bridge level; Store the green grille at lower right; Trophy shop the yellow cup-filled window above-right; Post office the red doorway on the lower central bridge. The small still silhouette looks over the foreground roof railing; there is no walkable floor band, and destinations are picked directly. Warm windows and terrace lamps supply the main inhabited light against cool fog, with the six accents kept local to their destinations. Draws on **01** for vast depth and a solitary foreground observer, **04** for distinct neon ownership and pixel density, and **05** for framed signs and occupied window silhouettes. Roof tanks, ledge plants, wires and capiz keep it Filipino rather than a generic future skyline.

**B — Fenced canyon overlook.** Close tower walls and enormous overhead pipes enclose a vertical, amber-lit drop, with bridges linking the six destinations across the canyon rather than arranging them along a single street. Home is the cyan upper-left apartment entry; School the violet gate above the bridge left of centre; Arcade the pink lower-left doorway; Store the green lower-right grille; Trophy shop the yellow upper-right display frontage; Post office the red middle-right stair landing. A still rear-view silhouette leans at the foreground fence, above a cropped vertical service wall; there is no traversable deck. The main light rises from the warm haze far below, while cool tower planes separate the six neon families. Draws on **02** for the fence, glowing drop and warm haze, **06** for overhead service clutter, and **04** for signs with clear colour identities. The foreground remains a vantage point: clicking the distant entries selects the unchanged building scenes.

**C — Street beneath the skyline.** A single continuous, repaired low-rise city frontage sits against a broad layered skyline, with six easy-to-read entrances opening directly onto a calm horizontal wet pavement strip. Left to right: cyan Home, violet School gate, pink Arcade doorway, green Store grille, yellow Trophy window/door and red Post office. The side-on character walks along the strip at the intended 32-pixel scale; all six approach positions share the same ground level, making this the clearest option for walking navigation. A sodium streetlamp from above-left is the main light; broken cyan, violet, pink, green, yellow and red reflections fall below the corresponding fronts without covering the route in detail. Draws on **03** for flat shape clarity and the pink/blue/yellow relationship, **04** for frontage density and individual neon identity, and **05** for framed illuminated signs and window stock silhouettes. Upper-floor capiz, corrugated roofs, tanks, banderitas, tangled wires and a jeepney make the frontage part of a larger inhabited Manila city.

**D — Market under a skyway.** A heavy horizontal skyway forms the ceiling of a two-level neighbourhood, framing a central opening onto distant fogged towers; this is a deeper, more enclosed walking option than C. Home occupies the cyan upper-left bay and School the violet upper-right gate, each with a visible stair approach from the foreground strip. Along the lower market level, left to right, are the green Store grille, pink Arcade entry, yellow Trophy shop and red Post office. The side-on character walks on one continuous foreground strip at the intended 32-pixel scale; the two stair feet serve as the Home/School approaches, while the other four doors are reached directly. Warm lamps hung from the skyway provide the main light, the six destination accents stay on their own bays, and damp paving carries short broken reflections. Draws on **06** for pipes, rain, gutters and overhead enclosure, **04/05** for dense grilles, window stock and framed neon, and **01** for the city depth visible through the central gap. The skyway, service pipes and layered frontage are one city structure, not a map of separate miniature shops.

## Exact signs and destinations

Every main sign is two lines: invented name first, destination word second. Use a shared 3x5 capital alphabet with 1px letter spacing when these concepts are translated into final Aseprite art; use 5x7 only where the selected composition has room. No extra words, real brands, copied reference names or pseudo-script are intended.

| Destination | Exact sign (line 1 / line 2) | Neon colour | Existing scene content |
|---|---|---|---|
| Home | `FERN` / `HOME` | Cyan `#46E6E1`, dim `#19788C` | Russell's room |
| School | `RAIN` / `SCHOOL` | Violet `#BE6EFF`, dim `#602C96` | About |
| Arcade | `MOTH` / `ARCADE` | Pink `#FF4F9A`, dim `#961E5A` | Projects |
| Sari-sari store | `LEAF` / `GOODS` | Green `#7CF05A`, dim `#28783C` | Tools |
| Trophy shop | `KITE` / `TROPHY` | Yellow `#FFE24D`, dim `#96781E` | Credentials |
| Post office | `MOON` / `POST` | Red `#FF463C`, dim `#8C1C24` | Contact |

## Files and method

Generated with the **built-in imagegen tool**, after studying all six `art/_work/refs/hub/` images. References informed atmosphere and visual principles; none was traced, copied into the output or supplied as a source image to reproduce. Refinement calls used only the newly generated concepts. Initial prompts, framing/character correction prompts and selected generated masters are retained beside the deliverables in `art/_work/concept/hub/`.

`export_hub.py` converts each selected generated master to the requested 480x270, maps colours to the existing `art/palette.gpl` without dithering, and writes an exact nearest-neighbour 4x enlargement. The generated masters remain visual working files; the eight named deliverables use only shared palette colours. The native images are concept illustrations for choosing a composition, not layered game assets or a replacement for Claude's final Aseprite drawing. The later implementation can define hit regions and walking approaches around the chosen exterior cues; none is changed here.

No `.aseprite`, `src/`, interior plan or palette files were edited. No commits.
