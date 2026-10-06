import type { Accent } from '../lib/accent';

/*
 * Everything personal lives in this file.
 * Lines marked TODO are placeholders: swap them for the real thing.
 * Projects are separate Markdown files in src/content/projects/.
 */

export const site = {
  name: 'Russell Magdaong',
  initials: 'RM',
  role: 'Software Developer',
  // TODO: one-line pitch shown in the hero
  tagline: 'I turn coffee and curiosity into fast, friendly software that people actually enjoy using.',
  // TODO: used for search engines and link previews
  description: 'Portfolio of Russell Magdaong, a software developer who builds web apps, APIs, and developer tools.',
  // TODO
  location: 'Your City, Country',
  // TODO
  email: 'hello@example.com',
  // Shows the "available" badge in the hero and contact section.
  available: true,
  // TODO: drop a PDF in public/ and set this to '/resume.pdf' to show a résumé button.
  resumeUrl: '',
};

// Cycles through the end of "…who builds ___" in the hero.
export const rotatingWords = ['web apps', 'speedy APIs', 'developer tools', 'tiny experiments'];

// TODO: point LinkedIn at your real profile
export const socials = [
  { label: 'GitHub', href: 'https://github.com/russellmagdaong' },
  { label: 'LinkedIn', href: 'https://www.linkedin.com/in/your-username' },
];

export const about = {
  // TODO: your story, in your voice
  paragraphs: [
    "I'm a software developer who likes the whole trip: sketching an idea, wiring up the backend, and sweating the last few pixels until it feels right.",
    'Placeholder bio. Say what kind of problems you love, what you have shipped, and what makes working with you different. Two or three short paragraphs is plenty.',
    'Away from the keyboard you can find me doing placeholder hobby one, placeholder hobby two, and hunting for the best coffee in town.',
  ],
  // TODO
  facts: [
    { label: 'Based in', value: 'Your City' },
    { label: 'Currently', value: 'Building side projects' },
    { label: 'Powered by', value: 'Coffee & lo-fi' },
  ],
};

// TODO: list what you actually use
export const skills: { title: string; accent: Accent; items: string[] }[] = [
  { title: 'Languages', accent: 'pink', items: ['TypeScript', 'JavaScript', 'Python', 'SQL'] },
  { title: 'Frontend', accent: 'sky', items: ['React', 'Astro', 'Tailwind CSS', 'HTML & CSS'] },
  { title: 'Backend', accent: 'mint', items: ['Node.js', 'REST APIs', 'PostgreSQL', 'Auth'] },
  { title: 'Tools', accent: 'tang', items: ['Git & GitHub', 'Docker', 'VS Code', 'Figma'] },
];

// TODO: newest first
export const experience = [
  {
    role: 'Software Developer',
    company: 'Company Name',
    period: '2025 — Present',
    summary: 'Placeholder. One sentence on what the team does and what you own.',
    highlights: [
      'Shipped a feature that improved something measurable by some percent.',
      'Rebuilt a slow thing so it became a fast thing.',
    ],
  },
  {
    role: 'Junior Developer / Intern',
    company: 'Another Company',
    period: '2023 — 2025',
    summary: 'Placeholder. What you learned and what you delivered.',
    highlights: ['Built and maintained internal tools used by the whole team.'],
  },
  {
    role: 'BS in Your Degree',
    company: 'Your University',
    period: '2019 — 2023',
    summary: 'Placeholder. Capstone project, org work, or awards worth a mention.',
    highlights: [],
  },
];
