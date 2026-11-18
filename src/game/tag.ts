/**
 * Puts a tag (the key prompt, a prop's card, a building's name) at a point on the stage: centred
 * on it and standing on top of it (the CSS translates it by -50% / -100%), but kept inside the
 * stage, so a tag over something at the edge of the window is never cut off. Nor does it sit over
 * the HUD's buttons: on a small screen a tag over a rooftop would cover them (and take their taps),
 * so it drops below the button it would hide.
 */
const MARGIN = 6;

export function placeTag(el: HTMLElement, x: number, y: number) {
  const stage = el.offsetParent as HTMLElement | null;
  const half = el.offsetWidth / 2;
  const height = el.offsetHeight;
  const width = stage?.clientWidth ?? window.innerWidth;
  const left = Math.min(Math.max(x, half + MARGIN), width - half - MARGIN);
  let top = Math.max(y, height + MARGIN);
  if (stage) {
    const origin = stage.getBoundingClientRect();
    for (const hud of stage.querySelectorAll<HTMLElement>('.hud-top > *')) {
      const box = hud.getBoundingClientRect();
      if (box.width === 0) continue;
      const l = box.left - origin.left;
      const r = box.right - origin.left;
      const b = box.bottom - origin.top;
      const overlaps = left + half > l - MARGIN && left - half < r + MARGIN && top - height < b + MARGIN;
      if (overlaps) top = Math.max(top, b + MARGIN + height);
    }
  }
  el.style.translate = `${Math.round(left)}px ${Math.round(top)}px`;
}
