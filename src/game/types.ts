// The shapes of what `npm run art` exports (scripts/art/export.lua) and of the
// config each page hands to the game script.

export type UserData = Record<string, string | number | boolean>;

export interface Slice {
  name: string;
  x: number;
  y: number;
  width: number;
  height: number;
  data: UserData;
}

export interface Tag {
  row: number;
  frames: number;
  durations: number[];
  direction: string;
  repeats?: number;
}

/** A sprite sheet: one row per tag, one cell per frame. */
export interface SheetJson {
  width: number;
  height: number;
  columns: number;
  rows: number;
  /** The point in a cell that sits on the ground (the `feet` or `base` slice). */
  origin: { x: number; y: number };
  tags: Record<string, Tag>;
  slices: Slice[];
}

export interface Sheet extends SheetJson {
  src: string;
}

/** A scene or the map: one image per layer, back to front. */
export interface LayersJson {
  width: number;
  height: number;
  layers: {
    name: string;
    image: string;
    x: number;
    y: number;
    width: number;
    height: number;
    frames: number;
    durations?: number[];
    data: UserData;
  }[];
  slices: Slice[];
}

export interface Layer {
  name: string;
  src: string;
  x: number;
  y: number;
  width: number;
  height: number;
  frames: number;
  durations: number[];
  /** How fast it moves past compared with the floor. */
  speed: number;
  /** Drawn in front of the player. */
  over: boolean;
  /**
   * Layer user data `sort=<y>`: drawn in front of him only while his feet are behind that line
   * (y less than it), for a thing standing out on the floor that he can walk behind (the couch).
   */
  sort?: number;
  /** Layer user data `stair`: drawn in front of him only while he is on a stairway (the railings). */
  stair?: boolean;
}

export interface Place {
  id: string;
  path: string;
  /** The page's title: what the visitor finds there. */
  title: string;
  /** The building on the map. */
  label: string;
}

/** A scene's interactable, drawn from its own file: art/objects/<scene>/<id>.aseprite. */
export interface SceneObject {
  /** The object:<id> or prop:<id> slice it stands on (the middle of its bottom edge). */
  slice: string;
  sprite: Sheet;
}

export interface SceneConfig {
  kind: 'scene';
  place: Place;
  width: number;
  height: number;
  layers: Layer[];
  slices: Slice[];
  /** Drawn just in front of the `props` layer. */
  objects: SceneObject[];
  player: Sheet;
  /** The marker over where he is running to (art/arrow.aseprite). */
  arrow: Sheet;
  mapPath: string;
}

export interface HubBuilding {
  place: Place;
  /** Where its sprite stands (bottom middle) and what can be clicked. */
  slice: Slice;
  /** door:<id>: where he stands to go in (bottom middle), and its level. */
  door: Slice;
  sprite: Sheet;
}

/** The hub: the front view of the street that leads to every place (art/hub.aseprite). */
export interface HubConfig {
  kind: 'hub';
  width: number;
  height: number;
  layers: Layer[];
  slices: Slice[];
  player: Sheet;
  arrow: Sheet;
  buildings: HubBuilding[];
}

export type GameConfig = SceneConfig | HubConfig;
