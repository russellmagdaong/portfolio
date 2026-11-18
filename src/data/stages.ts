/*
 * How each place's room is staged on the text page (src/components/text/SceneStage.astro): where
 * the crop sits, which side its panel hangs on, which of its moving layers keeps running, and the
 * arrows and board labels drawn over it. Measured at 1469 px with the sidebar open; the design is
 * docs/superpowers/specs/2026-11-18-scene-sections-design.md ("Shape outcome").
 */
import type { Slice } from '../game/types';

export interface StagePlan {
  /** Art x (art pixels) of the crop's left edge when the room is wider than its stage. END keeps
   *  the room's right end in view: a room whose panel hangs on the left is cropped under the panel,
   *  never at the open edge, so no board or frame is cut in half where it can be seen. 0 and END
   *  show the whole room on a stage wide enough for it; any other focus stays cropped there too
   *  (the panel then hangs at the crop, where the focus was chosen to put it). */
  focus: number;
  /** The side the panel hangs on, over the boards whose content it shows. */
  panel: 'left' | 'right';
  /** The panel's width in CSS pixels. */
  panelWidth: number;
  /** The one moving layer that keeps running (by layer name), or null for none. */
  loop: string | null;
  /** Arrows pointing at what can be pointed at: art pixels, the arrow's middle and top. */
  arrows: { x: number; y: number; label: string; touch: string }[];
  /** Words for blank boards left in view, by target id. */
  labels: Record<string, string>;
  /** Things moved (art pixels) where the panel would cover them, on screens 900px and up only (on a
   *  phone the panel sits under the room, which scrolls sideways): object and prop slices by name,
   *  and the targets standing on those slices move with them. */
  shift?: { slices: string[]; dx: number; dy: number };
}

/** A focus past any room's width: the crop is clamped to the room's right end (see focus). */
const END = 9999;

export const stages: Record<string, StagePlan> = {
  // The hobbies (guitar, console, camera, flag, trophy) stand on the shelf's floor under the panel:
  // moved as one group onto the floor between the bed and the panel, so Off the clock can light them.
  home: {
    focus: 0,
    panel: 'right',
    panelWidth: 680,
    loop: 'lights',
    arrows: [],
    labels: {},
    shift: { slices: ['prop:guitar', 'prop:console', 'prop:camera', 'prop:flag', 'prop:trophy'], dx: -299, dy: 44 },
  },
  school: { focus: END, panel: 'left', panelWidth: 640, loop: 'rain', arrows: [], labels: {} },
  arcade: {
    focus: 0,
    panel: 'right',
    panelWidth: 740,
    loop: 'lights',
    arrows: [{ x: 139, y: 104, label: 'Click a cabinet', touch: 'Tap a cabinet' }],
    labels: {},
  },
  store: {
    focus: END,
    panel: 'left',
    panelWidth: 640,
    loop: 'lights',
    // The screens show their group's logos (TextSite's fills), and point at nothing.
    arrows: [],
    labels: {},
  },
  // Not END: cropped at its right end, the panel would cover half the CTFs frame. From 70, at 1469 px
  // every frame is either whole in view or under the panel.
  'trophy-shop': {
    focus: 70,
    panel: 'left',
    panelWidth: 460,
    loop: 'lights',
    arrows: [],
    // The frames on the wall hold a certificate from their folder (TextSite's fills).
    labels: {},
  },
  'post-office': { focus: END, panel: 'left', panelWidth: 640, loop: 'lights', arrows: [], labels: {} },
};

/** A short brief shown over a thing in a room while it is hovered or focused. */
export interface StageBrief {
  title: string;
  line?: string;
  tagline?: string;
}

/**
 * What the game paints on a board or screen (its <Show>): a title, then paragraphs (the first the
 * lead), terminal lines, or term and value pairs. Drawn in the board's own ink and sized to fit it.
 */
export interface StageBoard {
  heading: string;
  /** A short line at the right of the title. */
  note?: string;
  text?: string[];
  lines?: string[];
  facts?: { term: string; value: string }[];
  /** Art pixels at the board's bottom kept clear of words: things the art stands on it. */
  clear?: number;
}

/** What a board or screen in a room shows, by spot id: a row of logos, a picture, or the game's board. */
export type StageFills = Record<string, { icons?: { src?: string; label: string }[]; image?: string; board?: StageBoard }>;

export interface Target {
  /** The spot id it stands for (the same id the page's data-spot and the game use). */
  id: string;
  /** The slice's own name (prop:guitar). */
  slice: string;
  x: number;
  y: number;
  width: number;
  height: number;
  /** How the board looks in the game (paper, chalk, terminal...), for its label's ink. */
  look?: string;
}

/**
 * The things in a room that can be pointed at, by the rule in src/game/spot.ts: object:<x> stands
 * for its opens=<id>, show:<id> for <id>, prop:<x> for its tip=<id>. Other slices are skipped.
 */
export function targetsOf(slices: Slice[]): Target[] {
  return slices.flatMap((s) => {
    const [kind, name] = [s.name.slice(0, s.name.indexOf(':')), s.name.slice(s.name.indexOf(':') + 1)];
    const id =
      kind === 'object' ? String(s.data.opens ?? name) : kind === 'show' ? name : kind === 'prop' ? String(s.data.tip ?? name) : null;
    if (!id || !s.name.includes(':')) return [];
    const look = typeof s.data.look === 'string' ? s.data.look : undefined;
    return [{ id, slice: s.name, x: s.x, y: s.y, width: s.width, height: s.height, look }];
  });
}
