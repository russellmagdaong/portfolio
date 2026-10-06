export const accents = ['pink', 'sun', 'mint', 'sky', 'grape', 'tang'] as const;

export type Accent = (typeof accents)[number];

// Spelled out in full so Tailwind can see the class names.
export const accentBg: Record<Accent, string> = {
  pink: 'bg-pink',
  sun: 'bg-sun',
  mint: 'bg-mint',
  sky: 'bg-sky',
  grape: 'bg-grape',
  tang: 'bg-tang',
};

export const accentFill: Record<Accent, string> = {
  pink: 'fill-pink',
  sun: 'fill-sun',
  mint: 'fill-mint',
  sky: 'fill-sky',
  grape: 'fill-grape',
  tang: 'fill-tang',
};

export const accentAt = (index: number): Accent => accents[index % accents.length];
