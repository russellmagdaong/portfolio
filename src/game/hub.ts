/**
 * The hub (/map): the front view of the street, which leads to every place.
 * Russell (the side-on sprite) walks on two levels, the sidewalk and the upper
 * landings with the footbridge, joined by stairways. Clicking a destination (or
 * pressing E at its door) sends him to its door and in.
 *
 * Everything comes from art/hub.aseprite (see art/README.md, "The hub"): layers;
 * floor slices with level=street|upper; stairs:<id> with lower, upper and up=left|right;
 * spawn; building:<id> (where art/hub-objects/<id> stands, and what can be clicked);
 * door:<id> with its level; jeep (the jeepney on the road, which rides to the chooser: text or game).
 */
import { Animator, WARP_SPEED, warpInOrder, warpShadow, warpTo, warpedTo } from './sprite';
import { View, gameOn, loadImage, reducedMotion } from './view';
import { KEYS, bindKeys, isDown, onPress } from './input';
import { type Ui, clamp, contains, frameOf, inFront, loadLayers, outlineOf, sliceStarting, slicesNamed } from './layers';
import { placeTag } from './tag';
import { registerSpot, takeArrival, takeJeepney } from './spot';
import type { HubBuilding, HubConfig, Layer, Slice } from './types';

const WALK = 62;
const RUN = 132;
const DEPTH = 52;
/** Speed along a stairway, in art pixels of its length a second. */
const STAIR = 110;
/** How close to a stairway's end he must be to take it with W or S. */
const STAIR_REACH = 9;
/**
 * How far above the stairs slice's diagonal his feet are while he climbs. The diagonal runs along
 * the tread tops in art/hub.aseprite (the light top edge of each step is 1 px above it), so 1 keeps
 * his feet on the steps rather than sunk into the wall below them.
 */
const STAIR_LIFT = 1;
/** How close to a door he must be to go in with E. */
const DOOR_REACH = 8;
/** The jeepney's ride (to the chooser and back): how long it waits once he is aboard (ms), how
 * hard it speeds up or slows down (art px/s²), and how long the picture takes to fade (ms). */
const RIDE_PAUSE = 220;
const RIDE_ACCEL = 900;
const RIDE_FADE = 280;
/** The middle of the band that is always on screen (art/README.md). */
const SAFE_MIDDLE = 134;

interface Bounds {
  x0: number;
  x1: number;
  y0: number;
  y1: number;
}

interface Stair {
  id: string;
  lower: string;
  upper: string;
  bottom: { x: number; y: number };
  top: { x: number; y: number };
  length: number;
}

interface Destination extends HubBuilding {
  anim: Animator;
  /** Where the sprite's `base` stands: the middle of the bottom of its slice. */
  ax: number;
  ay: number;
  /** Where he stands to go in. */
  dx: number;
  dy: number;
  level: string;
}

type Step =
  | { kind: 'walk'; level: string; x: number; y: number }
  | { kind: 'stair'; stair: Stair; up: boolean };

interface Plan {
  steps: Step[];
  /** The arrow's spot, if the plan was a click on the ground. */
  mark?: { x: number; y: number };
  then?: () => void;
}

export async function runHub(cfg: HubConfig, ui: Ui) {
  const [images, playerImage, arrowImage, objectImages] = await Promise.all([
    loadLayers(cfg.layers),
    loadImage(cfg.player.src),
    loadImage(cfg.arrow.src),
    Promise.all(cfg.buildings.map((b) => loadImage(b.sprite.src))),
  ]);
  const view = new View(ui.stage, ui.canvas, cfg);
  const ctx = view.ctx;
  const anim = new Animator(cfg.player, playerImage);
  const marker = new Animator(cfg.arrow, arrowImage);
  const markerTag = marker.has('bob') ? 'bob' : Object.keys(cfg.arrow.tags)[0];
  bindKeys();

  // --- The street, from its slices ---
  const floors = new Map<string, Bounds>();
  for (const s of slicesNamed(cfg.slices, 'floor')) {
    floors.set(String(s.data.level ?? 'street'), { x0: s.x + 2, x1: s.x + s.width - 2, y0: s.y + 1, y1: s.y + s.height });
  }
  const floorOf = (level: string) => floors.get(level) ?? [...floors.values()][0];

  const stairs: Stair[] = sliceStarting(cfg.slices, 'stairs:').map((s) => {
    const lower = String(s.data.lower ?? 'street');
    const upper = String(s.data.upper ?? 'upper');
    const upRight = s.data.up !== 'left';
    const lo = floorOf(lower);
    const hi = floorOf(upper);
    // The slice's diagonal is the line his feet follow over the step tops.
    const bottom = { x: upRight ? s.x : s.x + s.width, y: clamp(s.y + s.height, lo.y0, lo.y1) };
    const top = { x: upRight ? s.x + s.width : s.x, y: clamp(s.y, hi.y0, hi.y1) };
    return { id: s.name.slice('stairs:'.length), lower, upper, bottom, top, length: Math.hypot(top.x - bottom.x, top.y - bottom.y) };
  });

  const destinations: Destination[] = cfg.buildings.map((b, i) => {
    const a = new Animator(b.sprite, objectImages[i]);
    a.play('idle');
    const level = String(b.door.data.level ?? 'street');
    const f = floorOf(level);
    return {
      ...b,
      anim: a,
      ax: b.slice.x + b.slice.width / 2,
      ay: b.slice.y + b.slice.height,
      dx: clamp(b.door.x + b.door.width / 2, f.x0, f.x1),
      dy: clamp(b.door.y + b.door.height, f.y0, f.y1),
      level,
    };
  });
  const home = destinations.find((d) => d.place.id === 'home');

  // The jeepney parked on the road (the `jeep` slice): clicking it, or E on the sidewalk beside
  // it, rides to the chooser (text or game). It lights up with an outline while pointed at.
  const jeep = slicesNamed(cfg.slices, 'jeep')[0];
  const jeepAt = cfg.layers.findIndex((l) => l.name === 'jeepney');
  const jeepOutlines = new Map<number, HTMLCanvasElement | null>();
  let jeepHovered = false;
  /**
   * The ride: the jeepney drives off to the right with him aboard ('leave'), then the picture fades
   * and the chooser opens ('away'); back in the game it drives in from the left and stops
   * where it was ('arrive'), and he gets off. `time` is how long the arrival takes, in seconds.
   */
  let ride: { phase: 'leave' | 'away' | 'arrive'; start: number; fade?: number; time?: number } | null = null;

  // --- Russell: outside the place he just left, or at the spawn ---
  let cameFrom: string | null = null;
  try {
    cameFrom = sessionStorage.getItem('map-from');
  } catch {}
  const outside = destinations.find((d) => d.place.id === cameFrom);
  const spawn = slicesNamed(cfg.slices, 'spawn')[0];
  let level = outside?.level ?? String(spawn?.data.level ?? 'street');
  let x = outside?.dx ?? (spawn ? spawn.x + spawn.width / 2 : floorOf(level).x0 + 20);
  let y = outside?.dy ?? (spawn ? spawn.y + spawn.height : floorOf(level).y1);
  let facing = 1;
  let turning = false;
  /** While on a stairway: which, and how far up it (0 bottom, 1 top). */
  let onStair: { stair: Stair; t: number } | null = null;
  let plan: Plan | null = null;
  let stuck = 0;
  let leaving = false;
  let hovered: Destination | null = null;

  // Warped here from a room (its Back to street button): he forms out of the sparks outside its
  // door, the warp (the sheet's `death`) played backwards until he stands whole.
  let arriving = warpedTo('street') && !reducedMotion() && anim.has('death');
  if (arriving) anim.play('death', { loop: false, order: warpInOrder(cfg.player.tags.death.frames) });
  /** The Home button (or Esc): he warps out, and his room shows him arriving the same way. */
  let departing = false;

  const go = (d: Destination) => {
    if (leaving) return;
    leaving = true;
    // The scene then starts him just inside its door (src/game/scene.ts).
    try {
      sessionStorage.setItem('entering', d.place.id);
    } catch {}
    location.href = d.place.path;
  };

  const warpGone = () => {
    if (!home) return;
    warpTo(home.place.id);
    leaving = true;
    location.href = home.place.path;
  };
  /** Home, from anywhere on the street: at its door he just goes in; elsewhere he warps. */
  const warpHome = () => {
    if (!home || leaving || ride || arriving || departing) return;
    if (doorHere() === home) return go(home);
    plan = null;
    if (ui.exit) ui.exit.disabled = true;
    if (reducedMotion() || !anim.has('death')) return warpGone();
    departing = true;
    turning = false;
    anim.play('death', { loop: false, restart: true });
  };

  const stairEnd = (s: Stair, lvl: string) => (lvl === s.upper ? s.top : s.bottom);

  /** The steps from where he is to a spot on a level, by a stairway if the level differs. */
  const route = (toLevel: string, tx: number, ty: number): Step[] => {
    const steps: Step[] = [];
    let from = level;
    let fx = x;
    if (onStair) {
      // Finish the stairway first, towards the level he is heading for.
      const up = toLevel === onStair.stair.upper;
      steps.push({ kind: 'stair', stair: onStair.stair, up });
      from = up ? onStair.stair.upper : onStair.stair.lower;
      fx = stairEnd(onStair.stair, from).x;
    }
    if (from !== toLevel) {
      const usable = stairs.filter((s) => (s.lower === from && s.upper === toLevel) || (s.upper === from && s.lower === toLevel));
      const best = usable.sort(
        (a, b) =>
          Math.abs(stairEnd(a, from).x - fx) + Math.abs(stairEnd(a, toLevel).x - tx) -
          (Math.abs(stairEnd(b, from).x - fx) + Math.abs(stairEnd(b, toLevel).x - tx)),
      )[0];
      if (best) {
        const start = stairEnd(best, from);
        steps.push({ kind: 'walk', level: from, x: start.x, y: start.y });
        steps.push({ kind: 'stair', stair: best, up: toLevel === best.upper });
      }
    }
    const f = floorOf(toLevel);
    steps.push({ kind: 'walk', level: toLevel, x: clamp(tx, f.x0, f.x1), y: clamp(ty, f.y0, f.y1) });
    return steps;
  };

  const sendTo = (d: Destination) => {
    if (ride || arriving || departing) return;
    plan = { steps: route(d.level, d.dx, d.dy), then: () => go(d) };
  };

  /** The level whose floor is nearest a point of the picture (among those under it). */
  const levelAt = (wx: number, wy: number) => {
    let best = level;
    let dist = Infinity;
    for (const [name, f] of floors) {
      if (wx < f.x0 - 4 || wx > f.x1 + 4) continue;
      const d = wy < f.y0 ? f.y0 - wy : wy > f.y1 ? wy - f.y1 : 0;
      if (d < dist) [best, dist] = [name, d];
    }
    return best;
  };

  const walkTo = (wx: number, wy: number) => {
    if (ride || arriving || departing) return;
    const lvl = levelAt(wx, wy);
    const f = floorOf(lvl);
    const spot = { x: clamp(wx, f.x0, f.x1), y: clamp(wy, f.y0, f.y1) };
    plan = { steps: route(lvl, spot.x, spot.y), mark: spot };
  };

  const doorHere = () =>
    onStair ? null : destinations.find((d) => d.level === level && Math.abs(d.dx - x) <= DOOR_REACH) ?? null;

  /** Whether he stands on the sidewalk beside the jeepney. */
  const byJeep = () => !!jeep && !onStair && level === 'street' && x >= jeep.x && x <= jeep.x + jeep.width;
  /** The jeepney's ride ends at the chooser (src/game/landing.ts): text or game. */
  const textVersion = () => document.dispatchEvent(new CustomEvent('change-ui'));
  /** He gets on and the jeepney pulls away (with reduced motion, the chooser opens at once). */
  const board = () => {
    plan = null;
    jeepHovered = false;
    ride = { phase: 'away', start: performance.now() };
    if (reducedMotion()) textVersion();
    else ride = { phase: 'leave', start: performance.now() };
  };
  // Back in the game after a ride, the jeepney brings him back.
  document.addEventListener('game-mode', (event) => {
    if (!(event as CustomEvent<boolean>).detail || ride?.phase !== 'away') return;
    if (!jeep || reducedMotion()) {
      ride = null;
      return;
    }
    // From just off the left edge of the view to its spot, slowing all the way.
    const distance = Math.max(40, jeep.x + jeep.width + 4 - camX);
    ride = { phase: 'arrive', start: performance.now(), time: Math.sqrt((2 * distance) / RIDE_ACCEL) };
  });
  /** Walks him to the curb beside the jeepney, then rides. */
  const toJeep = () => {
    if (!jeep || ride || arriving || departing) return;
    const f = floorOf('street');
    plan = { steps: route('street', clamp(jeep.x + jeep.width / 2, f.x0, f.x1), f.y1), then: board };
  };

  // --- Keys: run, Shift walks, W/S take a stairway at its end, E goes in, Esc goes home ---
  onPress((code) => {
    if (!gameOn() || leaving || ride || arriving || departing) return;
    if (KEYS.use.includes(code)) {
      const d = doorHere();
      if (d) go(d);
      else if (byJeep()) board();
    } else if (KEYS.back.includes(code)) {
      if (ui.panels.current) ui.panels.close();
      else warpHome();
    }
  });
  ui.exit?.addEventListener('click', warpHome);

  // --- Click or tap: a destination sends him in; the ground, there (with an arrow) ---
  const at = (clientX: number, clientY: number) => {
    const p = view.toArt(clientX, clientY);
    const wx = p.x + camX;
    const wy = p.y + camY;
    const dest = [...destinations].sort((a, b) => b.ay - a.ay).find((d) => contains(d.slice, wx, wy));
    const onJeep = !dest && !!jeep && contains(jeep, wx, wy);
    return { wx, wy, dest, onJeep };
  };
  let steering = false;
  ui.canvas.addEventListener('pointerdown', (event) => {
    if (event.button !== 0 || leaving || ride || arriving || departing) return;
    ui.stage.focus({ preventScroll: true });
    const hit = at(event.clientX, event.clientY);
    if (hit.dest) return sendTo(hit.dest);
    if (hit.onJeep) return toJeep();
    steering = true;
    ui.canvas.setPointerCapture(event.pointerId);
    walkTo(hit.wx, hit.wy);
  });
  ui.canvas.addEventListener('pointermove', (event) => {
    const hit = at(event.clientX, event.clientY);
    hovered = event.pointerType === 'mouse' ? hit.dest ?? null : null;
    jeepHovered = event.pointerType === 'mouse' && hit.onJeep;
    ui.canvas.style.cursor = hit.dest || hit.onJeep ? 'pointer' : '';
    if (steering) walkTo(hit.wx, hit.wy);
  });
  ui.canvas.addEventListener('pointerleave', () => {
    hovered = null;
    jeepHovered = false;
  });
  const stopSteering = () => (steering = false);
  ui.canvas.addEventListener('pointerup', stopSteering);
  ui.canvas.addEventListener('pointercancel', stopSteering);
  ui.label.addEventListener('click', () => {
    const d = hovered ?? doorHere();
    if (d) sendTo(d);
    else if (jeepHovered || byJeep()) toJeep();
  });
  ui.goButtons.forEach((button) =>
    button.addEventListener('click', () => {
      const d = destinations.find((x) => x.place.id === button.dataset.go);
      if (d) {
        ui.stage.focus({ preventScroll: true });
        sendTo(d);
      }
    }),
  );

  let camX = clamp(x - view.width / 2, 0, Math.max(0, cfg.width - view.width));
  let camY = 0;

  // --- Where he is, for the text page: the building whose door he is by (src/game/spot.ts) ---
  const spotHere = () => {
    if (onStair) return null;
    const by = destinations
      .filter((d) => d.level === level && Math.abs(d.dx - x) < 40)
      .sort((a, b) => Math.abs(a.dx - x) - Math.abs(b.dx - x))[0];
    return by?.place.id ?? null;
  };
  /** Stands him at a building's door. */
  const standAt = (id: string) => {
    const d = destinations.find((dest) => dest.place.id === id);
    if (!d) return;
    [level, x, y, onStair, plan] = [d.level, d.dx, d.dy, null, null];
    camX = clamp(x - view.width / 2, 0, Math.max(0, cfg.width - view.width));
  };
  const arrival = takeArrival('street');
  if (arrival) standAt(arrival);
  registerSpot(() => ({ place: 'street', id: spotHere() }), standAt);

  // Sent by jeepney (src/game/main.ts: back to the game, not for the first time this session): he
  // rides in on it from the left, the picture coming up from black, and gets off at the curb.
  const byJeepney = () => {
    if (!jeep) return;
    const f = floorOf('street');
    // Off at its front end, on the sidewalk, rather than behind it where only his head would show.
    [level, x, y, onStair, plan] = ['street', clamp(jeep.x + jeep.width + 8, f.x0, f.x1), f.y1, null, null];
    facing = 1;
    camX = clamp(x - view.width / 2, 0, Math.max(0, cfg.width - view.width));
    if (reducedMotion()) {
      ride = null;
      return;
    }
    const distance = Math.max(40, jeep.x + jeep.width + 4 - camX);
    ride = { phase: 'arrive', start: performance.now(), time: Math.sqrt((2 * distance) / RIDE_ACCEL) };
  };
  if (takeJeepney()) byJeepney();
  document.addEventListener('jeep-arrive', () => {
    takeJeepney();
    byJeepney();
  });

  // --- Each frame ---
  const update = (dt: number) => {
    // Aboard the jeepney, or still forming after a warp, he does not move.
    const still = !!ride || arriving || departing;
    const dx = still ? 0 : (isDown(KEYS.right) ? 1 : 0) - (isDown(KEYS.left) ? 1 : 0);
    const dy = still ? 0 : (isDown(KEYS.down) ? 1 : 0) - (isDown(KEYS.up) ? 1 : 0);
    const run = !isDown(KEYS.run);
    if (dx || dy) plan = null;

    const fromX = x;
    const fromY = y;

    // Keys at a stairway's end step onto it: W at the bottom, S at the top.
    if (!onStair && !plan && dy) {
      const s = stairs.find((st) =>
        dy < 0
          ? level === st.lower && Math.abs(x - st.bottom.x) <= STAIR_REACH
          : level === st.upper && Math.abs(x - st.top.x) <= STAIR_REACH,
      );
      if (s) onStair = { stair: s, t: dy < 0 ? 0 : 1 };
    }

    if (onStair) {
      // Along the stairway. Up: W, or running towards its top end. Down: S, or away.
      const s = onStair.stair;
      let along = 0;
      const step = plan?.steps[0];
      if (step?.kind === 'stair' && step.stair === s) along = step.up ? 1 : -1;
      else if (dy) along = -dy;
      else if (dx) along = Math.sign(s.top.x - s.bottom.x) === dx ? 1 : -1;
      // Stairs are always walked, up and down: walking pace, with the walk.
      onStair.t = clamp(onStair.t + (along * STAIR * 0.6 * dt) / s.length, 0, 1);
      x = s.bottom.x + (s.top.x - s.bottom.x) * onStair.t;
      y = s.bottom.y + (s.top.y - s.bottom.y) * onStair.t;
      if (along !== 0 && (onStair.t === 0 || onStair.t === 1)) {
        level = onStair.t === 1 ? s.upper : s.lower;
        onStair = null;
        if (step?.kind === 'stair') plan!.steps.shift();
      }
    } else {
      const f = floorOf(level);
      let stepX = dx * (run ? RUN : WALK) * dt;
      let stepY = dy * DEPTH * (run ? 1.5 : 1) * dt;
      const step = plan?.steps[0];
      if (step?.kind === 'stair') {
        onStair = { stair: step.stair, t: step.up ? 0 : 1 };
      } else if (step?.kind === 'walk') {
        const ex = step.x - x;
        const ey = step.y - y;
        if (Math.abs(ex) < 0.75 && Math.abs(ey) < 0.75) {
          plan!.steps.shift();
        } else {
          const sx = (run ? RUN : WALK) * dt;
          const sy = DEPTH * 1.5 * dt;
          const frames = Math.max(Math.abs(ex) / sx, Math.abs(ey) / sy);
          const t = frames > 1 ? 1 / frames : 1;
          stepX = ex * t;
          stepY = ey * t;
        }
      }
      x = clamp(x + stepX, f.x0, f.x1);
      y = clamp(y + stepY, f.y0, f.y1);
    }

    if (plan && !plan.steps.length) {
      const done = plan;
      plan = null;
      done.then?.();
    }

    const movedX = x - fromX;
    const moving = Math.abs(movedX) > 0.001 || Math.abs(y - fromY) > 0.001;
    if (plan && !moving) {
      stuck += dt;
      if (stuck > 0.5) plan = null;
    } else stuck = 0;

    // Facing and the moves, as in the scenes.
    // A stairway, up or down, is always a walk.
    const gait = !moving ? 'idle' : run && onStair === null ? 'run' : 'walk';
    const wantFacing = Math.abs(movedX) > 0.001 ? Math.sign(movedX) : facing;
    if (wantFacing !== facing) {
      facing = wantFacing;
      anim.play(`${gait}_turn`, { loop: false, restart: true });
      turning = anim.tag === `${gait}_turn`;
    }
    if (arriving) {
      // The warp, backwards; whole again, he is free to go.
      anim.update(dt * 1000 * WARP_SPEED);
      if (anim.done) {
        arriving = false;
        anim.play('idle');
      }
    } else if (departing) {
      // The warp out, then his room.
      anim.update(dt * 1000 * WARP_SPEED);
      if (anim.done) warpGone();
    } else {
      if (turning && !anim.done) {
        // Let the turn finish.
      } else {
        turning = false;
        if (gait !== 'idle') anim.play(gait);
        else if (anim.tag === 'run') anim.play('run_to_idle', { loop: false });
        else if (anim.tag !== 'run_to_idle' || anim.done) anim.play('idle');
      }
      anim.update(dt * 1000);
    }

    const here = doorHere();
    for (const d of destinations) d.anim.play(d === hovered || d === here ? 'hover' : 'idle');
    for (const d of destinations) d.anim.update(dt * 1000);

    const want = x + facing * 24 - view.width / 2;
    camX += (want - camX) * (1 - Math.exp(-dt * 4));
    camX = cfg.width <= view.width ? (cfg.width - view.width) / 2 : clamp(camX, 0, cfg.width - view.width);
    camY = cfg.height <= view.height ? 0 : clamp(Math.round(SAFE_MIDDLE - view.height / 2), 0, cfg.height - view.height);
  };

  const drawLayer = (layer: Layer, image: HTMLImageElement, cx: number, now: number, shift = 0) => {
    const frame = frameOf(layer, now);
    ctx.drawImage(
      image, frame * layer.width, 0, layer.width, layer.height,
      Math.round(layer.x - cx * layer.speed + shift), Math.round(layer.y - camY), layer.width, layer.height,
    );
  };

  /**
   * Where the jeepney is on its ride (how far right of its spot, in art px), how fast it goes, and
   * how dark the picture is. Moves the ride on: off the view, the fade; faded, the chooser;
   * stopped again, he gets off.
   */
  const riding = (now: number, cx: number) => {
    if (!ride || !jeep) return { shift: 0, speed: 0, dark: 0 };
    if (ride.phase === 'leave') {
      const s = Math.max(0, now - ride.start - RIDE_PAUSE) / 1000;
      const shift = (RIDE_ACCEL * s * s) / 2;
      if (ride.fade === undefined && jeep.x + shift - cx > view.width) ride.fade = now;
      const dark = ride.fade === undefined ? 0 : clamp((now - ride.fade) / RIDE_FADE, 0, 1);
      if (dark === 1) {
        ride = { phase: 'away', start: now };
        textVersion();
      }
      return { shift, speed: RIDE_ACCEL * s, dark };
    }
    if (ride.phase === 'arrive') {
      const s = (now - ride.start) / 1000;
      const left = Math.max(0, (ride.time ?? 0) - s);
      const dark = 1 - clamp((now - ride.start) / RIDE_FADE, 0, 1);
      // Stopped, it waits a moment before he steps off.
      if (left === 0 && now - ride.start > (ride.time ?? 0) * 1000 + RIDE_PAUSE) ride = null;
      return { shift: -(RIDE_ACCEL * left * left) / 2, speed: RIDE_ACCEL * left, dark };
    }
    return { shift: view.width * 2, speed: 0, dark: 1 };
  };

  /** Speed lines trailing the jeepney, longer the faster it goes. */
  const streaks = (back: number, speed: number) => {
    if (!jeep || speed < 60) return;
    ctx.fillStyle = 'rgba(214, 222, 255, 0.55)';
    [9, 18, 27, 36].forEach((dy, i) => {
      const len = Math.round(Math.min(48, speed * (0.05 + i * 0.012)));
      ctx.fillRect(Math.round(back - len - 2 - i * 3), jeep.y + dy - camY, len, 1);
    });
  };

  const shadow = (sx: number, sy: number, left = 1) => {
    if (left <= 0) return;
    ctx.fillStyle = `rgba(13, 11, 26, ${(0.55 * left).toFixed(2)})`;
    ctx.fillRect(Math.round(sx - 9), Math.round(sy - 1), 18, 2);
    ctx.fillRect(Math.round(sx - 7), Math.round(sy - 2), 14, 1);
    ctx.fillRect(Math.round(sx - 7), Math.round(sy + 1), 14, 1);
  };

  const draw = (now: number, dt: number) => {
    const cx = Math.round(camX);
    ctx.fillStyle = '#0d0b1a';
    ctx.fillRect(0, 0, view.width, view.height);
    // The destinations stand in front of the `buildings` layer, behind the street and what is on it.
    // The stair railings (`stair` layers) go in front of him while he is on a stairway: he climbs
    // behind the handrail.
    const at = { y, onStair: onStair !== null };
    const trip = riding(now, cx);
    const shiftOf = (i: number) => (i === jeepAt ? trip.shift : 0);
    cfg.layers.forEach((layer, i) => {
      if (inFront(layer, at)) return;
      drawLayer(layer, images[i], cx, now, shiftOf(i));
      if (layer.name === 'buildings') destinations.forEach((d) => d.anim.draw(ctx, d.ax - cx, d.ay - camY));
    });
    if (!cfg.layers.some((l) => l.name === 'buildings')) destinations.forEach((d) => d.anim.draw(ctx, d.ax - cx, d.ay - camY));
    // On a stairway his feet follow the tread tops.
    const feetY = onStair ? y - STAIR_LIFT : y;
    // While he rides he is in the jeepney, so he is not drawn.
    if (!ride) shadow(x - cx, feetY - camY, arriving || departing ? warpShadow(anim.frame) : 1);
    if (plan?.mark) {
      if (reducedMotion()) marker.hold(markerTag, 0);
      else marker.play(markerTag);
      marker.update(dt * 1000);
      marker.draw(ctx, plan.mark.x - cx, plan.mark.y - camY);
    }
    const flip = turning ? facing > 0 : facing < 0;
    if (!ride) anim.draw(ctx, x - cx, feetY - camY, flip);
    cfg.layers.forEach((layer, i) => inFront(layer, at) && drawLayer(layer, images[i], cx, now, shiftOf(i)));
    if (jeep && ride) streaks(jeep.x + trip.shift - cx, trip.speed);
    if (trip.dark > 0) {
      ctx.fillStyle = `rgba(13, 11, 26, ${trip.dark.toFixed(3)})`;
      ctx.fillRect(0, 0, view.width, view.height);
    }
    // The jeepney's outline (it bobs, so each frame has its own). Nothing in front of him covers
    // the road, so it is drawn last.
    const jeepLit = !!jeep && jeepAt >= 0 && !ride && !hovered && (jeepHovered || byJeep());
    if (jeepLit) {
      const layer = cfg.layers[jeepAt];
      const f = frameOf(layer, now);
      if (!jeepOutlines.has(f)) jeepOutlines.set(f, outlineOf(jeep, layer, images[jeepAt], f));
      const o = jeepOutlines.get(f);
      if (o) ctx.drawImage(o, jeep.x - 1 - cx, jeep.y - 1 - camY);
    }

    // The name over the destination pointed at, or the one he stands at.
    const here = doorHere();
    const shown = hovered ?? here;
    // The jeepney's tag only while it is pointed at: beside it, the prompt over his head says E
    // (a tag over the jeepney would cover him, standing behind it).
    ui.label.hidden = !(shown || (jeepLit && jeepHovered)) || leaving || !!ride || departing;
    if (!shown && jeepLit && jeepHovered) {
      const key = 'Click to ride';
      const html = `<strong>Jeepney</strong> <span>Change UI: text or game</span> <em>${key}</em>`;
      if (ui.label.innerHTML !== html) ui.label.innerHTML = html;
      const p = view.toStage(jeep.x + jeep.width / 2 - cx, jeep.y - camY - 2);
      placeTag(ui.label, p.x, p.y);
    }
    if (shown) {
      const key = ui.touch() ? 'Tap to go in' : shown === here && !hovered ? '<kbd>E</kbd> Go in' : 'Click to go in';
      const html = `<strong>${shown.place.title}</strong> <span>${shown.place.label}</span> <em>${key}</em>`;
      if (ui.label.innerHTML !== html) ui.label.innerHTML = html;
      const p = view.toStage(shown.ax - cx, shown.slice.y - camY - 2);
      placeTag(ui.label, p.x, p.y);
    }

    // At a stairway's end, the key that takes it.
    const stair = onStair
      ? null
      : stairs.find((s) =>
          (level === s.lower && Math.abs(x - s.bottom.x) <= STAIR_REACH) || (level === s.upper && Math.abs(x - s.top.x) <= STAIR_REACH),
        );
    const jeepKey = !stair && byJeep();
    ui.prompt.hidden = !(stair || jeepKey) || ui.touch() || !!ride || departing;
    if (stair || jeepKey) {
      const up = stair && level === stair.lower;
      const html = !stair ? '<kbd>E</kbd> Ride the jeepney: change UI' : up ? '<kbd>W</kbd> Up the stairs' : '<kbd>S</kbd> Down the stairs';
      if (ui.prompt.innerHTML !== html) ui.prompt.innerHTML = html;
      const p = view.toStage(x - cx, y - camY - 40);
      placeTag(ui.prompt, p.x, p.y);
    }
  };

  (window as unknown as { gameState: () => object }).gameState = () => ({
    x: Math.round(x), y: Math.round(y), level, onStair: onStair ? { id: onStair.stair.id, t: onStair.t } : null,
    plan: plan ? plan.steps.map((s) => s.kind) : null, ride: ride?.phase ?? null, view: [view.width, view.height], camX: Math.round(camX), camY,
  });

  let last = performance.now();
  const frame = (now: number) => {
    const dt = Math.min(0.05, (now - last) / 1000);
    last = now;
    if (gameOn() && !leaving) {
      update(dt);
      draw(now, dt);
    }
    requestAnimationFrame(frame);
  };
  requestAnimationFrame(frame);
}
