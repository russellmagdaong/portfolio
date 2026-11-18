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
    'Russell Magdaong is a student developer from the Philippines who builds games that teach things (ODIN, TAKO, Algebrawl) and is now building NOVA, a voice assistant.',
  email: 'russelldizonmagdaong@gmail.com',
  // Photos behind the hero's "De-pixelate" button: file names in src/assets/pics/, in the order shown.
  // List more than one and they fade from one to the next.
  photos: ['updated pic.png'],
  // Shown as the status line at the top of the hero. Leave empty to hide it.
  status: '',
  // TODO: drop a PDF in public/ and set this to '/resume.pdf' to show a résumé button.
  resumeUrl: '',
  // The postmark on the text page's postcard (where and when it was sent).
  postmark: 'Manila · November 2026',
};

// The hero terminal types these out one at a time.
export const dialogue = [
  'I build games that teach things.',
  'Godot up front, plain code behind it.',
  'ODIN, my thesis, is defended.',
  'Now building NOVA, a voice assistant.',
  'I also edit videos, play games and make music.',
];

// The text page's sidebar: under each place's sign word, one line on what is inside.
export const placeLines: Record<'home' | 'school' | 'arcade' | 'store' | 'trophy-shop' | 'post-office', string> = {
  home: "Who's writing, and what I'm open to",
  school: '4th-year CS at FEU Tech, DOST scholar',
  arcade: 'Games that teach: ODIN, TAKO, Algebrawl',
  store: 'Godot, C#, TypeScript and the rest',
  'trophy-shop': "Dean's List, hackathons, CTFs",
  'post-office': 'Write me a letter',
};

// What each place's sign says, on the street and on the text page's sidebar and panels.
export const signWords: Record<keyof typeof placeLines, string> = {
  home: 'HOME',
  school: 'ABOUT ME',
  arcade: 'PROJECTS',
  store: 'TOOLS',
  'trophy-shop': 'AWARDS',
  'post-office': 'CONTACT',
};

export const socials: { label: string; icon: IconName; href: string; handle: string }[] = [
  { label: 'Email', icon: 'email', href: `mailto:${site.email}`, handle: site.email },
  { label: 'GitHub', icon: 'github', href: 'https://github.com/russellmagdaong', handle: 'github.com/russellmagdaong' },
  { label: 'LinkedIn', icon: 'linkedin', href: 'https://www.linkedin.com/in/russell-magdaong/', handle: 'linkedin.com/in/russell-magdaong' },
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
    { label: 'Thesis', value: 'ODIN, defended' },
    { label: 'Now building', value: 'NOVA, a voice assistant' },
    { label: 'Open to', value: 'Software engineering and game dev internships' },
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

// The props in Russell's room. Each shows its card when pointed at or walked up to; `id` is the
// prop's tip in art/scenes/home.aseprite (prop:<thing> with tip=<id>). The CTF and hackathon
// cards also list the results from `certificates` below.
export const interests: { id: string; label: string; detail: string }[] = [
  {
    id: 'music',
    label: 'Musician',
    detail:
      "I make music. I've joined battles of the bands, and once played at iTAMNight, on the same lineup as Ben&Ben and Sean Archer.",
  },
  {
    id: 'games',
    label: 'Gamer',
    detail: 'I started gaming very young. That is where my love for video games, and for making them, began.',
  },
  { id: 'video', label: 'Video editor', detail: 'I edit videos. Portfolio coming soon.' },
  { id: 'ctf', label: 'CTF player', detail: 'I take part in capture-the-flag contests.' },
  { id: 'hackathons', label: 'Hackathons', detail: 'I enter hackathons and present at colloquiums.' },
];

export const contact = {
  heading: "Want to talk games, code, or a project? Say hi.",
  // The key that lets the "send a message" form email you. Get one free at https://web3forms.com
  // (it is sent to the address the messages should go to) and paste it here. It is made to be
  // public, so it is safe in this file. Left empty, the form opens the visitor's own mail app,
  // with their message written out, instead of sending it itself.
  formKey: '',
};

// From the résumé (RMagdaong_Resume_FEU_v2, November 2026).
export const achievements: { title: string; detail?: string }[] = [
  { title: '1st Runner-Up', detail: 'GCash ImaGnation 2026' },
  { title: '2nd Runner-Up', detail: 'ACM TechSprint 2026' },
  { title: "Dean's Lister", detail: '2025 – 2026' },
  { title: '6th Runner-Up', detail: 'ARTwakening 2024' },
  { title: 'DOST-SEI Scholar' },
];

export const organizations: { role: string; group: string; years: string }[] = [
  { role: 'Social Media Manager', group: 'iTamaraws Esports Club', years: '2024 – 2026' },
  { role: 'External Communications', group: 'ACM Student Chapter', years: '2024 – 2025' },
  { role: 'Member', group: 'ACM, JPCS and SAGE', years: '2023 – 2026' },
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
    label: 'Hackathons and Colloquiums',
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
      { file: 'deans-bronze-certificate-2025-2026', title: "Dean's Bronze Certificate", detail: 'FEU Institute of Technology, 2nd Term S.Y. 2025-2026' },
      { file: 'deans-silver-certificate', title: "Dean's Silver Certificate", detail: 'FEU Institute of Technology, 3rd Term S.Y. 2024-2025' },
      { file: 'deans-bronze-certificate-2024-2025', title: "Dean's Bronze Certificate", detail: 'FEU Institute of Technology, 2nd Term S.Y. 2024-2025' },
    ],
  },
];
