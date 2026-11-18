/**
 * The keyboard. Keys only reach the game while focus is not in a panel, a form
 * or a dialog, so typing a message or using a gallery never moves the player.
 */

const held = new Set<string>();

export const KEYS = {
  left: ['ArrowLeft', 'KeyA'],
  right: ['ArrowRight', 'KeyD'],
  up: ['ArrowUp', 'KeyW'],
  down: ['ArrowDown', 'KeyS'],
  run: ['ShiftLeft', 'ShiftRight'],
  jump: ['Space'],
  use: ['KeyE', 'Enter', 'NumpadEnter'],
  back: ['Escape'],
};

export const isDown = (keys: string[]) => keys.some((k) => held.has(k));

/** True when the event happened somewhere the game should keep out of. */
export function elsewhere(target: EventTarget | null) {
  if (!(target instanceof Element)) return false;
  return Boolean(
    target.closest('input, textarea, select, [contenteditable], [data-panel], dialog, [data-keys-own]'),
  );
}

type Press = (code: string, event: KeyboardEvent) => void;
const listeners: Press[] = [];

export function onPress(listener: Press) {
  listeners.push(listener);
}

let bound = false;
export function bindKeys() {
  if (bound) return;
  bound = true;
  window.addEventListener('keydown', (event) => {
    if (event.ctrlKey || event.metaKey || event.altKey) return;
    // Nor while a popup is open over the game (a certificate up close): its Esc is its own.
    if (elsewhere(event.target) || document.querySelector('dialog[open]')) return;
    const game = Object.values(KEYS).some((list) => list.includes(event.code));
    if (!game) return;
    // Space and the arrows would otherwise scroll or press the focused button.
    if (event.code !== 'Escape' && event.code !== 'Enter') event.preventDefault();
    if (!event.repeat) listeners.forEach((l) => l(event.code, event));
    held.add(event.code);
  });
  window.addEventListener('keyup', (event) => held.delete(event.code));
  window.addEventListener('blur', () => held.clear());
  document.addEventListener('visibilitychange', () => held.clear());
}

/** Forget every held key (when focus moves into a panel, say). */
export const releaseAll = () => held.clear();
