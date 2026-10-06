# Portfolio

Personal portfolio built with [Astro](https://astro.build) and [Tailwind CSS](https://tailwindcss.com).

## Commands

| Command           | What it does                              |
| :---------------- | :---------------------------------------- |
| `npm run dev`     | Start the dev server at `localhost:4321`  |
| `npm run build`   | Build the production site into `dist/`    |
| `npm run preview` | Preview the production build locally      |

## Where to edit

| What                                         | Where                                 |
| :------------------------------------------- | :------------------------------------ |
| Name, bio, skills, experience, contact links | `src/data/site.ts`                    |
| Projects (one Markdown file each)            | `src/content/projects/`               |
| Colours, fonts, shared styles                | `src/styles/global.css`               |
| Page sections                                | `src/components/`                     |

Placeholder content is marked with `TODO` — search the project for it to find everything left to fill in.

### Adding a project

Create `src/content/projects/my-project.md`:

```md
---
title: My Project
summary: One sentence about it.
year: 2026
tags: [TypeScript, React]
accent: pink # pink | sun | mint | sky | grape | tang
repo: https://github.com/you/my-project # optional
demo: https://my-project.example.com # optional
order: 1 # lower shows first
---

Write the case study here in Markdown.
```

It shows up on the home page and gets its own page at `/projects/my-project/`.

## Deploying

Set `site` in `astro.config.mjs` to your final URL before deploying. If the site will live under a sub-path
(for example `https://username.github.io/portfolio/`), also set `base: '/portfolio'`.
