/**
 * Where Russell is, in either version of the site, so switching between them keeps his place.
 *
 * A spot is a place (a scene's id, or 'street' for the hub) and, inside it, the thing he is at:
 * a panel's id (object:<id> opens=<id>), a board (show:<id>), a prop's card (prop:<x> tip=<id>), or
 * on the street a building's id. The text page (src/components/text/TextSite.astro) marks the same
 * things with data-spot inside each section's data-place, so a spot names the same thing in both.
 *
 * The running scene or street registers how to read and set his spot (registerSpot). A spot in
 * another place is carried over the page load in sessionStorage ('arrive').
 */
export interface Spot {
  place: string;
  id: string | null;
}

interface Engine {
  get: () => Spot;
  put: (id: string) => void;
}

let engine: Engine | null = null;
/** A put asked for before the engine was ready. */
let pending: string | null = null;

export function registerSpot(get: () => Spot, put: (id: string) => void) {
  engine = { get, put };
  if (pending) {
    put(pending);
    pending = null;
  }
}

/** Where he is in the game, if a game is running. */
export const gameSpot = () => engine?.get() ?? null;

/** Stands him at a thing in this place (once the engine is ready). */
export function putAt(id: string) {
  if (engine) engine.put(id);
  else pending = id;
}

/** Marks the spot for the page about to load (a different place). */
export function arriveAt(spot: Spot) {
  try {
    sessionStorage.setItem('arrive', JSON.stringify(spot));
  } catch {}
}

/** The thing to start at in this place, if the last page sent him here; forgets it either way. */
export function takeArrival(place: string): string | null {
  try {
    const raw = sessionStorage.getItem('arrive');
    sessionStorage.removeItem('arrive');
    const spot = raw ? (JSON.parse(raw) as Spot) : null;
    return spot?.place === place ? spot.id : null;
  } catch {
    return null;
  }
}

/**
 * Whether the game has been shown since this tab last loaded fresh (Russell, 2026-11-18): the first
 * switch to the game starts at home, every later one arrives on the street by jeepney. Kept in
 * sessionStorage so walking into a building (a page load) keeps it, and forgotten on a reload.
 */
const PLAYED = 'game-played';

/** Forgets the mark if this page load is a reload. Run once, first thing. */
export function forgetPlayedOnReload() {
  try {
    const nav = performance.getEntriesByType('navigation')[0] as PerformanceNavigationTiming | undefined;
    if (nav?.type === 'reload') sessionStorage.removeItem(PLAYED);
  } catch {}
}

export function markPlayed() {
  try {
    sessionStorage.setItem(PLAYED, '1');
  } catch {}
}

export function hasPlayed() {
  try {
    return sessionStorage.getItem(PLAYED) === '1';
  } catch {
    return false;
  }
}

/** Asks the street (the page about to load, or this one) to bring him in by jeepney. */
export function sendByJeepney() {
  try {
    sessionStorage.setItem('jeep-arrive', '1');
  } catch {}
}

/** Whether the last page sent him by jeepney; forgets it either way. */
export function takeJeepney(): boolean {
  try {
    const sent = sessionStorage.getItem('jeep-arrive') === '1';
    sessionStorage.removeItem('jeep-arrive');
    return sent;
  } catch {
    return false;
  }
}
