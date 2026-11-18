/**
 * Content panels: the <section data-panel id="..."> blocks in each page's HTML.
 *
 * In the game, one is open at a time. Opening one puts its id in the address
 * (/projects#odin), so links to it work and the Back button closes it. In the
 * text version they are simply the sections of an ordinary page.
 */
import { gameOn } from './view';
import { releaseAll } from './input';

type Listener = (id: string | null) => void;

export class Panels {
  current: string | null = null;
  private listeners: Listener[] = [];
  /** Where focus goes back to when a panel closes. */
  private returnTo: HTMLElement | null = null;

  constructor(private readonly home: HTMLElement) {
    document.querySelectorAll<HTMLButtonElement>('[data-panel-close]').forEach((button) =>
      button.addEventListener('click', () => this.close()),
    );
    // Esc inside a panel closes it (the game's own keys ignore panels).
    document.addEventListener('keydown', (event) => {
      if (event.key !== 'Escape' || !this.current || !gameOn()) return;
      const inPanel = (event.target as Element | null)?.closest?.('[data-panel]');
      if (!inPanel) return;
      // An open <dialog> inside the panel (a certificate) takes its own Esc.
      if (document.querySelector('dialog[open]')) return;
      event.preventDefault();
      this.close();
    });
    window.addEventListener('popstate', () => this.sync());
    window.addEventListener('hashchange', () => this.sync());
  }

  has(id: string) {
    return Boolean(this.element(id));
  }

  element(id: string) {
    const el = document.getElementById(id);
    return el?.hasAttribute('data-panel') ? el : null;
  }

  /** The panel the address asks for, if any. */
  fromAddress() {
    const id = decodeURIComponent(location.hash.slice(1));
    return id && this.has(id) ? id : null;
  }

  onChange(listener: Listener) {
    this.listeners.push(listener);
  }

  open(id: string, { address = true } = {}) {
    const el = this.element(id);
    if (!el) {
      console.warn(`No panel with the id ${id} on this page`);
      return;
    }
    if (this.current !== id) {
      this.current = id;
      this.show(id);
      if (address && location.hash !== `#${id}`) history.pushState({ panel: id }, '', `#${id}`);
    }
    releaseAll();
    this.returnTo = this.home;
    el.querySelector<HTMLElement>('[data-panel-title]')?.focus({ preventScroll: true });
  }

  close() {
    if (!this.current) return;
    const id = this.current;
    this.current = null;
    this.show(null);
    if (history.state?.panel === id) history.back();
    else if (location.hash) history.replaceState(history.state, '', location.pathname + location.search);
    this.returnTo?.focus({ preventScroll: true });
  }

  /** Follows the address after Back, Forward or a link to #id. */
  private sync() {
    if (!gameOn()) return;
    const id = this.fromAddress();
    if (id === this.current) return;
    this.current = id;
    this.show(id);
    if (!id) this.returnTo?.focus({ preventScroll: true });
  }

  private show(id: string | null) {
    document.querySelectorAll<HTMLElement>('[data-panel]').forEach((panel) => {
      panel.toggleAttribute('data-open', panel.id === id);
    });
    document.documentElement.toggleAttribute('data-panel-open', Boolean(id));
    this.listeners.forEach((l) => l(id));
  }
}
