/**
 * The text page (src/components/text/TextSite.astro): the nav (which slides in once the street on
 * the postcard's front is out of view), the section being read (the address follows it), things
 * revealing as they scroll in, and reading or setting where the visitor is, for switching to the
 * game (src/game/spot.ts).
 */
import type { Spot } from './spot';
import { currentSpot, initPanels, selectSpot } from './textpanels';
import { reducedMotion } from './view';

interface Options {
  /** This page's place. */
  here: string;
  pathOf: (place: string) => string;
  /** Buttons that play something in the game ("Find it in the arcade"). */
  play: (spot: Spot) => void;
}

/** The line, as a share of the window's height from the top, that counts as where one is reading. */
const READ_LINE = 0.32;

const root = document.documentElement;
/** This page's place (set by initTextSite): the postcard's front counts as it, except on the street itself. */
let pageHere: string | null = null;
const site = () => document.querySelector<HTMLElement>('[data-text-site]');
const showing = () => !root.classList.contains('game') && !root.classList.contains('choosing');
const headerHeight = () => document.querySelector<HTMLElement>('[data-t-header]')?.offsetHeight ?? 72;

function sectionsOf(place?: string) {
  const s = site();
  if (!s) return [];
  return [...s.querySelectorAll<HTMLElement>(place ? `[data-place="${CSS.escape(place)}"]` : '[data-place]')];
}

/**
 * The reading line, in px from the window's top; at the very bottom of the page, the window's bottom
 * edge. The last chapter (Contact) is too short to scroll up to READ_LINE on a tall window, so the
 * nav kept marking Awards at the end of the page. Only the bottom itself moves the line: the last
 * two chapters together are shorter than a screen, so sliding it any earlier skipped Awards.
 */
function readLine() {
  const left = document.documentElement.scrollHeight - (scrollY + innerHeight);
  return left <= 4 ? innerHeight : innerHeight * READ_LINE;
}

/** The section the reading line is in (or the last one above it). */
function currentSection() {
  const line = readLine();
  let found: HTMLElement | null = null;
  for (const sec of sectionsOf()) {
    if (sec.getBoundingClientRect().top <= line) found = sec;
  }
  found = found ?? sectionsOf()[0] ?? null;
  // The front (the street) opens every page; reading it, the visitor is still on this page's place.
  if (found?.dataset.place === 'street' && pageHere && pageHere !== 'street') return sectionsOf(pageHere)[0] ?? found;
  return found;
}

/** Where the text page is: the section being read, and the thing in it nearest the reading line. */
export function textSpot(): Spot | null {
  const sec = currentSection();
  if (!sec) return null;
  // A room's panel shows one thing at a time: that is where the visitor is.
  const showing = currentSpot(sec);
  if (showing) return { place: sec.dataset.place ?? '', id: showing };
  const line = readLine();
  let best: HTMLElement | null = null;
  let distance = innerHeight * 0.45;
  sec.querySelectorAll<HTMLElement>('[data-spot]').forEach((el) => {
    const r = el.getBoundingClientRect();
    const d = r.top > line ? r.top - line : r.bottom < line ? line - r.bottom : 0;
    // Nearer wins. Level with it (cards side by side): the one last pointed at or focused, or the
    // inner one (the photo in the terminal window); otherwise the first, as the eye reads.
    const tie = d === distance && best && (el === lastPointed || best.contains(el));
    if (d < distance || tie) [distance, best] = [d, el];
  });
  return { place: sec.dataset.place ?? '', id: (best as HTMLElement | null)?.dataset.spot ?? null };
}

/** The thing on the text page last pointed at or focused, to tell apart things side by side. */
let lastPointed: HTMLElement | null = null;

/** Scrolls to a place's section, or to a thing in it, marked for a moment if asked. */
export function showTextAt(spot: Spot, { mark = false, smooth = false } = {}) {
  // The postcard's front opens the page: anywhere on the street, and Home with nothing named in
  // it (the front and the letter right under it), start at the very top.
  if (spot.place === 'street' || (spot.place === 'home' && !spot.id)) {
    scrollTo({ top: 0, behavior: smooth && !reducedMotion() ? 'smooth' : 'instant' });
    return;
  }
  const secs = sectionsOf(spot.place);
  if (!secs.length) return;
  // A thing in a room's panel: show it there first, then go to the room (the panel hangs at its top).
  if (spot.id) selectSpot(spot.id);
  const el = (spot.id && secs.map((s) => s.querySelector<HTMLElement>(`[data-spot="${CSS.escape(spot.id!)}"]`)).find(Boolean)) || secs[0];
  const inPanel = !!el.closest('[data-panel][data-live]');
  const goTo = inPanel ? secs[0] : el;
  // The first section opens at the very top; a thing sits a little under the header.
  // A marked thing leaves room above it for its "Russell was here" tag.
  const gap = goTo === secs[0] ? 0 : mark ? 64 : 28;
  const top = goTo === sectionsOf()[0] ? 0 : goTo.getBoundingClientRect().top + scrollY - headerHeight() - gap;
  // Rounded down: a section that starts part way through a pixel is never cut by a hairline.
  scrollTo({ top: Math.max(0, Math.floor(top)), behavior: smooth && !reducedMotion() ? 'smooth' : 'instant' });
  // Reveal it now, rather than wiping it in while the eye looks for it.
  el.querySelectorAll('[data-reveal]').forEach((r) => r.classList.add('is-in'));
  el.closest('[data-reveal]')?.classList.add('is-in');
  if (el.hasAttribute('data-reveal')) el.classList.add('is-in');
  if (mark && el !== secs[0]) {
    el.classList.remove('is-here');
    void el.offsetWidth;
    el.classList.add('is-here');
    setTimeout(() => el.classList.remove('is-here'), 2800);
  }
}

export function initTextSite(options: Options) {
  const s = site();
  if (!s) return;
  pageHere = options.here;
  initPanels(s);
  const header = s.querySelector<HTMLElement>('[data-t-header]');
  const links = [...s.querySelectorAll<HTMLAnchorElement>('.t-nav [data-goto], .t-side-nav [data-goto]')];
  const menu = s.querySelector<HTMLButtonElement>('[data-menu-toggle]');

  // --- The sidebar (wide screens): open or folded into a rail, as the visitor last left it ---
  const foldButton = s.querySelector<HTMLButtonElement>('[data-side-fold]');
  const setSide = (side: 'open' | 'folded') => {
    root.dataset.side = side;
    foldButton?.setAttribute('aria-expanded', String(side === 'open'));
  };
  let stored: string | null = null;
  try {
    stored = localStorage.getItem('t-side');
  } catch {}
  setSide(stored === 'folded' ? 'folded' : 'open');
  foldButton?.addEventListener('click', () => {
    const side = root.dataset.side === 'folded' ? 'open' : 'folded';
    setSide(side);
    try {
      localStorage.setItem('t-side', side);
    } catch {}
  });

  // --- Links within the page: scroll there (and to a thing, if one is named) ---
  const closeMenu = () => {
    header?.classList.remove('is-open');
    menu?.setAttribute('aria-expanded', 'false');
  };
  s.querySelectorAll<HTMLElement>('[data-goto]').forEach((link) =>
    link.addEventListener('click', (event) => {
      event.preventDefault();
      closeMenu();
      showTextAt({ place: link.dataset.goto ?? options.here, id: link.dataset.gotoSpot ?? null }, { smooth: true, mark: !!link.dataset.gotoSpot });
    }),
  );
  // The postcard's "Scroll down": to the letter, just under the street ("go to Home" means the top).
  s.querySelector<HTMLAnchorElement>('[data-scroll-down]')?.addEventListener('click', (event) => {
    const letter = document.getElementById('sec-home');
    if (!letter) return;
    event.preventDefault();
    const top = Math.floor(letter.getBoundingClientRect().top + scrollY - (header?.offsetHeight && innerWidth < 1181 ? header.offsetHeight : 0));
    scrollTo({ top, behavior: reducedMotion() ? 'instant' : 'smooth' });
  });
  menu?.addEventListener('click', () => {
    const open = !header?.classList.contains('is-open');
    header?.classList.toggle('is-open', open);
    menu.setAttribute('aria-expanded', String(open));
  });
  document.addEventListener('keydown', (event) => event.key === 'Escape' && closeMenu());

  const point = (event: Event) => {
    const spot = (event.target as Element | null)?.closest?.<HTMLElement>('[data-spot]');
    if (spot) lastPointed = spot;
  };
  s.addEventListener('pointerover', point);
  s.addEventListener('focusin', point);

  s.querySelectorAll<HTMLButtonElement>('[data-play]').forEach((button) =>
    button.addEventListener('click', () => {
      const [place, id] = (button.dataset.play ?? '').split(':');
      options.play({ place, id: id || null });
    }),
  );

  // --- While scrolling: the nav and the address ---
  let ticking = false;
  const update = () => {
    ticking = false;
    if (!showing()) return;
    const sec = currentSection();
    const place = sec?.dataset.place;
    if (!place) return;
    links.forEach((a) => (a.dataset.goto === place ? a.setAttribute('aria-current', 'location') : a.removeAttribute('aria-current')));
    // The address names the place being read, so a reload or a shared link opens there.
    const path = options.pathOf(place);
    if (location.pathname !== path) history.replaceState(history.state, '', path + location.search);
  };
  addEventListener('scroll', () => {
    if (!ticking) requestAnimationFrame(update);
    ticking = true;
  }, { passive: true });
  document.addEventListener('game-mode', () => requestAnimationFrame(update));

  // --- The postcard's front: where it is wider than the frame (a phone), open it on Russell ---
  const street = s.querySelector<HTMLElement>('[data-front-scroll]');
  const me = s.querySelector<HTMLElement>('[data-front-russell]');
  if (street && me && street.scrollWidth > street.clientWidth) {
    street.scrollLeft = me.offsetLeft + me.offsetWidth / 2 - street.clientWidth / 2;
  }

  // --- Things wipe in as they scroll into view ---
  const reveals = [...s.querySelectorAll<HTMLElement>('[data-reveal]')];
  if (reducedMotion() || !('IntersectionObserver' in window)) reveals.forEach((el) => el.classList.add('is-in'));
  else {
    const seen = new IntersectionObserver(
      (entries) =>
        entries.forEach((entry) => {
          if (!entry.isIntersecting) return;
          entry.target.classList.add('is-in');
          seen.unobserve(entry.target);
        }),
      { rootMargin: '0px 0px -8% 0px' },
    );
    reveals.forEach((el) => seen.observe(el));
  }

  // In development, a hook for the checks in scripts/check (like gamePut in scene.ts).
  if (import.meta.env.DEV) Object.assign(window, { textAt: showTextAt, textSpot });

  // --- The nav bar slides in once the street (the postcard's front) is out of view ---
  const front = s.querySelector<HTMLElement>('[data-front]');
  if (front && header && 'IntersectionObserver' in window) {
    new IntersectionObserver(([entry]) => header.toggleAttribute('data-past-front', !entry.isIntersecting)).observe(front);
  } else header?.setAttribute('data-past-front', '');

  // --- Opening in the text version: at this page's section (or the thing the address names) ---
  if (!root.classList.contains('game')) {
    const hash = decodeURIComponent(location.hash.slice(1));
    const open = () => showTextAt({ place: options.here, id: hash || null });
    if (hash || options.here !== 'home') {
      open();
      // Pictures above it can still change its place as they load: once more, unless the visitor has scrolled.
      const at = scrollY;
      addEventListener('load', () => scrollY === at && open(), { once: true });
    }
  }
  update();
}
