/**
 * Switching to the text page (Russell, 2026-11-18): on the postcard's street, the jeepney drives in
 * from the left and stops at its spot, he gets off at the curb and runs to where the postcard
 * stands him (the door of this page's place, up the stairs if it is on the landings), then idles.
 *
 * The postcard (src/components/text/PostcardFront.astro) is plain CSS: this moves its jeepney layer
 * and his sprite for the length of the trip, then hands them back as they were. Geometry is the
 * street's own (floors, stairs, the jeep slice), read as src/game/hub.ts reads it.
 */
import { reducedMotion } from './view';

interface Pt {
  x: number;
  y: number;
}
interface Floor {
  x0: number;
  x1: number;
  y0: number;
  y1: number;
}
interface Tag {
  row: number;
  frames: number;
  durations: number[];
}
interface Ride {
  jeep: { x: number; width: number };
  floors: Record<string, Floor>;
  stairs: { lower: string; upper: string; bottom: Pt; top: Pt }[];
  origin: Pt;
  size: { w: number; h: number };
  run: Tag;
  target: Pt & { level: string };
}

/** How hard the jeepney slows to a stop (art px/s²); the hub's is 900, a touch gentler here. */
const BRAKE = 600;
/** Stopped, it waits this long (ms) before he steps off. */
const PAUSE = 260;
/** His running speed on the flat and along a stairway (art px/s), as in the game. */
const RUN = 132;
const STAIR = 110;
/** On a stairway his feet sit 1px over the slice's diagonal (the tread tops), as in the game. */
const STAIR_LIFT = 1;

const root = document.documentElement;
let current = 0;

/** A leg of his walk: from one point to the next, how long it takes, and whether it is a stairway. */
interface Leg {
  from: Pt;
  to: Pt;
  ms: number;
  stair: boolean;
}

function legsOf(ride: Ride, start: Pt): Leg[] {
  const legs: Leg[] = [];
  let at = start;
  const walk = (to: Pt, speed: number, stair = false) => {
    const ms = (Math.hypot(to.x - at.x, to.y - at.y) / speed) * 1000;
    if (ms > 0) legs.push({ from: at, to, ms, stair });
    at = to;
  };
  const t = ride.target;
  if (t.level !== 'street') {
    // The stairway whose ends make the shortest walk, as the game picks one.
    const usable = ride.stairs.filter((s) => s.lower === 'street' && s.upper === t.level);
    const best = usable.sort(
      (a, b) => Math.abs(a.bottom.x - start.x) + Math.abs(a.top.x - t.x) - (Math.abs(b.bottom.x - start.x) + Math.abs(b.top.x - t.x)),
    )[0];
    if (best) {
      walk(best.bottom, RUN);
      walk(best.top, STAIR, true);
    }
  }
  walk({ x: t.x, y: t.y }, RUN);
  return legs;
}

/** Plays the arrival on the postcard's street. Does nothing with reduced motion. */
export function playFrontRide() {
  const front = document.querySelector<HTMLElement>('[data-front]');
  const data = front?.querySelector<HTMLScriptElement>('[data-front-ride]');
  const me = front?.querySelector<HTMLElement>('[data-front-russell]');
  const jeepney = front?.querySelector<HTMLElement>('[data-layer="jeepney"]');
  const clip = front?.querySelector<HTMLElement>('.t-front-clip');
  const scroller = front?.querySelector<HTMLElement>('[data-front-scroll]');
  if (!front || !data || !me || !jeepney || !clip || reducedMotion()) return;
  const ride = JSON.parse(data.textContent ?? '{}') as Ride;
  const token = ++current;
  const meStyle = me.getAttribute('style') ?? '';
  const scale = () => parseFloat(getComputedStyle(clip).getPropertyValue('--s')) || 2;
  const street = ride.floors.street ?? Object.values(ride.floors)[0];
  const curb: Pt = { x: Math.min(street.x1, Math.max(street.x0, ride.jeep.x + ride.jeep.width / 2)), y: street.y1 };
  const distance = ride.jeep.x + ride.jeep.width + 4;
  const brakeMs = Math.sqrt((2 * distance) / BRAKE) * 1000;
  const legs = legsOf(ride, curb);
  const walkMs = legs.reduce((a, l) => a + l.ms, 0);
  const runLoop = ride.run.durations.reduce((a, b) => a + b, 0) || ride.run.frames * 100;

  const finish = () => {
    me.setAttribute('style', meStyle);
    jeepney.style.removeProperty('translate');
  };

  /** Stands him with his feet at a point, facing a way, on a frame of his run. */
  const pose = (feet: Pt, facing: number, ms: number) => {
    const s = scale();
    const { w, h } = ride.size;
    // Flipped about the frame's middle, his feet are mirrored too: keep them on the point.
    const ox = facing < 0 ? w - ride.origin.x : ride.origin.x;
    me.style.setProperty('--x', String(feet.x - ox));
    me.style.setProperty('--y', String(feet.y - ride.origin.y));
    me.style.scale = facing < 0 ? '-1 1' : '';
    let t = ms % runLoop;
    let frame = 0;
    while (frame < ride.run.frames - 1 && t >= (ride.run.durations[frame] ?? 100)) t -= ride.run.durations[frame++] ?? 100;
    me.style.backgroundPosition = `${-frame * w * s}px ${-ride.run.row * h * s}px`;
  };

  /** On a phone the street is wider than its frame: keep the action in view. */
  const follow = (x: number) => {
    if (!scroller || scroller.scrollWidth <= scroller.clientWidth) return;
    scroller.scrollLeft = x * scale() - scroller.clientWidth / 2;
  };

  // Set at once, so the parked jeepney and him at his door never flash before the trip.
  me.style.visibility = 'hidden';
  me.style.animation = 'none';
  jeepney.style.translate = `${-distance * scale()}px 0`;

  let start = 0;
  const frame = (now: number) => {
    if (token !== current) return;
    // Wait for the chooser to be gone (its fade too), so the trip is seen from its start.
    if (root.classList.contains('choosing') || document.querySelector('.landing.is-leaving:not([hidden])'))
      return requestAnimationFrame(frame);
    if (!start) start = now + 150;
    const t = now - start;
    if (t < brakeMs) {
      // Braking all the way in: how far it still has to go shrinks with the square of the time left.
      const left = Math.max(0, brakeMs - Math.max(0, t)) / 1000;
      jeepney.style.translate = `${(-(BRAKE * left * left) / 2) * scale()}px 0`;
      follow(curb.x);
      return requestAnimationFrame(frame);
    }
    jeepney.style.removeProperty('translate');
    const w = t - brakeMs - PAUSE;
    if (w < 0) return requestAnimationFrame(frame);
    if (w >= walkMs) {
      finish();
      follow(ride.target.x);
      return;
    }
    me.style.visibility = '';
    let rest = w;
    for (const leg of legs) {
      if (rest > leg.ms) {
        rest -= leg.ms;
        continue;
      }
      const k = rest / leg.ms;
      const p = { x: leg.from.x + (leg.to.x - leg.from.x) * k, y: leg.from.y + (leg.to.y - leg.from.y) * k - (leg.stair ? STAIR_LIFT : 0) };
      pose(p, leg.to.x < leg.from.x ? -1 : 1, w);
      follow(p.x);
      break;
    }
    requestAnimationFrame(frame);
  };
  requestAnimationFrame(frame);
}
