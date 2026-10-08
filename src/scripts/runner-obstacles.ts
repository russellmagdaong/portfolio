// The things the runner (src/components/Runner.astro) has to get past: what kinds there are,
// which of them turn up at a given score, how each is drawn, and what counts as hitting one.

type Kind = 'spike' | 'crate' | 'pylon' | 'drone' | 'gate';

export type Obstacle = {
  kind: Kind;
  // Left edge, in pixels from the left of the strip.
  x: number;
  width: number;
  height: number;
  // How far its underside is off the ground. Drones fly and gates hang; the rest stand on it.
  altitude: number;
  // A random number of its own, so that two of a kind do not blink and bob in step.
  seed: number;
};

// The site's colours, read from the stylesheet by the game.
export type Theme = { cyan: string; magenta: string; acid: string; violet: string; deck: string };

type Shape = Omit<Obstacle, 'x' | 'seed'> & { offset: number };
const between = (random: () => number, low: number, high: number) => Math.round(low + random() * (high - low));

// A row of spikes standing shoulder to shoulder. The more there are, the lower they are kept,
// because he has to stay above all of them for longer.
const SPIKE_WIDTH = 16;
const spikes =
  (count: number, low: number, high: number) =>
  (random: () => number): Shape[] =>
    Array.from({ length: count }, (_, i) => ({
      kind: 'spike',
      offset: i * SPIKE_WIDTH,
      width: SPIKE_WIDTH,
      height: between(random, low, high),
      altitude: 0,
    }));

const crate = (random: () => number): Shape[] => [
  { kind: 'crate', offset: 0, width: between(random, 24, 34), height: between(random, 24, 38), altitude: 0 },
];

const pylon = (random: () => number): Shape[] => [
  { kind: 'pylon', offset: 0, width: between(random, 12, 14), height: between(random, 40, 48), altitude: 0 },
];

// Flies clear of his head, so the way past it is to stay on the ground: jumping is what hits it.
const drone = (random: () => number): Shape[] => [
  { kind: 'drone', offset: 0, width: 36, height: 16, altitude: between(random, 84, 94) },
];

// A barrier that hangs from the top of the strip to below head height. There is no jumping it:
// the only way past is to slide underneath. It is drawn far taller than the strip, so its top
// is always out of sight.
const gate = (random: () => number): Shape[] => [
  { kind: 'gate', offset: 0, width: between(random, 16, 20), height: 400, altitude: between(random, 44, 50) },
];

// What can turn up, how likely each is next to the others, and the score it first appears at.
// The game opens with the plain ones and adds the harder ones as it goes on.
const MENU = [
  { from: 0, weight: 3, make: spikes(1, 22, 34) },
  { from: 0, weight: 3, make: crate },
  { from: 150, weight: 3, make: spikes(2, 20, 30) },
  { from: 150, weight: 2, make: pylon },
  { from: 250, weight: 3, make: gate },
  { from: 400, weight: 2, make: spikes(3, 18, 26) },
  { from: 400, weight: 2, make: drone },
];

/** Picks the next obstacle for this score and places it at `x`. A row of spikes comes back as several. */
export function spawn(score: number, x: number, random: () => number = Math.random): Obstacle[] {
  const open = MENU.filter((entry) => score >= entry.from);
  let pick = random() * open.reduce((sum, entry) => sum + entry.weight, 0);
  const chosen = open.find((entry) => (pick -= entry.weight) < 0) ?? open[0];
  return chosen.make(random).map(({ offset, ...shape }) => ({ ...shape, x: x + offset, seed: random() }));
}

// How close he can come without it counting: a little at an obstacle's sides, and a little
// above and below it.
const EDGE_PX = 2;
const SLACK_PX = 4;

/**
 * Whether his body touches an obstacle. His body is a box from `left` to `right`, `bodyHeight`
 * tall, with its feet `lift` pixels off the ground.
 */
export function hits(obstacle: Obstacle, left: number, right: number, lift: number, bodyHeight: number): boolean {
  const from = Math.max(left, obstacle.x + EDGE_PX);
  const to = Math.min(right, obstacle.x + obstacle.width - EDGE_PX);
  if (from >= to) return false;
  // He is passing underneath it.
  if (lift + bodyHeight <= obstacle.altitude + SLACK_PX) return false;

  let top = obstacle.altitude + obstacle.height;
  if (obstacle.kind === 'spike') {
    // A spike is a triangle, so it is only as tall as its slope is at the part he is over.
    const middle = obstacle.x + obstacle.width / 2;
    const nearest = Math.max(from, Math.min(to, middle));
    top = obstacle.height * (1 - Math.abs(nearest - middle) / (obstacle.width / 2));
  }
  return lift < top - SLACK_PX;
}

const GLOW_PX = 10;

// Fills the current path the way the site's panels are filled: dark, with a wash of its own colour.
const fillTinted = (ctx: CanvasRenderingContext2D, colour: string, dark: string, strength: number) => {
  ctx.fillStyle = dark;
  ctx.fill();
  ctx.fillStyle = colour;
  ctx.globalAlpha = strength;
  ctx.fill();
  ctx.globalAlpha = 1;
};

type Painter = (ctx: CanvasRenderingContext2D, obstacle: Obstacle, time: number, theme: Theme) => void;

// Each painter draws with the obstacle's bottom-left corner at 0,0 and up as negative y.
const PAINT: Record<Kind, Painter> = {
  // A neon triangle: lit edges, a dim fill, and a brighter core up the middle.
  spike(ctx, { width, height }, _time, theme) {
    ctx.beginPath();
    ctx.moveTo(1, 0);
    ctx.lineTo(width / 2, -height);
    ctx.lineTo(width - 1, 0);
    ctx.closePath();
    fillTinted(ctx, theme.magenta, theme.deck, 0.45);
    ctx.strokeStyle = theme.magenta;
    ctx.shadowColor = theme.magenta;
    ctx.shadowBlur = GLOW_PX;
    ctx.stroke();

    ctx.fillStyle = theme.magenta;
    ctx.beginPath();
    ctx.moveTo(width / 2 - 2, -2);
    ctx.lineTo(width / 2, -height * 0.6);
    ctx.lineTo(width / 2 + 2, -2);
    ctx.closePath();
    ctx.fill();
  },

  // A cargo crate with the same sliced corners as the site's panels, braced on the inside.
  crate(ctx, { width, height }, _time, theme) {
    const cut = 7;
    ctx.beginPath();
    ctx.moveTo(1, -height + 1);
    ctx.lineTo(width - cut, -height + 1);
    ctx.lineTo(width - 1, -height + cut);
    ctx.lineTo(width - 1, -1);
    ctx.lineTo(cut, -1);
    ctx.lineTo(1, -cut);
    ctx.closePath();
    fillTinted(ctx, theme.acid, theme.deck, 0.14);
    ctx.strokeStyle = theme.acid;
    ctx.shadowColor = theme.acid;
    ctx.shadowBlur = GLOW_PX;
    ctx.stroke();

    ctx.shadowBlur = 0;
    ctx.lineWidth = 1;
    ctx.globalAlpha = 0.6;
    ctx.strokeRect(5.5, -height + 5.5, width - 11, height - 11);
    ctx.beginPath();
    ctx.moveTo(5.5, -5.5);
    ctx.lineTo(width - 5.5, -height + 5.5);
    ctx.stroke();
    ctx.globalAlpha = 1;
    // A warning light in the corner.
    ctx.fillStyle = theme.acid;
    ctx.fillRect(width - 10, -10, 4, 4);
  },

  // A tall barrier post in hazard stripes, with a lit cap.
  pylon(ctx, { width, height }, _time, theme) {
    ctx.fillStyle = theme.deck;
    ctx.fillRect(1, -height, width - 2, height);

    ctx.save();
    ctx.beginPath();
    ctx.rect(1, -height, width - 2, height);
    ctx.clip();
    ctx.fillStyle = theme.cyan;
    ctx.globalAlpha = 0.85;
    for (let y = 0; y > -height - width; y -= 12) {
      ctx.beginPath();
      ctx.moveTo(0, y);
      ctx.lineTo(width, y - width);
      ctx.lineTo(width, y - width + 6);
      ctx.lineTo(0, y + 6);
      ctx.closePath();
      ctx.fill();
    }
    ctx.restore();

    ctx.strokeStyle = theme.cyan;
    ctx.shadowColor = theme.cyan;
    ctx.shadowBlur = GLOW_PX;
    ctx.strokeRect(1, -height, width - 2, height);
    ctx.fillStyle = theme.cyan;
    ctx.fillRect(-2, -height - 4, width + 4, 4);
  },

  // A hovering drone: it bobs, its rotors flicker and its eye blinks.
  drone(ctx, { width, height, seed }, time, theme) {
    ctx.translate(0, Math.round(Math.sin(time * 6 + seed * 6.28) * 2));
    const nose = 7;
    ctx.beginPath();
    ctx.moveTo(1, -height / 2);
    ctx.lineTo(nose, -height + 1);
    ctx.lineTo(width - nose, -height + 1);
    ctx.lineTo(width - 1, -height / 2);
    ctx.lineTo(width - nose, -1);
    ctx.lineTo(nose, -1);
    ctx.closePath();
    fillTinted(ctx, theme.violet, theme.deck, 0.25);
    ctx.strokeStyle = theme.violet;
    ctx.shadowColor = theme.violet;
    ctx.shadowBlur = GLOW_PX;
    ctx.stroke();

    // Two rotors on stalks. Their width snaps between wide and narrow, which reads as spinning.
    ctx.fillStyle = theme.violet;
    const span = Math.floor(time * 24 + seed * 8) % 2 ? 14 : 6;
    for (const hub of [nose + 3, width - nose - 3]) {
      ctx.fillRect(hub - 1, -height - 4, 2, 4);
      ctx.fillRect(hub - span / 2, -height - 6, span, 2);
    }

    // It faces the way it is flying: left.
    if (Math.floor(time * 3 + seed * 4) % 4 !== 0) {
      ctx.fillStyle = theme.acid;
      ctx.shadowColor = theme.acid;
      ctx.fillRect(nose, -height / 2 - 2, 6, 4);
    }
  },

  // A hazard-striped post let down from above, in the drone's colour: both mean "keep low".
  // Its foot is lit, and blinks so that it stands out against the posts that stand on the ground.
  gate(ctx, { width, height, seed }, time, theme) {
    ctx.fillStyle = theme.deck;
    ctx.fillRect(1, -height, width - 2, height);

    ctx.save();
    ctx.beginPath();
    ctx.rect(1, -height, width - 2, height);
    ctx.clip();
    ctx.fillStyle = theme.violet;
    ctx.globalAlpha = 0.85;
    for (let y = 0; y > -height - width; y -= 12) {
      ctx.beginPath();
      ctx.moveTo(0, y - width);
      ctx.lineTo(width, y);
      ctx.lineTo(width, y + 6);
      ctx.lineTo(0, y - width + 6);
      ctx.closePath();
      ctx.fill();
    }
    ctx.restore();

    ctx.strokeStyle = theme.violet;
    ctx.shadowColor = theme.violet;
    ctx.shadowBlur = GLOW_PX;
    ctx.strokeRect(1, -height, width - 2, height);
    const lit = Math.floor(time * 4 + seed * 4) % 2 === 0;
    ctx.fillStyle = lit ? theme.acid : theme.violet;
    ctx.shadowColor = ctx.fillStyle;
    ctx.fillRect(-3, -5, width + 6, 5);
  },
};

/** Draws one obstacle. `ground` is the y of the ground line, `time` is in seconds. */
export function draw(ctx: CanvasRenderingContext2D, obstacle: Obstacle, ground: number, time: number, theme: Theme) {
  ctx.save();
  // Whole pixels, so that the thin lines stay sharp as it moves.
  ctx.translate(Math.round(obstacle.x), ground - obstacle.altitude);
  ctx.lineWidth = 2;
  PAINT[obstacle.kind](ctx, obstacle, time, theme);
  ctx.restore();
}
