import type { IconName } from '../components/Icon.astro';

/*
 * Everything personal lives in this file.
 * Projects are separate Markdown files in src/content/projects/.
 */

export const site = {
  name: 'Russell Magdaong',
  // The short form of the name, used wherever the full one does not fit.
  handle: 'russm',
  role: 'Student developer / DOST-SEI scholar / Philippines',
  // Used for search engines and link previews.
  description:
    'Russell Magdaong is a student developer from the Philippines who builds games that teach things: ODIN, TAKO and Algebrawl.',
  email: 'russelldizonmagdaong@gmail.com',
  // Photos behind the hero's "De-pixelate" button: file names in src/assets/pics/, in the order shown.
  // List more than one and they fade from one to the next.
  photos: ['juIYtZ3o1.jpg'],
  // Shown as the status line at the top of the hero. Leave empty to hide it.
  status: '',
  // TODO: drop a PDF in public/ and set this to '/resume.pdf' to show a résumé button.
  resumeUrl: '',
};

// The hero terminal types these out one at a time.
export const dialogue = [
  'I build games that teach things.',
  'Godot up front, plain code behind it.',
  'Now building ODIN, a tutor in a dungeon crawler.',
  'I also edit videos, play games and make music.',
];

export const socials: { label: string; icon: IconName; href: string; handle: string }[] = [
  { label: 'Email', icon: 'email', href: `mailto:${site.email}`, handle: site.email },
  { label: 'GitHub', icon: 'github', href: 'https://github.com/russellmagdaong', handle: 'github.com/russellmagdaong' },
  { label: 'Facebook', icon: 'facebook', href: 'https://www.facebook.com/russssm', handle: 'facebook.com/russssm' },
];

export const about = {
  paragraphs: [
    "I'm a 4th year BS Computer Science student at FEU Tech, specializing in Software Engineering, and a DOST-SEI scholar from the Philippines. Most of what I build ends up being a game that teaches something: math, programming, or whatever I was struggling to learn at the time.",
    'I like the part of a project where the "fun" layer and the "is this actually correct" layer have to meet. In practice that means a lot of Godot on the front and a lot of plain, deterministic code behind it.',
    'Away from that, I edit videos, play games and make music, and I take part in CTFs and hackathons.',
  ],
  stats: [
    { label: 'Degree', value: 'BS Computer Science (Software Engineering)' },
    { label: 'School', value: 'FEU Tech, 4th year' },
    { label: 'Based in', value: 'Philippines' },
    { label: 'Scholarship', value: 'DOST-SEI' },
    { label: 'Now building', value: 'ODIN, my undergraduate thesis' },
    { label: 'Open to', value: 'Software engineering internships' },
  ],
};

// `icon` is a file name in public/icons/ (without .svg). Leave it out to show initials instead.
export const tools: { group: string; items: { name: string; icon?: string }[] }[] = [
  {
    group: 'Games',
    items: [{ name: 'Godot 4', icon: 'godot' }, { name: 'GDScript' }],
  },
  {
    group: 'Web',
    items: [
      { name: 'TypeScript', icon: 'typescript' },
      { name: 'React', icon: 'react' },
      { name: 'Vite', icon: 'vitejs' },
      { name: 'Tailwind CSS', icon: 'tailwindcss' },
    ],
  },
  {
    group: 'Backend and data',
    items: [
      { name: 'C#', icon: 'csharp' },
      { name: 'ASP.NET Core', icon: 'dotnetcore' },
      { name: 'PostgreSQL', icon: 'postgresql' },
      { name: 'SQLite', icon: 'sqlite' },
      { name: 'Supabase', icon: 'supabase' },
    ],
  },
  {
    group: 'Also comfortable in',
    items: [
      { name: 'Java', icon: 'java' },
      { name: 'Python', icon: 'python' },
      { name: 'C++', icon: 'cplusplus' },
    ],
  },
];

// Scrolls past in the band above the contact section.
export const interests = ['Developer', 'Video editor', 'Gamer', 'Musician', 'CTF player', 'Hackathons'];

export const contact = {
  heading: "Want to talk games, code, or a project? Say hi.",
  // The key that lets the "send a message" form email you. Get one free at https://web3forms.com
  // (it is sent to the address the messages should go to) and paste it here. It is made to be
  // public, so it is safe in this file. Left empty, the form opens the visitor's own mail app,
  // with their message written out, instead of sending it itself.
  formKey: '',
};

export const achievements: { title: string; detail?: string }[] = [
  { title: 'DOST-SEI Scholar' },
  { title: 'PMI Project Management Ready', detail: 'Project Management Institute' },
  { title: 'Python developer certification' },
];

// Certificates, grouped under the buttons in the "Other things" section. Each group stays closed
// until its button is pressed. `file` is the image name (without .jpg) in src/assets/certificates/<folder>/.
export const certificates: {
  label: string;
  folder: string;
  items: { file: string; title: string; detail: string }[];
}[] = [
  {
    label: 'Certifications',
    folder: 'certifications',
    items: [
      { file: 'pmi-project-management-ready', title: 'PMI Project Management Ready', detail: 'Project Management Institute, March 2026' },
      { file: 'it-specialist-python', title: 'IT Specialist: Python', detail: 'Certiport, July 2025' },
    ],
  },
  {
    label: 'CTFs',
    folder: 'ctfs',
    items: [
      { file: 'brunnerctf-2026', title: 'BrunnerCTF 2026', detail: '363rd of 1,103 teams, as Billiard Boys' },
      { file: 'boroctf-2026', title: 'boroCTF 2026', detail: 'Rank 121, open division' },
      { file: 'vishwactf-2026', title: 'VishwaCTF 2026', detail: 'Participant, March 2026' },
      { file: 'v1t-ctf-2025', title: 'V1T CTF 2025', detail: 'Rank 240, October 2025' },
      { file: 'deadface-ctf-2025', title: 'DEADFACE CTF 2025', detail: 'Competitor badge, October 2025' },
      { file: 'trend-university-ctf-2025', title: 'Trend University Capture the Flag', detail: 'Preliminary round, August 2025' },
    ],
  },
  {
    label: 'Hackathons and colloquiums',
    folder: 'hackathons',
    items: [
      { file: 'gcash-imagnation-2026', title: 'GCash ImaGnation 2026', detail: '1st runner-up, Top 10 Challenger Team, September 2026' },
      { file: 'acm-techsprint-2026', title: 'ACM TechSprint', detail: '2nd runner-up, June 2026' },
      { file: 'feu-tech-research-colloquium-2026', title: 'FEU Tech Research Colloquium 2026', detail: 'Presented the ODIN paper, July 2026' },
    ],
  },
  {
    label: 'Academic',
    folder: 'academic',
    items: [
      { file: 'deans-silver-certificate', title: "Dean's Silver Certificate", detail: 'FEU Institute of Technology, 3rd Term S.Y. 2024-2025' },
    ],
  },
];
