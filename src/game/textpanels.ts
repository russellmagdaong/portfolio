/**
 * The panels hung over the rooms on the text page (src/components/text/ScenePanel.astro): one
 * detail at a time, beside the list of what is inside.
 *
 * A detail changes on a click (or Enter / Space) on an item, a tab or a thing in the room, never
 * on hover or focus alone: Russell found resting-to-switch hard to steer (2026-11-18). Hovering is
 * left to things that only preview (the arcade cabinets' briefs, the certificates growing), in CSS.
 * Esc goes back to the first. Inactive details and tabs are hidden "until found", so find-in-page
 * still reaches them and opens them.
 *
 * Without this script every detail shows (the panels only go live here).
 */
import { reducedMotion } from './view';

/** Below 900px the panel sits under its room, and the room scrolls sideways in its frame. */
const narrow = matchMedia('(max-width: 899px)');
/**
 * On a phone (Russell, 2026-11-18) the rooms and the postcard's street are drawn whole, zoomed out
 * to the screen's width, and the panels' lists are a row of tabs. The post office keeps its 2x art,
 * scrolling sideways: its counter reads better close.
 */
const phone = matchMedia('(max-width: 600px)');
/** Where a room hangs its panel over it (text.css: from 900px), and may be zoomed up to its stage. */
const wide = matchMedia('(min-width: 900px)');
const KEEP_CLOSE = '#sec-contact';
const POINTABLE = '.t-item, .t-target, .t-tab';

/** The room's height at 2x: a panel hangs 20px inside it, top and bottom. */
const ROOM_H = 540;
/** The smallest a detail is drawn to fit its room; past that the room's stage grows instead. */
const MIN_ZOOM = 0.75;

/**
 * Fits a panel in its room without scrolling (all but the arcade's, which scrolls one page): if the
 * shown detail makes the panel taller than the room, the detail is drawn smaller (CSS zoom, so its
 * ruled lines, pins and padding scale with the words), down to MIN_ZOOM. Under 900px the panel sits
 * under its room and keeps its size.
 */
function fit(panel: HTMLElement) {
  if (panel.dataset.material === 'cabinet') return;
  const detail = detailsOf(panel).find((d) => !d.hidden) ?? null;
  detailsOf(panel).forEach((d) => d.style.removeProperty('zoom'));
  if (!detail || narrow.matches) return;
  const room = ROOM_H - 40;
  const fits = (zoom: number) => {
    detail.style.zoom = String(zoom);
    return panel.getBoundingClientRect().height <= room;
  };
  if (fits(1)) return detail.style.removeProperty('zoom');
  if (!fits(MIN_ZOOM)) return;
  // The largest zoom that fits, to the hundredth (seven halvings of the range).
  let [lo, hi] = [MIN_ZOOM, 1];
  for (let i = 0; i < 7; i++) {
    const mid = (lo + hi) / 2;
    if (fits(mid)) lo = mid;
    else hi = mid;
  }
  detail.style.zoom = String(Math.floor(lo * 100) / 100);
}

const panelOf = (el: Element) =>
  (el.closest('[data-panel]') ?? el.closest('[data-stage]')?.querySelector('[data-panel]')) as HTMLElement | null;
const detailsOf = (panel: HTMLElement) => [...panel.querySelectorAll<HTMLElement>('.t-detail')];
const split = (panel: HTMLElement) => panel.hasAttribute('data-split');

/** The detail in a panel that holds a spot id (it is the detail's key, or a data-spot inside it). */
function detailFor(panel: HTMLElement, id: string) {
  return detailsOf(panel).find((d) => d.dataset.detail === id || d.querySelector(`[data-spot="${CSS.escape(id)}"]`)) ?? null;
}

function wipe(el: HTMLElement) {
  if (reducedMotion()) return;
  el.classList.remove('is-wiping');
  void el.offsetWidth;
  el.classList.add('is-wiping');
}

/** Marks the things in the room that stand for what is showing. */
function markTargets(panel: HTMLElement, shownIds: Set<string>) {
  const stage = panel.closest('[data-stage]');
  stage?.querySelectorAll<HTMLElement>('.t-target').forEach((t) => t.toggleAttribute('data-on', shownIds.has(t.dataset.target ?? '')));
  // A thing drawn as its own sprite shows it in its own outline (text.css, .t-obj[data-lit]).
  stage?.querySelectorAll<HTMLElement>('.t-obj[data-for]').forEach((o) => o.toggleAttribute('data-on', shownIds.has(o.dataset.for ?? '')));
}

/** Lights a sprite's outline while its button is pointed at or focused (the button is only a box). */
function hoverSprite(target: Element | null, on: boolean) {
  if (!(target instanceof HTMLElement) || !target.matches('.t-target[data-sprite]')) return;
  const id = CSS.escape(target.dataset.target ?? '');
  target.closest('[data-stage]')?.querySelector(`.t-obj[data-for="${id}"]`)?.toggleAttribute('data-hover', on);
}

const idsIn = (detail: HTMLElement) =>
  new Set([detail.dataset.detail ?? '', ...[...detail.querySelectorAll<HTMLElement>('[data-spot]')].map((e) => e.dataset.spot ?? '')]);

/** Shows one detail of a panel. polite: say the change out loud (it came from a click or the keys). */
function show(panel: HTMLElement, key: string, { polite = false } = {}) {
  const details = detailsOf(panel);
  const next = details.find((d) => d.dataset.detail === key);
  if (!next) return false;
  if (!split(panel)) {
    // Every group shows: pointing at one just marks it.
    details.forEach((d) => d.toggleAttribute('data-on', d === next));
    markTargets(panel, idsIn(next));
    return true;
  }
  panel.querySelector('.t-details')?.setAttribute('aria-live', polite ? 'polite' : 'off');
  const was = details.find((d) => !d.hidden);
  details.forEach((d) => {
    if (d === next) d.removeAttribute('hidden');
    else d.setAttribute('hidden', 'until-found');
  });
  panel.querySelectorAll<HTMLElement>('.t-item').forEach((b) => b.setAttribute('aria-pressed', String(b.dataset.item === key)));
  markTargets(panel, idsIn(next));
  fit(panel);
  if (was !== next) {
    wipe(next);
    // A new project (or any new detail) starts at its top, not where the last one was scrolled to.
    panel.querySelector('.t-details')?.scrollTo({ top: 0 });
  }
  return true;
}

/** Shows one tab of a detail's tabs. */
function showTab(tabs: HTMLElement, key: string) {
  const panels = [...tabs.querySelectorAll<HTMLElement>('[data-tab-panel]')];
  if (!panels.some((p) => p.dataset.tabPanel === key)) return;
  panels.forEach((p) => (p.dataset.tabPanel === key ? p.removeAttribute('hidden') : p.setAttribute('hidden', 'until-found')));
  tabs.querySelectorAll<HTMLElement>('[data-tab]').forEach((b) => b.setAttribute('aria-pressed', String(b.dataset.tab === key)));
}

/** Chooses what a clicked thing stands for. */
function choose(el: HTMLElement, polite: boolean) {
  if (el.matches('.t-tab')) {
    const tabs = el.closest<HTMLElement>('[data-tabs]');
    if (tabs) showTab(tabs, el.dataset.tab ?? '');
    return;
  }
  const panel = panelOf(el);
  if (!panel) return;
  const key = el.dataset.item ?? detailFor(panel, el.dataset.target ?? '')?.dataset.detail;
  if (key) show(panel, key, { polite });
}

const firstKey = (panel: HTMLElement) => detailsOf(panel)[0]?.dataset.detail ?? '';

/** Shows the detail that holds a spot, in whichever panel has it. False if none does. */
export function selectSpot(id: string): boolean {
  for (const panel of document.querySelectorAll<HTMLElement>('[data-panel][data-live]')) {
    const detail = detailFor(panel, id);
    if (!detail) continue;
    show(panel, detail.dataset.detail ?? '');
    // And the tab inside it that holds it, if it sits in one.
    const tabPanel = detail.querySelector(`[data-spot="${CSS.escape(id)}"]`)?.closest<HTMLElement>('[data-tab-panel]');
    const tabs = tabPanel?.closest<HTMLElement>('[data-tabs]');
    if (tabs && tabPanel) showTab(tabs, tabPanel.dataset.tabPanel ?? '');
    return true;
  }
  return false;
}

/** The spot showing in a section's panel (a split panel only), or null. */
export function currentSpot(section: HTMLElement): string | null {
  const panel = section.querySelector<HTMLElement>('[data-panel][data-live][data-split]');
  const detail = panel && detailsOf(panel).find((d) => !d.hidden);
  if (!detail) return null;
  return detail.querySelector<HTMLElement>('[data-spot]')?.dataset.spot ?? detail.dataset.detail ?? null;
}

/**
 * Sizes the words on each board in a room (SceneStage's board fills) to the largest that fit it, as
 * the game sizes its boards (world.ts fit): --fs in art pixels, capped at 8, rounded down to whole
 * CSS pixels (2 per art pixel) so the lettering stays sharp. Boards do not change size with the
 * window, so this only matters once the pixel font is in and the page is showing.
 */
function fitBoards(root: HTMLElement) {
  root.querySelectorAll<HTMLElement>('.t-fill[data-board]').forEach((box) => {
    const text = box.querySelector<HTMLElement>('[data-board-text]');
    if (!text || box.clientHeight === 0) return;
    const fits = (u: number) => {
      text.style.setProperty('--fs', String(u));
      return box.scrollHeight <= box.clientHeight + 1 && box.scrollWidth <= box.clientWidth + 1;
    };
    if (fits(8)) return;
    let [lo, hi] = [1, 8];
    for (let i = 0; i < 12; i++) {
      const mid = (lo + hi) / 2;
      if (fits(mid)) lo = mid;
      else hi = mid;
    }
    fits(Math.max(1, Math.floor(lo * 2)) / 2);
  });
}

/** Zooms each room (and the postcard's street) to the frame's width on a phone; undoes it wider. */
function fitArt(root: HTMLElement) {
  root.querySelectorAll<HTMLElement>('.t-stage').forEach((stage) => {
    const frame = stage.querySelector<HTMLElement>('.t-stage-frame');
    const art = stage.querySelector<HTMLElement>('.t-stage-art');
    const width = parseFloat(stage.style.getPropertyValue('--art-w'));
    if (!frame || !art || !width) return;
    const on = phone.matches && !stage.closest(KEEP_CLOSE);
    // Wider than a phone it always comes off (there the frame is display: contents, 0 wide, so
    // it must not wait on a measurement: a window widened from phone size kept the phone's zoom).
    if (!on) {
      stage.removeAttribute('data-fit');
      art.style.removeProperty('zoom');
      // On a wide screen a room narrower than its stage is zoomed up to fill it, so no ink shows
      // beside it (Russell, 2026-11-18); a stage narrower than the room keeps the crop at its focus.
      const view = parseFloat(stage.style.getPropertyValue('--view-w'));
      const zoom = wide.matches && view ? stage.clientWidth / view : 0;
      if (zoom > 1) {
        stage.setAttribute('data-fill', '');
        art.style.zoom = String(zoom);
      } else stage.removeAttribute('data-fill');
      return;
    }
    stage.removeAttribute('data-fill');
    // Hidden (the game is showing): measured again when the text page shows.
    if (frame.clientWidth === 0) return;
    stage.setAttribute('data-fit', '');
    art.style.zoom = String(frame.clientWidth / width);
    frame.scrollLeft = 0;
  });
  const scroller = root.querySelector<HTMLElement>('[data-front-scroll]');
  const clip = scroller?.querySelector<HTMLElement>('.t-front-clip');
  const streetWidth = clip ? parseFloat(clip.style.getPropertyValue('--sw')) * 2 : 0;
  if (scroller && clip && streetWidth) {
    if (!phone.matches) clip.style.removeProperty('zoom');
    else if (scroller.clientWidth > 0) clip.style.zoom = String(scroller.clientWidth / streetWidth);
  }
}

/**
 * The credentials case on a phone: its tabs wrap in rows, and the folder opened shows right under
 * its own tab, not under them all (Russell, 2026-11-18). The list and the details flow as one row of
 * boxes (display: contents in text.css), each detail placed straight after its tab by flex order.
 */
function orderInline(panel: HTMLElement) {
  let n = 0;
  panel.querySelectorAll<HTMLElement>('.t-item-group').forEach((group) => {
    const head = group.querySelector<HTMLElement>('.t-item-head');
    if (head) head.style.order = String(n++);
    group.querySelectorAll<HTMLElement>('li').forEach((li) => {
      li.style.order = String(n++);
      const key = li.querySelector<HTMLElement>('.t-item')?.dataset.item ?? '';
      const detail = detailsOf(panel).find((d) => d.dataset.detail === key);
      if (detail) detail.style.order = String(n++);
    });
  });
}

/**
 * A project's write-up on a phone (Russell, 2026-11-18): one page at a time (the overview, how it
 * works, the screens, the stack), with Prev and Next under it. Its title and its buttons stay on
 * every page. Wider, every part shows. Hidden parts are "until found", so find-in-page opens them.
 */
function pageProject(project: HTMLElement) {
  const parts = [...project.querySelectorAll<HTMLElement>(':scope > .t-project-part')];
  if (parts.length < 2) return;
  const names = parts.map((part, i) => part.querySelector('.t-part-head')?.textContent?.trim() || (i === 0 ? 'Overview' : `Part ${i + 1}`));
  const pager = document.createElement('nav');
  pager.className = 't-pager';
  pager.setAttribute('aria-label', 'Pages of this project');
  pager.innerHTML = `<button type="button" class="t-pager-btn" data-page-step="-1">&#9664;&#xFE0E; Prev</button>
    <span class="t-pager-count" aria-live="polite"></span>
    <button type="button" class="t-pager-btn" data-page-step="1">Next &#9654;&#xFE0E;</button>`;
  parts.at(-1)!.after(pager);
  const count = pager.querySelector<HTMLElement>('.t-pager-count')!;
  const [prev, next] = [...pager.querySelectorAll<HTMLButtonElement>('[data-page-step]')];
  let page = 0;
  const render = () => {
    const paged = phone.matches;
    parts.forEach((part, i) => {
      if (!paged || i === page) part.removeAttribute('hidden');
      else part.setAttribute('hidden', 'until-found');
    });
    count.textContent = `${page + 1} / ${parts.length} · ${names[page]}`;
    prev.disabled = page === 0;
    next.disabled = page === parts.length - 1;
  };
  const go = (to: number) => {
    page = Math.max(0, Math.min(parts.length - 1, to));
    render();
  };
  pager.addEventListener('click', (event) => {
    const step = (event.target as Element).closest<HTMLElement>('[data-page-step]')?.dataset.pageStep;
    if (!step) return;
    go(page + Number(step));
    // Back to the top of the write-up, where the new page starts.
    const top = project.getBoundingClientRect().top;
    if (top < 0) project.scrollIntoView({ block: 'start', behavior: reducedMotion() ? 'instant' : 'smooth' });
  });
  project.addEventListener('beforematch', (event) => {
    const i = parts.findIndex((part) => part.contains(event.target as Node));
    if (i >= 0) go(i);
  });
  phone.addEventListener('change', render);
  // And on any resize: an emulated or docked window can change size without the query reporting it.
  let paged = phone.matches;
  window.addEventListener('resize', () => {
    if (phone.matches !== paged) render();
    paged = phone.matches;
  });
  render();
}

export function initPanels(root: HTMLElement) {
  fitArt(root);
  root.querySelectorAll<HTMLElement>('.t-project').forEach(pageProject);
  root.querySelectorAll<HTMLElement>('[data-panel][data-material="case"]').forEach(orderInline);
  // On a phone each room opens at its crop's left edge (--focus, in art pixels at 2x).
  if (narrow.matches)
    root.querySelectorAll<HTMLElement>('.t-stage:not([data-fit])').forEach((stage) => {
      const frame = stage.querySelector<HTMLElement>('.t-stage-frame');
      if (frame) frame.scrollLeft = (parseFloat(stage.style.getPropertyValue('--focus')) || 0) * 2;
    });
  const panels = [...root.querySelectorAll<HTMLElement>('[data-panel]')];
  for (const panel of panels) {
    panel.setAttribute('data-live', '');
    if (split(panel)) show(panel, firstKey(panel));
    panel.querySelectorAll<HTMLElement>('[data-tabs]').forEach((tabs) => {
      const first = tabs.querySelector<HTMLElement>('[data-tab]')?.dataset.tab;
      if (first) showTab(tabs, first);
    });
  }

  // Refit when the page's width or fonts change what fits.
  const refit = () => {
    fitArt(root);
    fitBoards(root);
    panels.forEach(fit);
  };
  let resizing = 0;
  window.addEventListener('resize', () => {
    cancelAnimationFrame(resizing);
    resizing = requestAnimationFrame(refit);
  });
  document.fonts?.ready.then(refit);
  document.addEventListener('game-mode', () => requestAnimationFrame(refit));
  phone.addEventListener('change', refit);
  wide.addEventListener('change', refit);
  // A face first used further down the page (the letter's) can finish after "ready" has resolved.
  document.fonts?.addEventListener('loadingdone', refit);
  refit();

  // A sprite's outline follows the pointer and the keyboard focus on its button.
  root.addEventListener('pointerover', (event) => hoverSprite((event.target as Element).closest('.t-target'), true));
  root.addEventListener('pointerout', (event) => hoverSprite((event.target as Element).closest('.t-target'), false));
  root.addEventListener('focusin', (event) => hoverSprite((event.target as Element).closest('.t-target'), (event.target as Element).matches(':focus-visible')));
  root.addEventListener('focusout', (event) => hoverSprite((event.target as Element).closest('.t-target'), false));

  // A click (Enter and Space click a button too): at once, and said out loud. On a phone the detail
  // sits under the list, so a tap brings it into view.
  root.addEventListener('click', (event) => {
    const el = (event.target as Element).closest<HTMLElement>(POINTABLE);
    if (!el) return;
    choose(el, true);
    if (narrow.matches && el.matches('.t-item')) {
      const detail = document.getElementById(el.getAttribute('aria-controls') ?? '');
      if (!detail || detail.hidden) return;
      const tall = detail.getBoundingClientRect().height > innerHeight;
      detail.scrollIntoView({ block: tall ? 'start' : 'nearest', behavior: reducedMotion() ? 'instant' : 'smooth' });
    }
  });

  // Esc, inside a panel or on a thing in its room: back to the first.
  root.addEventListener('keydown', (event) => {
    if (event.key !== 'Escape') return;
    const el = (event.target as Element).closest<HTMLElement>('[data-panel], .t-target');
    const panel = el && panelOf(el);
    if (panel && split(panel)) show(panel, firstKey(panel), { polite: true });
  });

  // Find-in-page reached a hidden detail or tab: open it.
  root.addEventListener('beforematch', (event) => {
    const target = event.target as HTMLElement;
    const tabPanel = target.closest<HTMLElement>('[data-tab-panel]');
    const detail = target.closest<HTMLElement>('.t-detail');
    const panel = detail && panelOf(detail);
    if (panel && detail) show(panel, detail.dataset.detail ?? '');
    const tabs = tabPanel?.closest<HTMLElement>('[data-tabs]');
    if (tabs && tabPanel) showTab(tabs, tabPanel.dataset.tabPanel ?? '');
  });
}
