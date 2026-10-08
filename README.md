# Portfolio

Personal portfolio built with [Astro](https://astro.build) and [Tailwind CSS](https://tailwindcss.com), styled like
an arcade machine: a black CRT face, pixel lettering, flat cyan / magenta / yellow, and a lot of motion.

## Commands

| Command           | What it does                              |
| :---------------- | :---------------------------------------- |
| `npm run dev`     | Start the dev server at `localhost:4321`  |
| `npm run build`   | Build the production site into `dist/`    |
| `npm run preview` | Preview the production build locally      |

If projects or images go missing in the dev server after files are moved or renamed, restart it.

## Where to edit

| What                                                    | Where                        |
| :------------------------------------------------------ | :--------------------------- |
| Name, short name, bio, typed lines, tools, contact      | `src/data/site.ts`           |
| Projects (one Markdown file each)                       | `src/content/projects/`      |
| Project images (one folder per project)                 | `src/assets/projects/`       |
| Hero portrait: game sprite and real photo               | `src/assets/hero/`           |
| Minigame character (sprite sheet, built from GIFs)      | `src/assets/runner/`         |
| CTF and hackathon certificates (images)                 | `src/assets/certificates/`   |
| Tool icons                                              | `public/icons/`              |
| Browser-tab icon and link-preview image                 | `public/`                    |
| Colours, fonts, panel, button and animation styles      | `src/styles/global.css`      |
| Scroll-in, heading and spotlight effects                | `src/scripts/effects.ts`     |
| Page sections                                           | `src/components/`            |

### Your photos

The hero portrait flips between the game sprite and real photos. Put images in `src/assets/pics/` and list the file
names to use under `photos` in `src/data/site.ts`. List more than one and they fade from one to the next. They are
cropped to the frame from the top and resized at build time.

### Minigame character

The runner under the hero animates from one sprite sheet, `src/assets/runner/man.png`, with a row each for idle,
run, jump, slide and death. It is built from five GIFs: `man_idle.gif`, `man_run.gif`, `man_jump.gif`,
`man_slide.gif` and `man_death.gif`.
After changing them, rebuild the sheet by pointing the script at their folder:

```
node scripts/runner-sprites.mjs path/to/the/gifs
```

The GIFs can be exported at any whole-number scale, as long as they all share it and have a transparent background.
They do not have to be the same size: they are lined up by their bottom edge (the ground) and the middle of their width.
The obstacles are not images: they are drawn in code, in `src/scripts/runner-obstacles.ts`.

### Icon and link preview

The browser-tab icon is `public/favicon.svg`. After changing it, run `node scripts/favicons.mjs` to remake the two
copies that cannot be SVG: `favicon.ico` and `apple-touch-icon.png` (for iPhone and iPad).

`public/og.png` is the picture that Facebook, Discord, X and the like show when the site is shared. It is drawn by
`scripts/og-image.mjs`, which needs Playwright (see the top of that file). Those sites keep their own copy of a
preview for a while, so a new image can take time to show up on links that were shared before.

### Certificates

Certificates sit behind the buttons in the "Other things" section and only appear when one is pressed.
To add one, save it as a `.jpg` in `src/assets/certificates/<folder>/` and add a line for it to the `certificates`
list at the bottom of `src/data/site.ts` (file name, title, one line of detail). PDFs must be exported as images first.

### Adding a project

Put its images in `src/assets/projects/my-project/`, then create `src/content/projects/my-project.md`:

```md
---
title: My Project
tagline: The one-line pitch, shown in bold.
gallery: # shown in this order; put the logo first
  - src: ../../assets/projects/my-project/logo.png
    alt: The My Project logo
  - src: ../../assets/projects/my-project/gameplay.png
    alt: What this screenshot shows
stack: [Godot 4, GDScript]
play: https://my-project.example.com # optional
source: https://github.com/you/my-project # optional
order: 4 # lower shows first
---

Write the description here in Markdown.
```

To add screenshots to an existing project, drop the files in its folder and add entries to its `gallery` list.
Images narrower than 400px are treated as pixel-art logos: they get a margin and stay sharp when scaled up.

### Styling notes

- The colours are the `--color-*` values at the top of `src/styles/global.css`. Change them there and the whole
  site follows. Each has one job: cyan is the interface (frames, titles, links), yellow is the thing to press,
  magenta is for emphasis.
- Put `data-accent="cyan"` (or `magenta`, `acid`, `violet`) on any element to recolour what is inside it.
- The fonts are set in the same place: a pixel font for names and titles, a sans for reading, a mono for labels.
  The pixel font is drawn on an 8px grid, so it is sharpest at 8, 16, 24, 32px and so on.
- `.panel` is the framed box with pixel-stepped corners. `--bw` is its border width, `--px` the size of a corner
  step and `--line` the border colour, for example `class="panel [--bw:4px] [--line:var(--accent)]"`.
  Add `panel-run` for the dashes that chase along its edges and `data-spotlight` for the dots that light up under
  the pointer.
- `title-chrome` gives a title the three-band fill of the section headings; `chip` is the small bracketed label.
- Tool icons must be single-colour SVGs: they are used as masks and take the section's colour.

### Animation notes

- The home page is a set of stages, not one long scroll: each stage fills the screen and holds still, and
  scrolling on changes the picture to the next stage in its place. A stage taller than the screen scrolls as usual
  until its end. A stage is a `<Stage>` in `src/pages/index.astro`; it can hold more than one section, and its `id`
  is what links point at.
- Scrolling never rests between two stages: once it has left one it carries on to the next, which settles in the
  middle of the screen. `NUDGE_PX` in `src/components/Stage.astro` is how far counts as having left.
- The changes between stages (scan line, iris, pixel dissolve, interlace, glitch) are listed in `CHANGES` in
  `src/components/Stage.astro` and drawn under "Stages" in `src/styles/global.css`. `--stage-hold` there is how far
  a stage holds. Contents smaller than the window are enlarged to use it, up to `MAX_FIT`.
- `data-reveal` fades a block up when it scrolls into view (`data-reveal="left"` / `"right"` slide it in from a side).
- `data-stagger` does the same to each child in turn. `style="--i:2"` moves an item later in the queue.
- `data-scramble` on a heading inside a `data-reveal` block makes its letters decode into place.
- Everything respects the visitor's "reduce motion" setting, and the hero's entrance is plain CSS so the first screen
  never waits on a script.

## Deploying

`site` in `astro.config.mjs` is the address the site is published at; the link preview and canonical link are built
from it, so change it if the site moves. If the site will live under a sub-path
(for example `https://username.github.io/portfolio/`), also set `base: '/portfolio'`.

## Credits

- Tool icons: [Devicon](https://devicon.dev), MIT licence. Logos belong to their respective owners.
