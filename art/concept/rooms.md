# Individual room concepts — second visual set

Six separately generated side-on interior studies, requested after the city hub concepts. The original scene purposes, interactions and palette identities remain in place. These are visual alternatives for review; they do not replace the existing Aseprite art or approve a redraw. The city hub is unchanged.

| Room | Native-size concept | 4x enlargement | Generation prompt |
|---|---|---|---|
| Home | [680x270](../_work/concept/rooms/home.png) | [Home 4x](../_work/concept/rooms/home-4x.png) | [Prompt](../_work/concept/rooms/home-prompt.txt), [correction](../_work/concept/rooms/home-correction-prompt.txt) |
| Arcade | [640x270](../_work/concept/rooms/arcade.png) | [Arcade 4x](../_work/concept/rooms/arcade-4x.png) | [Prompt](../_work/concept/rooms/arcade-prompt.txt) |
| School | [480x270](../_work/concept/rooms/school.png) | [School 4x](../_work/concept/rooms/school-4x.png) | [Prompt](../_work/concept/rooms/school-prompt.txt) |
| Sari-sari store | [552x270](../_work/concept/rooms/store.png) | [Store 4x](../_work/concept/rooms/store-4x.png) | [Prompt](../_work/concept/rooms/store-prompt.txt), [English-lettering correction](../_work/concept/rooms/store-correction-prompt.txt) |
| Trophy shop | [758x270](../_work/concept/rooms/trophy-shop.png) | [Trophy shop 4x](../_work/concept/rooms/trophy-shop-4x.png) | [Prompt](../_work/concept/rooms/trophy-shop-prompt.txt) |
| Post office | [480x270](../_work/concept/rooms/post-office.png) | [Post office 4x](../_work/concept/rooms/post-office-4x.png) | [Prompt](../_work/concept/rooms/post-office-prompt.txt) |

**Home.** A personal creative room under a warm sodium tube, with cyan electronics and rainy blue-teal rooftops beyond the right window. Keep the current source's left corkboard, mirror, plain poster, PC, music/game/video/CTF/hackathon props and right exit. Dense shelf stock, capiz, plants, clipped wiring and lenses frame the calm content surfaces. The mood carries forward the approved first Home study; the new image uses the current left-to-right arrangement rather than the stale export.

**Arcade.** A pink-accented game room with the five planned cabinets: NOVA, ODIN, TAKO, Algebrawl and the playable runner. Cabinets, token equipment and a repair bench communicate work in progress; parts trays, old displays, bundled cables and vending stock fill the surrounding room. Main overhead lamps remain sodium warm. NOVA sits near the exit with its building placard. The runner remains in the concept because PLAN.md requires it, even though the current source inventory no longer includes an `object:runner` slice. No missing slice was recreated or other source setting changed here.

**School.** A covered campus bulletin room/corridor, violet lab signage, warm capiz and a cold rainy courtyard beyond the open side. The two large board interiors stay plain for About/profile content. Fans, conduit, breeze blocks, plants and stacked chairs supply visual density without concealing the boards. Actual FEU Tech and DOST-SEI information remains in the planned HTML content rather than fabricated in the art.

**Store.** A green-accented sari-sari interior with sachet strips, stock jars, grille, rice sacks, electric meters and a small card reader. The four tool display recesses remain plain for the Tools HTML; decorative stock surrounds them. Warm counter lamps keep the shop welcoming, and the dry customer-side floor stays calmer than the wall of goods.

**Trophy shop.** A warm brass-and-wood framing workshop with five clear credential surfaces, varied cup silhouettes, ribbon stock, frame clamps and small fastener trays. The scene retains its planned violet sign accent; it does not inherit the hub's yellow destination colour. Pennants use original simple motifs, avoiding existing game emblems. No fake certificate wording or new qualifications are painted into the frames.

**Post office.** A cyan-accented night mail office centred on a small writing counter. Pigeonholes, letters, parcels, bags, twine, stamps and a scale surround a plain socials board. Warm light over the letter surface makes the contact interaction clear; rain remains outside the shutter, and the interior floor stays dry. The existing counter still leads to the Contact form.

## Exact English sign schedule

Slashes below mean line breaks. Final Aseprite lettering should use the shared 3x5 or 5x7 glyphs. No unlisted tiny writing, branded package labels, real company names or copied logos should be carried forward from generated texture.

| Room | All intended wording |
|---|---|
| Home | `ROOM`; `NIGHT / FERN` |
| Arcade | `MOTH BYTE`; `NOVA`; `ODIN`; `TAKO`; `ALGE / BRAWL`; `RUNNER`; `BUILDING`; `REPAIR` |
| School | `RAINLAMP / CAMPUS`; `NIGHT LAB`; `LEARN` |
| Store | `LEAFWIRE / GOODS`; `OPEN`; `DAILY / NEEDS`; `PAY` |
| Trophy shop | `BRASS KITE`; `FRAMES`; `REPAIRS` |
| Post office | `MOONRELAY / POST`; `LETTERS`; `PARCELS`; `WRITE / HERE` |

## Method and limits

Built-in **imagegen** generated each room individually. These are new original images, not crops of the city hub or copies of the earlier studies. The references' fog-separated skyline depth and multi-scale surface clutter inform the art direction. No reference image pixels were inserted.

Source files were inspected read-only before writing prompts. The prompts preserve their interaction/content ordering and approximate rectangles, but generated shapes are not exact geometry: Claude must preserve actual slice bounds and layer user data when translating an approved concept. Plain HTML interiors remain intentional; some generated furniture or borders will need reconciliation at native game scale. Native-size detailed concepts are not the flat block-outs or exhaustive layer/animation handoffs required before final drawing.

Selected generated masters and exact prompts are stored in `art/_work/concept/rooms/`. `export_room.py` writes native-size palette-mapped review PNGs and exact nearest-neighbour 4x enlargements; it never opens or saves an Aseprite file. Palette mapping uses the current shared `art/palette.gpl`, without dithering. No animation is proposed in this visual set.

Edits are confined to `art/concept/` and `art/_work/concept/`. No `.aseprite`, `src/`, palette or hub file was changed. No commits.
