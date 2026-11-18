import { defineCollection } from 'astro:content';
import { glob } from 'astro/loaders';
import { z } from 'astro/zod';

const projects = defineCollection({
  loader: glob({ pattern: '**/*.md', base: './src/content/projects' }),
  schema: ({ image }) =>
    z.object({
      title: z.string(),
      // The one-line pitch shown in bold.
      tagline: z.string(),
      // "building" puts it under "Now building" in the arcade; "shipped" under "Finished".
      status: z.enum(['building', 'shipped']).default('shipped'),
      // A short line under the title: what kind of project, and when.
      meta: z.string().optional(),
      // A few words in the arcade's list on the text page, under the name.
      line: z.string().optional(),
      // Preview images, in order. Put the logo first. Paths are relative to the Markdown file.
      gallery: z.array(z.object({ src: image(), alt: z.string() })).min(1),
      stack: z.array(z.string()).default([]),
      play: z.url().optional(),
      source: z.url().optional(),
      // Lower numbers show first.
      order: z.number().default(0),
    }),
});

export const collections = { projects };
