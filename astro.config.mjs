// @ts-check
import { defineConfig } from 'astro/config';

import tailwindcss from '@tailwindcss/vite';

// https://astro.build/config
export default defineConfig({
  // Where the site is published. The link-preview image and the canonical link have to be
  // full addresses, and they are built from this.
  site: 'https://russm.vercel.app',
  vite: {
    plugins: [tailwindcss()]
  }
});