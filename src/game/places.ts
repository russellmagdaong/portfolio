import type { Place } from './types';

/**
 * Every place in the town: its page, and the building that leads there on the map.
 * The id is the scene's file name (art/scenes/<id>.aseprite) and the building's
 * slice on the map (building:<id>).
 */
export const places: Place[] = [
  { id: 'home', path: '/', title: 'Home', label: "Russell's room" },
  { id: 'school', path: '/about', title: 'About', label: 'School' },
  { id: 'arcade', path: '/projects', title: 'Projects', label: 'Arcade' },
  { id: 'store', path: '/tools', title: 'Tools', label: 'PC repair shop' },
  { id: 'trophy-shop', path: '/credentials', title: 'Credentials', label: 'Trophy shop' },
  { id: 'post-office', path: '/contact', title: 'Contact', label: 'Post office' },
];

export const MAP_PATH = '/map';

export function place(id: string): Place {
  const found = places.find((p) => p.id === id);
  if (!found) throw new Error(`No place called ${id} in src/game/places.ts`);
  return found;
}
