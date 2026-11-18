/**
 * Starts a page made with src/layouts/Game.astro: the side-on scene or the street, the panels,
 * the HUD buttons, the text page, and the switch between the two versions.
 *
 * Switching versions (Russell, 2026-11-18): the text page opens at its top, where the postcard's
 * jeepney drives in and he walks to his door (frontride.ts). The game starts at home the first time
 * it is shown since the tab loaded fresh, and after that he arrives on the street by jeepney
 * (src/game/spot.ts keeps the mark). "Play it in the arcade" and the like still go to their thing.
 */
import { Panels } from './panels';
import { arriveAt, forgetPlayedOnReload, hasPlayed, markPlayed, putAt, sendByJeepney } from './spot';
import { initTextSite } from './textsite';
import { playFrontRide } from './frontride';
import { MAP_PATH, places } from './places';
import type { Ui } from './layers';
import type { GameConfig } from './types';

const root = document.documentElement;
// Tells the fail-safe in Game.astro that the script arrived.
root.dataset.engine = 'on';
forgetPlayedOnReload();
// Opened straight into the game (no chooser): that counts as having played.
if (root.classList.contains('game') && !root.classList.contains('choosing')) markPlayed();

const configEl = document.getElementById('game-config');
const config = configEl ? (JSON.parse(configEl.textContent ?? '{}') as GameConfig) : null;
/** This page's place: a scene's id, or 'street' for the hub. */
const here = config ? (config.kind === 'hub' ? 'street' : config.place.id) : null;
const pathOf = (place: string) => (place === 'street' ? MAP_PATH : places.find((p) => p.id === place)?.path ?? '/');

/** Shows the game or the text version, and remembers which. */
const applyMode = (game: boolean) => {
  root.classList.toggle('game', game);
  try {
    localStorage.setItem('mode', game ? 'game' : 'text');
  } catch {}
  document.dispatchEvent(new CustomEvent('game-mode', { detail: game }));
  if (game) {
    markPlayed();
    window.scrollTo(0, 0);
    document.querySelector<HTMLElement>('[data-stage]')?.focus({ preventScroll: true });
  }
};

/** The chooser on the first page of a visit: nothing has been played yet, so nothing to mark. */
let firstChoice = root.classList.contains('choosing');

/** Opens the game on another page (the chooser has been answered: no chooser there). */
const gameAt = (place: string) => {
  try {
    localStorage.setItem('mode', 'game');
    sessionStorage.setItem('mode-chosen', 'game');
  } catch {}
  location.href = pathOf(place);
};

/** Switches version. */
const setMode = (game: boolean) => {
  const was = root.classList.contains('game');
  const first = firstChoice;
  firstChoice = false;
  if (!here) return applyMode(game);
  if (game) {
    // Already playing (Change UI, then the game again; or back from the jeepney's ride, which
    // the street brings him back from itself): carry on where he is.
    if (was && !first) return applyMode(true);
    // The first time this session: at home.
    if (!hasPlayed()) {
      if (here !== 'home') return gameAt('home');
      return applyMode(true);
    }
    // Every time after: by jeepney, on the street.
    sendByJeepney();
    if (here !== 'street') return gameAt('street');
    applyMode(true);
    document.dispatchEvent(new CustomEvent('jeep-arrive'));
  } else {
    // Already reading (Change UI, then Esc or the text side again): stay where the page is.
    if (!was && !first) return applyMode(false);
    // The text page from its top: the jeepney pulls into the postcard and he walks to his door.
    applyMode(false);
    scrollTo({ top: 0, behavior: 'instant' });
    playFrontRide();
  }
};

// --- The chooser: on the first page of a visit, and from Change UI or the jeepney ---
const chooser = document.querySelector<HTMLElement>('[data-landing]');
// A clean copy, so it can open again with its entrance from the start.
const pristine = chooser?.cloneNode(true) as HTMLElement | undefined;
const openChooser = () => {
  const current = document.querySelector<HTMLElement>('[data-landing]');
  if (!pristine || !current || root.classList.contains('choosing')) return;
  const fresh = pristine.cloneNode(true) as HTMLElement;
  current.replaceWith(fresh);
  root.classList.add('choosing');
  import('./landing')
    .then((m) => m.runLanding(setMode, { reopened: true }))
    .catch(() => root.classList.remove('choosing'));
};
document.querySelectorAll<HTMLButtonElement>('[data-change-ui]').forEach((button) => button.addEventListener('click', openChooser));
document.addEventListener('change-ui', openChooser);

if (root.classList.contains('choosing')) {
  import('./landing')
    .then((m) => m.runLanding(setMode))
    .catch((error) => {
      console.error(error);
      root.classList.remove('choosing');
    });
}

// --- The text page ---
if (here) {
  initTextSite({
    here,
    pathOf,
    // "Play it in the arcade" and the like: the game, at that thing.
    play: (spot) => {
      if (spot.place !== here) {
        arriveAt(spot);
        try {
          localStorage.setItem('mode', 'game');
          sessionStorage.setItem('mode-chosen', 'game');
        } catch {}
        location.href = pathOf(spot.place);
        return;
      }
      applyMode(true);
      if (spot.id) putAt(spot.id);
    },
  });
}

// --- Touch or not: changes what the prompts say ---
let touch = matchMedia('(pointer: coarse)').matches;
window.addEventListener('pointerdown', (event) => (touch = event.pointerType === 'touch'), { capture: true });
window.addEventListener('keydown', () => (touch = false), { capture: true });

const stage = document.querySelector<HTMLElement>('[data-stage]');
const panels = new Panels(stage ?? document.body);
document.querySelectorAll<HTMLButtonElement>('[data-open-panel]').forEach((button) =>
  button.addEventListener('click', () => panels.open(button.dataset.openPanel ?? '')),
);

const canvas = document.querySelector<HTMLCanvasElement>('[data-canvas]');
if (config && stage && canvas) {
  const ui: Ui = {
    stage,
    canvas,
    world: document.querySelector<HTMLElement>('[data-world]')!,
    prompt: document.querySelector<HTMLElement>('[data-prompt]')!,
    label: document.querySelector<HTMLElement>('[data-label]')!,
    exit: document.querySelector<HTMLButtonElement>('[data-exit]'),
    warp: document.querySelector<HTMLButtonElement>('[data-warp]'),
    panels,
    goButtons: [...document.querySelectorAll<HTMLButtonElement>('[data-go]')],
    touch: () => touch,
  };
  const run = config.kind === 'hub' ? import('./hub').then((m) => m.runHub(config, ui)) : import('./scene').then((m) => m.runScene(config, ui));
  run
    .then(() => {
      root.dataset.engine = 'ready';
      if (root.classList.contains('game') && !root.classList.contains('choosing') && !panels.current) stage.focus({ preventScroll: true });
    })
    .catch((error) => {
      // Something failed to load: fall back to the text version rather than an empty screen.
      console.error(error);
      root.classList.remove('game');
      document.dispatchEvent(new CustomEvent('game-mode', { detail: false }));
    });
}
