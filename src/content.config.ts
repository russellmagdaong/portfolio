import { defineCollection } from 'astro:content';
import { glob } from 'astro/loaders';
import { z } from 'astro/zod';
import { accents } from './lib/accent';

const projects = defineCollection({
  loader: glob({ pattern: '**/*.md', base: './src/content/projects' }),
  schema: z.object({
    title: z.string(),
    summary: z.string(),
    year: z.number(),
    tags: z.array(z.string()).default([]),
    accent: z.enum(accents).default('sun'),
    repo: z.url().optional(),
    demo: z.url().optional(),
    // Lower numbers show first.
    order: z.number().default(0),
  }),
});

export const collections = { projects };
