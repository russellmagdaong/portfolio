/**
 * Finding a way across the floor around things that block it (platforms he has
 * not jumped onto). The floor is seen from the side, so a position is x along
 * it and y in depth; each obstacle is a box in those terms.
 *
 * With only a few boxes per scene, a visibility graph is enough: the corners
 * of every box (pushed out a little) are the places a path can turn, and the
 * shortest chain of clear straight lines from start to goal is the way.
 */

export interface Box {
  x0: number;
  x1: number;
  y0: number;
  y1: number;
}

export interface Point {
  x: number;
  y: number;
}

/** How far a path keeps from a box, in art pixels. */
const MARGIN = 3;

/** Whether the straight line a-b passes through the inside of a box (Liang-Barsky). */
function crosses(a: Point, b: Point, box: Box) {
  let t0 = 0;
  let t1 = 1;
  const dx = b.x - a.x;
  const dy = b.y - a.y;
  const edges: [number, number][] = [
    [-dx, a.x - box.x0],
    [dx, box.x1 - a.x],
    [-dy, a.y - box.y0],
    [dy, box.y1 - a.y],
  ];
  for (const [p, q] of edges) {
    if (p === 0) {
      if (q <= 0) return false;
    } else {
      const r = q / p;
      if (p < 0) t0 = Math.max(t0, r);
      else t1 = Math.min(t1, r);
      if (t0 >= t1) return false;
    }
  }
  return t1 - t0 > 1e-6;
}

const inside = (p: Point, box: Box) => p.x > box.x0 && p.x < box.x1 && p.y > box.y0 && p.y < box.y1;

/**
 * The points to walk through from `start` to `goal`, not counting the start.
 * `bounds` is the floor. A goal inside a box is moved to the nearest free spot
 * in front of or behind it.
 */
export function findPath(start: Point, goal: Point, boxes: Box[], bounds: Box): Point[] {
  const grown = boxes.map((b) => ({ x0: b.x0 - MARGIN, x1: b.x1 + MARGIN, y0: b.y0 - MARGIN, y1: b.y1 + MARGIN }));
  // A box he is standing in (on top of it, say) does not block his way off it.
  const blocking = grown.filter((b) => !inside(start, b));
  const inBounds = (p: Point) => p.x >= bounds.x0 && p.x <= bounds.x1 && p.y >= bounds.y0 && p.y <= bounds.y1;

  for (const b of blocking) {
    if (inside(goal, b)) {
      const front = { x: goal.x, y: b.y1 + 0.5 };
      const back = { x: goal.x, y: b.y0 - 0.5 };
      goal = inBounds(front) && (Math.abs(goal.y - front.y) <= Math.abs(goal.y - back.y) || !inBounds(back)) ? front : back;
    }
  }

  const clear = (a: Point, b: Point) => blocking.every((box) => !crosses(a, b, box));
  if (clear(start, goal)) return [goal];

  // Slightly outside each corner, so the lines along the edges count as clear.
  const nodes: Point[] = [start, goal];
  for (const b of blocking) {
    for (const p of [
      { x: b.x0 - 0.5, y: b.y0 - 0.5 },
      { x: b.x1 + 0.5, y: b.y0 - 0.5 },
      { x: b.x0 - 0.5, y: b.y1 + 0.5 },
      { x: b.x1 + 0.5, y: b.y1 + 0.5 },
    ]) {
      if (inBounds(p) && blocking.every((box) => !inside(p, box))) nodes.push(p);
    }
  }

  // Dijkstra over the clear lines between nodes.
  const dist = nodes.map(() => Infinity);
  const prev = nodes.map(() => -1);
  const done = nodes.map(() => false);
  dist[0] = 0;
  for (;;) {
    let i = -1;
    for (let k = 0; k < nodes.length; k++) if (!done[k] && (i < 0 || dist[k] < dist[i])) i = k;
    if (i < 0 || dist[i] === Infinity || i === 1) break;
    done[i] = true;
    for (let k = 0; k < nodes.length; k++) {
      if (done[k] || !clear(nodes[i], nodes[k])) continue;
      const d = dist[i] + Math.hypot(nodes[k].x - nodes[i].x, nodes[k].y - nodes[i].y);
      if (d < dist[k]) {
        dist[k] = d;
        prev[k] = i;
      }
    }
  }
  if (dist[1] === Infinity) return [goal]; // No way round: walk at it and stop where it blocks.
  const path: Point[] = [];
  for (let k = 1; k !== 0; k = prev[k]) path.unshift(nodes[k]);
  return path;
}
