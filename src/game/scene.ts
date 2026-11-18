/**
 * A side-on scene: Russell runs along the floor (and up and down it, in depth),
 * jumps onto things, reads what is on the walls, and uses the few things that
 * open (arcade cabinets, the mirror, the post office counter).
 *
 * Everything about the place comes from its Aseprite file (art/scenes/<id>.aseprite):
 * layers and their speeds, and the slices floor, spawn, exit, platform,
 * object:<id> (opens a panel; a <template data-peek="<id>"> on the page is the window shown while
 * the mouse points at it), show:<id> (the page's content on the wall) and
 * prop:<id> (a card when pointed at or reached). See art/README.md.
 */
import { Animator, WARP_SPEED, warpInOrder, warpShadow, warpTo, warpedTo } from './sprite';
import { View, gameOn, loadImage, reducedMotion } from './view';
import { KEYS, bindKeys, isDown, onPress } from './input';
import { type Ui, clamp, contains, drawLayers, loadLayers, outlineOf, outlineOfCell, sliceStarting, slicesNamed } from './layers';
import { findPath, type Point } from './path';
import { World } from './world';
import { placeTag } from './tag';
import { registerSpot, takeArrival } from './spot';
import type { SceneConfig, Slice } from './types';

// Speeds in art pixels a second. He is 32 px tall. Running is the default; Shift walks.
const WALK = 62;
const RUN = 132;
const DEPTH = 52;
const GRAVITY = 620;
const JUMP = 205;
/** How far to either side of a thing he can still use it. */
const REACH = 10;
/** How far in front of the back wall (the floor slice's top edge) his feet must stay, in art pixels. */
const BACK_GAP = 8;
/** How close to the door (the middle of the exit slice) the Exit button shows and E goes out. */
const EXIT_REACH = 44;
/** The Exit button gets him out within about this many seconds. */
const EXIT_SECONDS = 1.6;
/** The middle of the band that is always on screen (art/README.md). */
const SAFE_MIDDLE = 134;

interface Thing {
  id: string;
  slice: Slice;
  opens: string;
  prompt: string;
  /** The window shown over it while the mouse points at it (<template data-peek="<opens>">), if the page has one. */
  peek: HTMLTemplateElement | null;
}

interface Prop {
  slice: Slice;
  tip: HTMLElement | null;
  /** Its own sprite (art/objects/<scene>/<id>.aseprite), if it has one. */
  piece?: Piece;
  /** Without one: a 1 px outline round what is drawn of it on the `props` layer, shown while it is pointed at. */
  outline: HTMLCanvasElement | null;
}

/** An interactable drawn from its own file, standing on the middle of its slice's bottom edge. */
interface Piece {
  anim: Animator;
  image: HTMLImageElement;
  ax: number;
  ay: number;
  /**
   * It is drawn in front of him while his feet are behind this line: the bottom of its slice (where
   * it stands), or the slice's `sort=<y>`. Things on the wall stand above the floor, so he is always
   * in front of them.
   */
  line: number;
  /** Its outlines, one per tag and frame, made when first needed. */
  outlines: Map<string, HTMLCanvasElement | null>;
}

interface Target {
  /** The points still to walk through; the last is where he is going. */
  path: Point[];
  then?: () => void;
  exit?: boolean;
  /** Overrides the speed (the Exit button hurries). */
  speed?: number;
  /** Shows the arrow over where he is going. */
  marked: boolean;
}

export async function runScene(cfg: SceneConfig, ui: Ui) {
  const [images, playerImage, arrowImage, objectImages] = await Promise.all([
    loadLayers(cfg.layers),
    loadImage(cfg.player.src),
    loadImage(cfg.arrow.src),
    Promise.all(cfg.objects.map((o) => loadImage(o.sprite.src))),
  ]);
  const view = new View(ui.stage, ui.canvas, cfg);
  const ctx = view.ctx;
  // He (and whatever stands in front of him) is drawn on a second, see-through canvas above the
  // page's content on the walls (.world), so the boards' text never covers him when he passes or
  // jumps in front of them. It takes no clicks: they go to the boards and the room below.
  const front = document.createElement('canvas');
  front.className = 'stage-front';
  front.setAttribute('aria-hidden', 'true');
  ui.world.after(front);
  const fctx = front.getContext('2d')!;
  const fitFront = () => {
    front.width = ui.canvas.width;
    front.height = ui.canvas.height;
    fctx.imageSmoothingEnabled = false;
    const { width, height, left, top } = ui.canvas.style;
    Object.assign(front.style, { width, height, left, top });
  };
  const resized = view.onResize;
  view.onResize = () => {
    resized?.();
    fitFront();
  };
  fitFront();
  const anim = new Animator(cfg.player, playerImage);
  // The marker over where he is going: the `bob` tag of art/arrow.aseprite, standing on its `base`.
  const marker = new Animator(cfg.arrow, arrowImage);
  const markerTag = marker.has('bob') ? 'bob' : Object.keys(cfg.arrow.tags)[0];
  bindKeys();

  // --- The place, from its slices ---
  const floor: Slice = slicesNamed(cfg.slices, 'floor')[0] ?? {
    name: 'floor', x: 0, y: cfg.height - 94, width: cfg.width, height: 48, data: {},
  };
  // He keeps off the strip of floor where it meets the back wall, so he never looks as if he stands
  // inside the wall.
  const bounds = { x0: floor.x + 4, x1: floor.x + floor.width - 4, y0: floor.y + BACK_GAP, y1: floor.y + floor.height };
  const exits = slicesNamed(cfg.slices, 'exit');
  // The glass of the mirror at home (the `reflect` slice): he shows in it.
  const glass = slicesNamed(cfg.slices, 'reflect')[0];
  // A platform slice covers a thing's front face; `depth` is how far back it reaches.
  const platforms = slicesNamed(cfg.slices, 'platform').map((s) => {
    const front = s.y + s.height;
    return { x0: s.x, x1: s.x + s.width, height: s.height, back: front - Number(s.data.depth ?? 10), front };
  });
  // The interactables that have their own sprite, by slice name.
  const pieces = new Map<string, Piece>();
  cfg.objects.forEach((o, i) => {
    const s = cfg.slices.find((sl) => sl.name === o.slice);
    if (!s) return;
    const anim = new Animator(o.sprite, objectImages[i]);
    anim.play('idle');
    const line = typeof s.data.sort === 'number' ? s.data.sort : s.y + s.height;
    pieces.set(o.slice, { anim, image: objectImages[i], ax: s.x + Math.floor(s.width / 2), ay: s.y + s.height, line, outlines: new Map() });
  });
  const things: Thing[] = sliceStarting(cfg.slices, 'object:').map((s) => {
    const id = s.name.slice('object:'.length);
    const opens = String(s.data.opens ?? id);
    const peek = document.querySelector<HTMLTemplateElement>(`template[data-peek="${CSS.escape(opens)}"]`);
    return { id, slice: s, opens, prompt: String(s.data.prompt ?? 'Open'), peek };
  });
  things.forEach((t) => {
    if (!ui.panels.has(t.opens)) console.warn(`object:${t.id} opens "${t.opens}", which is not a panel on this page`);
  });
  // The windows' pictures load now, so a window never opens on an empty screen.
  things.forEach((t) => t.peek?.content.querySelectorAll('img').forEach((img) => (new Image().src = img.getAttribute('src') ?? '')));
  const props: Prop[] = sliceStarting(cfg.slices, 'prop:').map((s) => {
    const id = String(s.data.tip ?? s.name.slice('prop:'.length));
    const tip = document.querySelector<HTMLElement>(`[data-tip="${CSS.escape(id)}"]`);
    if (!tip) console.warn(`${s.name} shows tip "${id}", which is not a <Tip> on this page`);
    const piece = pieces.get(s.name);
    if (piece) return { slice: s, tip, piece, outline: null };
    const at = cfg.layers.findIndex((l) => l.name === 'props');
    return { slice: s, tip, outline: outlineOf(s, cfg.layers[at], images[at]) };
  });
  const world = new World(ui.world, sliceStarting(cfg.slices, 'show:'));

  const supportAt = (x: number, y: number) =>
    platforms.reduce((top, p) => (x >= p.x0 && x < p.x1 && y > p.back && y <= p.front ? Math.max(top, p.height) : top), 0);
  const blocked = (x: number, y: number, z: number) => supportAt(x, y) > z + 1;
  // The depth he sorts at against `sort` layers and pieces. Up on a thing (the bed, the couch) he is
  // inside its footprint, so he sorts at its front edge: its posts and ends go behind him, not over him.
  const sortY = (x: number, y: number) =>
    platforms.reduce((at, p) => (x >= p.x0 && x < p.x1 && y > p.back && y <= p.front ? Math.max(at, p.front) : at), y);

  // --- Russell ---
  const spawn = slicesNamed(cfg.slices, 'spawn')[0];
  let x = clamp(spawn ? spawn.x + spawn.width / 2 : bounds.x0 + 30, bounds.x0, bounds.x1);
  let y = clamp(spawn ? spawn.y + spawn.height : bounds.y0 + 20, bounds.y0, bounds.y1);
  let z = 0;
  let vz = 0;
  let facing = 1;
  // Walking in from the street, he comes in through the door: just inside the exit, facing in.
  // (A first visit, a link or a reload starts him at the spawn.)
  let fromStreet = false;
  try {
    fromStreet = sessionStorage.getItem('entering') === cfg.place.id;
    sessionStorage.removeItem('entering');
  } catch {}
  if (fromStreet && exits[0]) {
    const door = exits[0];
    const right = door.x + door.width / 2 > cfg.width / 2;
    x = clamp(right ? door.x - 18 : door.x + door.width + 18, bounds.x0, bounds.x1);
    facing = right ? -1 : 1;
  }
  let turning = false;
  let jumpQueued = false;
  let target: Target | null = null;
  let stuck = 0;
  let leaving = false;
  /**
   * The warp: arriving here by one ('in': the street's Home button warps him into his room), or Back
   * to street, waiting to land ('queued') and then playing ('out'). He cannot be moved meanwhile.
   */
  let warping: 'in' | 'queued' | 'out' | null = null;
  if (warpedTo(cfg.place.id) && !reducedMotion() && anim.has('death')) {
    anim.play('death', { loop: false, order: warpInOrder(cfg.player.tags.death.frames) });
    warping = 'in';
  }
  /** The thing whose panel is open, so walking away from it closes the panel. */
  let openedBy: Thing | null = null;
  let near: Thing | null = null;
  let hoverProp: Prop | null = null;
  let hoverThing: Thing | null = null;

  // Coming back to the map later puts him outside this building.
  try {
    sessionStorage.setItem('map-from', cfg.place.id);
  } catch {}

  /** The spot on the floor in front of something on the wall. */
  const frontOf = (s: Slice): Point => ({
    x: clamp(s.x + s.width / 2, bounds.x0, bounds.x1),
    y: clamp(Math.max(s.y + s.height, floor.y) + 8, bounds.y0, bounds.y1),
  });

  const blockers = () =>
    platforms.filter((p) => p.height > z + 1).map((p) => ({ x0: p.x0, x1: p.x1, y0: p.back, y1: p.front }));

  const go = (goal: Point, extra: Partial<Target> = {}) => {
    const clamped = { x: clamp(goal.x, bounds.x0, bounds.x1), y: clamp(goal.y, bounds.y0, bounds.y1) };
    target = { path: findPath({ x, y }, clamped, blockers(), bounds), marked: true, ...extra };
  };

  const use = (t: Thing) => {
    openedBy = t;
    ui.panels.open(t.opens);
  };

  const goTo = (t: Thing) => go(frontOf(t.slice), { then: () => use(t) });

  const leave = (to: unknown = 'map') => {
    if (leaving) return;
    leaving = true;
    location.href = typeof to === 'string' && to.startsWith('/') ? to : cfg.mapPath;
  };

  /** Back to street, from anywhere in the room: he warps out (once he lands), and the street shows him arriving. */
  const warpOut = () => {
    if (leaving || warping) return;
    target = null;
    jumpQueued = false;
    if (ui.panels.current) ui.panels.close();
    if (ui.warp) ui.warp.disabled = true;
    if (reducedMotion() || !anim.has('death')) return warpGone();
    warping = 'queued';
  };
  /** The warp is over: to the street, which shows him arriving the same way. */
  const warpGone = () => {
    warpTo('street');
    leave(cfg.mapPath);
  };

  /** Whether he is at the door. */
  const atExit = () => !!exits[0] && Math.abs(x - (exits[0].x + exits[0].width / 2)) < EXIT_REACH;

  /** The Exit button, E at the door, and Esc: hurry out the exit. Asked twice, just go. */
  const exitNow = () => {
    const door = exits[0];
    if (!door || target?.exit) return leave(door?.data.to);
    const spot = {
      x: clamp(door.x + door.width / 2, bounds.x0, bounds.x1),
      y: clamp(y, Math.max(bounds.y0, door.y + 1), Math.min(bounds.y1, door.y + door.height)),
    };
    go(spot, {
      exit: true,
      marked: false,
      speed: Math.max(RUN, Math.abs(spot.x - x) / EXIT_SECONDS),
      then: () => leave(door.data.to),
    });
  };

  // A link straight to a panel (/projects#odin) starts him in front of its thing.
  const asked = ui.panels.fromAddress();
  if (asked) {
    const t = things.find((thing) => thing.opens === asked);
    if (t) ({ x, y } = frontOf(t.slice));
    openedBy = t ?? null;
    ui.panels.open(asked, { address: false });
  }
  ui.panels.onChange((id) => {
    if (!id) openedBy = null;
  });

  let camX = clamp(x - view.width / 2, 0, Math.max(0, cfg.width - view.width));
  let camY = 0;

  // --- Where he is, for the text page, and standing him where the text page was (src/game/spot.ts) ---
  const tipOf = (s: Slice) => String(s.data.tip ?? s.name.slice('prop:'.length));
  /** The thing he is at: an open panel, the thing in reach, or the nearest board or prop within a few steps. */
  const spotHere = (): string | null => {
    if (ui.panels.current) return ui.panels.current;
    if (near) return near.opens;
    let best: string | null = null;
    let score = 64;
    const consider = (id: string, s: Slice) => {
      const gap = x < s.x ? s.x - x : x > s.x + s.width ? x - s.x - s.width : 0;
      // Under two at once, the one whose middle is nearer.
      const d = gap + Math.abs(x - (s.x + s.width / 2)) * 0.01;
      if (d < score) [score, best] = [d, id];
    };
    things.forEach((t) => consider(t.opens, t.slice));
    sliceStarting(cfg.slices, 'show:').forEach((s) => consider(s.name.slice('show:'.length), s));
    props.forEach((p) => consider(tipOf(p.slice), p.slice));
    return best;
  };
  /** Stands him in front of a thing (opening it, if it opens), a board or a prop. */
  const standAt = (id: string) => {
    const thing = things.find((t) => t.opens === id);
    const slice = thing?.slice ?? cfg.slices.find((s) => s.name === `show:${id}`) ?? props.find((p) => tipOf(p.slice) === id)?.slice;
    if (slice) {
      ({ x, y } = frontOf(slice));
      [z, vz, target] = [0, 0, null];
      camX = clamp(x - view.width / 2, 0, Math.max(0, cfg.width - view.width));
    }
    if (thing) use(thing);
    else if (!slice && ui.panels.has(id)) ui.panels.open(id);
  };
  const arrival = takeArrival(cfg.place.id);
  if (arrival) standAt(arrival);
  registerSpot(() => ({ place: cfg.place.id, id: spotHere() }), standAt);

  // --- Keys ---
  onPress((code) => {
    if (!gameOn() || warping) return;
    if (KEYS.jump.includes(code)) jumpQueued = true;
    else if (KEYS.use.includes(code) && near) use(near);
    else if (KEYS.use.includes(code) && atExit()) exitNow();
    else if (KEYS.back.includes(code)) {
      if (ui.panels.current) ui.panels.close();
      else if (atExit()) exitNow();
      else warpOut();
    }
  });

  // --- Click or tap: run there (around anything in the way), or to the thing and use it.
  //     Hold and drag to steer. ---
  let steering = false;
  const at = (clientX: number, clientY: number) => {
    const p = view.toArt(clientX, clientY);
    const wx = p.x + camX;
    const wy = p.y + camY;
    return {
      wx,
      wy,
      thing: things.find((t) => contains(t.slice, wx, wy)),
      prop: props.find((pr) => contains(pr.slice, wx, wy)),
    };
  };
  const floorPoint = (wx: number, wy: number): Point => ({ x: wx, y: wy >= floor.y ? clamp(wy, bounds.y0, bounds.y1) : y });
  ui.canvas.addEventListener('pointerdown', (event) => {
    if (event.button !== 0 || warping) return;
    ui.stage.focus({ preventScroll: true });
    const hit = at(event.clientX, event.clientY);
    if (hit.thing) return goTo(hit.thing);
    if (hit.prop) return go(frontOf(hit.prop.slice));
    steering = true;
    ui.canvas.setPointerCapture(event.pointerId);
    go(floorPoint(hit.wx, hit.wy));
  });
  ui.canvas.addEventListener('pointermove', (event) => {
    const hit = at(event.clientX, event.clientY);
    hoverProp = event.pointerType === 'mouse' ? hit.prop ?? null : null;
    hoverThing = event.pointerType === 'mouse' ? hit.thing ?? null : null;
    ui.canvas.style.cursor = hit.thing || hit.prop ? 'pointer' : '';
    if (steering) go(floorPoint(hit.wx, hit.wy));
  });
  ui.canvas.addEventListener('pointerleave', () => {
    hoverProp = null;
    hoverThing = null;
  });
  const stopSteering = () => (steering = false);
  ui.canvas.addEventListener('pointerup', stopSteering);
  ui.canvas.addEventListener('pointercancel', stopSteering);

  // Clicking something on the wall (not one of its links) walks him over to read it.
  world.forEach((slice, el) =>
    el.addEventListener('click', (event) => {
      if (warping || (event.target as Element).closest('a, button, input, textarea')) return;
      go(frontOf(slice));
    }),
  );

  ui.exit?.addEventListener('click', exitNow);
  ui.warp?.addEventListener('click', () => {
    ui.stage.focus({ preventScroll: true });
    warpOut();
  });

  // Buttons that name a thing: run to it and open it, or just open the panel.
  ui.goButtons.forEach((button) =>
    button.addEventListener('click', () => {
      const id = button.dataset.go ?? '';
      const t = things.find((thing) => thing.opens === id);
      if (warping) return;
      if (t) {
        ui.stage.focus({ preventScroll: true });
        goTo(t);
      } else ui.panels.open(id);
    }),
  );

  // --- Each frame ---
  const update = (dt: number) => {
    // Warping out, he stands still (and lands first, if he was in the air).
    const dx = warping ? 0 : (isDown(KEYS.right) ? 1 : 0) - (isDown(KEYS.left) ? 1 : 0);
    const dy = warping ? 0 : (isDown(KEYS.down) ? 1 : 0) - (isDown(KEYS.up) ? 1 : 0);
    const run = !isDown(KEYS.run); // Shift walks
    if (warping) target = null;
    if (dx || dy) target = null;

    let stepX = 0;
    let stepY = 0;
    if (target) {
      const next = target.path[0];
      const ex = next.x - x;
      const ey = next.y - y;
      if (Math.abs(ex) < 0.75 && Math.abs(ey) < 0.75) {
        target.path.shift();
        if (!target.path.length) {
          const done = target;
          target = null;
          done.then?.();
        }
      } else {
        // Straight at the next point, at the speed for the longer of the two directions.
        const sx = (target.speed ?? (run ? RUN : WALK)) * dt;
        const sy = DEPTH * (run ? 1.5 : 1) * dt;
        const frames = Math.max(Math.abs(ex) / sx, Math.abs(ey) / sy);
        const t = frames > 1 ? 1 / frames : 1;
        stepX = ex * t;
        stepY = ey * t;
      }
    } else {
      stepX = dx * (run ? RUN : WALK) * dt;
      stepY = dy * DEPTH * (run ? 1.5 : 1) * dt;
    }

    const fromX = x;
    const fromY = y;
    const nx = clamp(x + stepX, bounds.x0, bounds.x1);
    if (!blocked(nx, y, z)) x = nx;
    const ny = clamp(y + stepY, bounds.y0, bounds.y1);
    if (!blocked(x, ny, z)) y = ny;
    const movedX = x - fromX;
    const moving = Math.abs(movedX) > 0.001 || Math.abs(y - fromY) > 0.001;

    // A target he cannot reach is given up.
    if (target && !moving) {
      stuck += dt;
      if (stuck > 0.35) target = null;
    } else stuck = 0;

    // Falling, jumping, landing.
    const support = supportAt(x, y);
    const grounded = z <= support + 0.01 && vz <= 0;
    if (jumpQueued && grounded) vz = JUMP;
    jumpQueued = false;
    if (vz > 0 || z > support) {
      vz -= GRAVITY * dt;
      z += vz * dt;
      if (z <= support && vz <= 0) {
        z = support;
        vz = 0;
      }
    } else z = support;
    const airborne = z > support + 0.01 || vz > 0;

    // Which way he faces, and what he is doing.
    const running = moving && (target?.speed !== undefined || run);
    const gait = !moving ? 'idle' : running ? 'run' : 'walk';
    const wantFacing = Math.abs(movedX) > 0.001 ? Math.sign(movedX) : facing;
    if (wantFacing !== facing) {
      facing = wantFacing;
      if (!airborne) {
        anim.play(`${gait}_turn`, { loop: false, restart: true });
        turning = anim.tag === `${gait}_turn`;
      }
    }
    if (warping === 'in') {
      // The warp in, backwards; whole again, he is free to go.
      anim.update(dt * 1000 * WARP_SPEED);
      if (anim.done) {
        warping = null;
        anim.play('idle');
      }
    } else if (warping === 'out') {
      // The warp plays out, then the street.
      anim.update(dt * 1000 * WARP_SPEED);
      if (anim.done) warpGone();
    } else if (warping === 'queued' && !airborne) {
      turning = false;
      anim.play('death', { loop: false, restart: true });
      warping = 'out';
    } else if (airborne) {
      turning = false;
      if (vz > 0) anim.play('jump', { loop: false, from: 1 });
      else if (anim.tag !== 'fall' && anim.tag !== 'fall_loop') anim.play('fall', { loop: false });
      else if (anim.tag === 'fall' && anim.done) anim.play('fall_loop');
    } else if (turning && !anim.done) {
      // Let the turn finish.
    } else {
      turning = false;
      if (gait !== 'idle') anim.play(gait);
      else if (anim.tag === 'run') anim.play('run_to_idle', { loop: false });
      else if (anim.tag !== 'run_to_idle' || anim.done) anim.play('idle');
    }
    if (warping !== 'out' && warping !== 'in') anim.update(dt * 1000);

    // Walking out the exit leaves the scene.
    const out = exits.find((e) => contains(e, x, y - 1));
    if (out && (moving || target?.exit)) leave(out.data.to);

    // The thing in reach, if any.
    near = null;
    let best = Infinity;
    for (const t of things) {
      const s = t.slice;
      if (x < s.x - REACH || x > s.x + s.width + REACH) continue;
      const d = Math.abs(x - (s.x + s.width / 2));
      if (d < best) [best, near] = [d, t];
    }
    // Walking away from a thing closes what it opened.
    if (openedBy && ui.panels.current === openedBy.opens && moving) {
      const s = openedBy.slice;
      if (x < s.x - REACH - 24 || x > s.x + s.width + REACH + 24) ui.panels.close();
    }

    // The camera leads him a little, and keeps him clear of an open panel at the side.
    const sideways = ui.panels.current && ui.stage.clientWidth > ui.stage.clientHeight;
    const want = sideways ? x - view.width * 0.28 : x + facing * 24 - view.width / 2;
    camX += (want - camX) * (1 - Math.exp(-dt * 4));
    camX = cfg.width <= view.width ? (cfg.width - view.width) / 2 : clamp(camX, 0, cfg.width - view.width);
    camY = cfg.height <= view.height ? 0 : clamp(Math.round(SAFE_MIDDLE - view.height / 2), 0, cfg.height - view.height);
  };

  /** A pixel ellipse on the floor under him, smaller and fainter the higher he is. */
  const shadow = (cx: number, cy: number, height: number, left = 1) => {
    if (left <= 0) return;
    const k = clamp(1 - height / 48, 0.35, 1) * left;
    const w = Math.max(4, Math.round(18 * k));
    ctx.fillStyle = `rgba(13, 11, 26, ${(0.55 * k).toFixed(2)})`;
    ctx.fillRect(Math.round(cx - w / 2), Math.round(cy - 1), w, 2);
    ctx.fillRect(Math.round(cx - w / 2) + 2, Math.round(cy - 2), w - 4, 1);
    ctx.fillRect(Math.round(cx - w / 2) + 2, Math.round(cy + 1), w - 4, 1);
  };

  /** The marker over where he is going; with reduced motion it holds its first frame. */
  const arrow = (cx: number, cy: number, dt: number) => {
    if (reducedMotion()) marker.hold(markerTag, 0);
    else marker.play(markerTag);
    marker.update(dt * 1000);
    marker.draw(ctx, cx, cy);
  };

  /**
   * Him in the mirror's glass, as a mirror on the back wall shows him: level with him (it moves at his
   * pace and leaves the glass when he walks past its edge), and smaller and fainter the further he
   * stands from the wall, its feet rising a little toward the middle of the glass. It hops when he jumps.
   */
  const REFLECT_NEAR = 0.85; // his size in the glass with his back to the wall
  const REFLECT_FAR = 0.6; // and at the front of the floor
  const reflection = (g: Slice, cx: number, flip: boolean) => {
    if (Math.abs(x - (g.x + g.width / 2)) > g.width / 2 + anim.sheet.width / 2) return;
    // How far out from the wall he stands, 0 (back of the floor) to 1 (front).
    const t = clamp((y - bounds.y0) / Math.max(1, bounds.y1 - bounds.y0), 0, 1);
    // Whole rows of sprite, so it steps a pixel at a time rather than shimmering.
    const h = anim.sheet.height;
    const s = Math.round(h * (REFLECT_NEAR + (REFLECT_FAR - REFLECT_NEAR) * t)) / h;
    const feet = g.y + g.height - 1 - Math.round(t * 3) - Math.round(z * s);
    ctx.save();
    ctx.beginPath();
    ctx.rect(g.x - cx, g.y - camY, g.width, g.height);
    ctx.clip();
    ctx.globalAlpha = 0.8 - 0.3 * t;
    ctx.translate(Math.round(x - cx), feet - camY);
    ctx.scale(s, s);
    anim.draw(ctx, 0, 0, flip);
    ctx.restore();
  };

  /** Where a piece's current frame is drawn (its top left), and the cell it comes from. */
  const cellOf = (p: Piece) => {
    const { sheet, frame, tag } = p.anim;
    const w = sheet.width;
    const h = sheet.height;
    return { x: p.ax - sheet.origin.x, y: p.ay - sheet.origin.y, sx: frame * w, sy: (sheet.tags[tag]?.row ?? 0) * h, w, h };
  };

  /** The yellow outline round a piece's current frame. */
  const outlinePiece = (p: Piece, cx: number) => {
    const c = cellOf(p);
    const key = `${p.anim.tag}:${p.anim.frame}`;
    if (!p.outlines.has(key)) p.outlines.set(key, outlineOfCell(p.image, c.sx, c.sy, c.w, c.h));
    const o = p.outlines.get(key);
    if (o) ctx.drawImage(o, c.x - 1 - cx, c.y - 1 - camY);
  };

  const draw = (now: number, dt: number) => {
    const cx = Math.round(camX);
    ctx.fillStyle = '#0d0b1a';
    ctx.fillRect(0, 0, view.width, view.height);
    // The prop pointed at (or else the one he stands at) lights up with an outline, and shows its card.
    const prop =
      hoverProp ?? props.find((pr) => x >= pr.slice.x - 6 && x <= pr.slice.x + pr.slice.width + 6) ?? null;
    // The pieces play `hover` (if they have it) while pointed at or in reach.
    for (const [name, p] of pieces) {
      const lit = prop?.slice.name === name || near?.slice.name === name || hoverThing?.slice.name === name;
      p.anim.play(lit && p.anim.has('hover') ? 'hover' : 'idle');
      p.anim.update(dt * 1000);
    }
    // The objects go just in front of the `props` layer: behind him, or (standing out on the floor,
    // while he is behind them) on the front canvas over him.
    const piecesOn = (g: CanvasRenderingContext2D, over: boolean) => (layer: { name: string }) => {
      if (layer.name !== 'props') return;
      for (const p of pieces.values()) if (depth < p.line === over) p.anim.draw(g, p.ax - cx, p.ay - camY);
    };
    const depth = sortY(x, y);
    drawLayers(ctx, cfg.layers, images, cx, camY, now, false, { y: depth }, piecesOn(ctx, false));
    // While a turn plays, the sheet's turn is drawn facing the way he came from.
    const flip = turning ? facing > 0 : facing < 0;
    if (glass) reflection(glass, cx, flip);
    if (prop?.piece) outlinePiece(prop.piece, cx);
    else if (prop?.outline) ctx.drawImage(prop.outline, prop.slice.x - 1 - cx, prop.slice.y - 1 - camY);
    const ground = supportAt(x, y);
    const warpAnim = warping === 'out' || warping === 'in';
    shadow(x - cx, y - ground - camY, z - ground, warpAnim ? warpShadow(anim.frame) : 1);
    if (target?.marked) {
      const goal = target.path[target.path.length - 1];
      arrow(goal.x - cx, goal.y - camY, dt);
    }
    fctx.clearRect(0, 0, front.width, front.height);
    anim.draw(fctx, x - cx, y - z - camY, flip);
    drawLayers(fctx, cfg.layers, images, cx, camY, now, true, { y: depth }, piecesOn(fctx, true));
    world.place(view, cx, camY);

    // The key prompt over the thing in reach.
    const showPrompt = near && !warping && ui.panels.current !== near.opens;

    // At the door, the Exit button over his head. If a thing is in reach too (NOVA stands by the
    // arcade's door), E is the thing's, and the Exit button sits above its prompt, to be clicked.
    if (ui.exit) {
      const show = atExit() && !leaving && !warping;
      if (ui.exit.hidden === show) ui.exit.hidden = !show;
      if (show) {
        const key = !showPrompt && !ui.touch();
        const html = key ? '<kbd>E</kbd> Exit to the street' : 'Exit to the street';
        if (ui.exit.innerHTML !== html) ui.exit.innerHTML = html;
        const p = view.toStage(x - cx, y - z - camY - 38);
        placeTag(ui.exit, p.x, p.y - (showPrompt ? ui.prompt.offsetHeight + 8 : 0));
      }
    }
    ui.prompt.hidden = !showPrompt;
    if (near && showPrompt) {
      // Over his head, so it never covers the signs and marquees over the thing itself.
      const html = ui.touch() ? `Tap: ${near.prompt}` : `<kbd>E</kbd> ${near.prompt}`;
      if (ui.prompt.innerHTML !== html) ui.prompt.innerHTML = html;
      const p = view.toStage(x - cx, y - z - camY - 38);
      placeTag(ui.prompt, p.x, p.y);
    }

    // The card over that prop, or the window over the thing the mouse points at (not while a panel is open).
    const peek = ui.panels.current ? null : hoverThing?.peek;
    const card = peek && hoverThing ? { slice: hoverThing.slice, html: peek.innerHTML } : prop?.tip ? { slice: prop.slice, html: prop.tip.innerHTML } : null;
    ui.label.hidden = !card;
    ui.label.toggleAttribute('data-peek', !!peek);
    if (card) {
      const s = card.slice;
      if (ui.label.dataset.for !== s.name) {
        ui.label.dataset.for = s.name;
        ui.label.innerHTML = card.html;
      }
      const p = view.toStage(s.x + s.width / 2 - cx, s.y - camY - 4);
      placeTag(ui.label, p.x, p.y);
    }
  };

  // For checking the game from the browser's console.
  (window as unknown as { gameState: () => object }).gameState = () => ({
    x: Math.round(x), y: Math.round(y), z: Math.round(z), target, near: near?.id ?? null, view: [view.width, view.height], camX: Math.round(camX), camY: Math.round(camY),
  });
  // In development only: stand him somewhere (feet x, y, and height z above the floor), to check
  // which side of the furniture he is drawn on.
  if (import.meta.env.DEV)
    (window as unknown as { gamePut: (px: number, py: number, pz?: number) => void }).gamePut = (px, py, pz = 0) => {
      target = null;
      [x, y, z, vz] = [px, py, pz, 0];
      camX = clamp(x - view.width / 2, 0, Math.max(0, cfg.width - view.width));
    };

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
