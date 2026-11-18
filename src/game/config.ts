// Runs at build time, in the pages' frontmatter: turns the exports in
// src/assets/ into the config a page hands to the game script.

import type { ImageMetadata } from 'astro';
import russellJson from '../assets/sprites/russell.json';
import russellPng from '../assets/sprites/russell.png';
import arrowJson from '../assets/sprites/arrow.json';
import arrowPng from '../assets/sprites/arrow.png';
import { MAP_PATH, place, places } from './places';
import type { HubConfig, Layer, LayersJson, SceneConfig, SceneObject, Sheet, SheetJson } from './types';

const json = import.meta.glob<LayersJson>(['../assets/scenes/*/*.json', '../assets/hub/*.json'], {
  eager: true,
  import: 'default',
});
const pngs = import.meta.glob<ImageMetadata>(['../assets/scenes/*/*.png', '../assets/hub/*.png'], {
  eager: true,
  import: 'default',
});
const objectJson = import.meta.glob<SheetJson>('../assets/hub-objects/*.json', { eager: true, import: 'default' });
const objectPng = import.meta.glob<ImageMetadata>('../assets/hub-objects/*.png', { eager: true, import: 'default' });
const sceneObjectJson = import.meta.glob<SheetJson>('../assets/objects/*/*.json', { eager: true, import: 'default' });
const sceneObjectPng = import.meta.glob<ImageMetadata>('../assets/objects/*/*.png', { eager: true, import: 'default' });

const sheet = (data: SheetJson, png: ImageMetadata): Sheet => ({ ...data, src: png.src });

function layers(folder: string, file: string) {
  const data = json[`${folder}/${file}.json`];
  if (!data) throw new Error(`${folder}/${file}.json is missing: run npm run art`);
  const list: Layer[] = data.layers.map((layer) => {
    const png = pngs[`${folder}/${layer.image}`];
    if (!png) throw new Error(`${folder}/${layer.image} is missing: run npm run art`);
    return {
      name: layer.name,
      src: png.src,
      x: layer.x,
      y: layer.y,
      width: layer.width,
      height: layer.height,
      frames: layer.frames,
      durations: layer.durations ?? [100],
      speed: typeof layer.data.speed === 'number' ? layer.data.speed : 1,
      over: layer.data.over === true,
      sort: typeof layer.data.sort === 'number' ? layer.data.sort : undefined,
      stair: layer.data.stair === true,
    };
  });
  return { width: data.width, height: data.height, layers: list, slices: data.slices };
}

export function sceneConfig(id: string): SceneConfig {
  const scene = layers(`../assets/scenes/${id}`, id);
  // Each object:<id> and prop:<id> with a file in art/objects/<scene>/ is drawn from it.
  const objects: SceneObject[] = scene.slices
    .filter((s) => /^(object|prop):/.test(s.name))
    .flatMap((s) => {
      const name = s.name.slice(s.name.indexOf(':') + 1);
      const data = sceneObjectJson[`../assets/objects/${id}/${name}.json`];
      const png = sceneObjectPng[`../assets/objects/${id}/${name}.png`];
      return data && png ? [{ slice: s.name, sprite: sheet(data, png) }] : [];
    });
  return {
    kind: 'scene',
    place: place(id),
    ...scene,
    objects,
    player: sheet(russellJson as SheetJson, russellPng),
    arrow: sheet(arrowJson as SheetJson, arrowPng),
    mapPath: MAP_PATH,
  };
}

export function hubConfig(): HubConfig {
  const hub = layers('../assets/hub', 'hub');
  const buildings = places.map((p) => {
    const slice = hub.slices.find((s) => s.name === `building:${p.id}`);
    const door = hub.slices.find((s) => s.name === `door:${p.id}`);
    if (!slice || !door) throw new Error(`art/hub.aseprite needs the slices building:${p.id} and door:${p.id}`);
    const data = objectJson[`../assets/hub-objects/${p.id}.json`];
    const png = objectPng[`../assets/hub-objects/${p.id}.png`];
    if (!data || !png) throw new Error(`art/hub-objects/${p.id}.aseprite has not been exported: run npm run art`);
    return { place: p, slice, door, sprite: sheet(data, png) };
  });
  return {
    kind: 'hub',
    ...hub,
    player: sheet(russellJson as SheetJson, russellPng),
    arrow: sheet(arrowJson as SheetJson, arrowPng),
    buildings,
  };
}
