# Portfolio

Personal portfolio built with [Astro](https://astro.build) and [Tailwind CSS](https://tailwindcss.com), in a neon
cyberpunk style: dark background, cut-corner panels, cyan / magenta / yellow highlights, and a lot of motion.

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
| CTF and hackathon certificates (images)                 | `src/assets/certificates/`   |
| Tool icons                                              | `public/icons/`              |
| Colours, fonts, panel, button and animation styles      | `src/styles/global.css`      |
| Scroll-in, heading and spotlight effects                | `src/scripts/effects.ts`     |
| Page sections                                           | `src/components/`            |

### Your photos

The hero portrait flips between the game sprite and real photos. Put images in `src/assets/pics/` and list the file
names to use under `photos` in `src/data/site.ts`. List more than one and they fade from one to the next. They are
cropped to the frame from the top and resized at build time.

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

- The neon colours are the `--color-*` values at the top of `src/styles/global.css`. Change them there and the whole
  site follows.
- Put `data-accent="cyan"` (or `magenta`, `acid`, `violet`) on any element to recolour the neon inside it.
- `.neon-box` is the cut-corner panel. Its corner size is `--cut`, for example `class="neon-box [--cut:22px]"`.
  Add `neon-run` for the lights that chase along its edges and `data-spotlight` for the glow that follows the pointer.
- Tool icons must be single-colour SVGs: they are used as masks and take the colour of their row.

### Animation notes

- `data-reveal` fades a block up when it scrolls into view (`data-reveal="left"` / `"right"` slide it in from a side).
- `data-stagger` does the same to each child in turn. `style="--i:2"` moves an item later in the queue.
- `data-scramble` on a heading inside a `data-reveal` block makes its letters decode into place.
- Everything respects the visitor's "reduce motion" setting, and the hero's entrance is plain CSS so the first screen
  never waits on a script.

## Deploying

Set `site` in `astro.config.mjs` to your final URL before deploying. If the site will live under a sub-path
(for example `https://username.github.io/portfolio/`), also set `base: '/portfolio'`.

## Credits

- Tool icons: [Devicon](https://devicon.dev), MIT licence. Logos belong to their respective owners.
