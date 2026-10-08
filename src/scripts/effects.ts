// Page-wide motion: scroll-in reveals, the "decoding" headings, and the pointer spotlight on panels.
// The matching styles are at the bottom of src/styles/global.css.

const reducedMotion = matchMedia('(prefers-reduced-motion: reduce)').matches;

// Tells the fail-safe in Base.astro that reveals are being handled.
document.documentElement.dataset.effects = 'on';

const GLYPHS = 'ABCDEFGHJKLMNPQRSTUVWXYZ0123456789#/<>_';
const SCRAMBLE_MS = 900;
const SHUFFLE_EVERY_MS = 45;

/**
 * Makes a heading look like it is being decrypted: every letter cycles through random glyphs,
 * then they lock in from left to right. Each letter's box is frozen at its final width first,
 * so the line never reflows while it runs. The heading carries data-scrambling for as long as
 * it does, which holds off the banded fill in global.css until the text is whole again.
 */
function scramble(el: HTMLElement) {
  const text = el.textContent?.trim() ?? '';
  if (reducedMotion || !text) return;

  // Screen readers get the real text once; the animated letters are hidden from them.
  el.setAttribute('aria-label', text);
  el.dataset.scrambling = '';
  el.textContent = '';

  const letters: { span: HTMLSpanElement; final: string }[] = [];
  for (const word of text.split(/\s+/)) {
    const wordSpan = document.createElement('span');
    wordSpan.setAttribute('aria-hidden', 'true');
    wordSpan.style.whiteSpace = 'nowrap';
    for (const char of word) {
      const span = document.createElement('span');
      span.textContent = char;
      span.style.display = 'inline-block';
      wordSpan.append(span);
      letters.push({ span, final: char });
    }
    el.append(wordSpan, ' ');
  }

  for (const { span } of letters) {
    span.style.width = `${span.getBoundingClientRect().width}px`;
    span.style.textAlign = 'center';
  }

  const start = performance.now();
  let lastShuffle = 0;

  const frame = (now: number) => {
    const progress = Math.min(1, (now - start) / SCRAMBLE_MS);
    const settled = Math.floor(progress * letters.length);
    const shuffle = now - lastShuffle >= SHUFFLE_EVERY_MS;
    if (shuffle) lastShuffle = now;

    letters.forEach(({ span, final }, i) => {
      if (i < settled) {
        span.textContent = final;
        span.style.color = '';
      } else if (shuffle) {
        span.textContent = GLYPHS[Math.floor(Math.random() * GLYPHS.length)];
        span.style.color = 'var(--accent, var(--color-cyan))';
      }
    });

    if (progress < 1) {
      requestAnimationFrame(frame);
    } else {
      // Back to the plain text it started as, so it wraps and styles like any other heading.
      el.textContent = text;
      el.removeAttribute('aria-label');
      delete el.dataset.scrambling;
    }
  };

  requestAnimationFrame(frame);
}

// Long enough for the slowest staggered child to finish before hover styles are handed back.
const SETTLE_MS = 2000;

const observer = new IntersectionObserver(
  (entries) => {
    for (const entry of entries) {
      if (!entry.isIntersecting) continue;
      const el = entry.target as HTMLElement;
      // A stage that is switched off (Stage.astro) is still on the page, and can be within the
      // window. Its blocks wait until it is switched on; see the listener below.
      if (el.closest('[data-screen="off"]')) continue;
      observer.unobserve(el);
      el.classList.add('is-in');
      setTimeout(() => el.classList.add('is-done'), SETTLE_MS);
      el.querySelectorAll<HTMLElement>('[data-scramble]').forEach(scramble);
    }
  },
  { rootMargin: '0px 0px -8% 0px' },
);

// While the entry screen (Entry.astro) is up, nothing is watched yet: whatever is on the first
// screenful should animate in when the visitor arrives, not behind the entry screen.
const watch = () => document.querySelectorAll('[data-reveal], [data-stagger]').forEach((el) => observer.observe(el));
if (document.documentElement.classList.contains('gated')) {
  document.addEventListener('site:enter', watch, { once: true });
} else {
  watch();
}

// A link to a section that is already on screen moves nothing (Stage.astro), so its title is
// run through the scramble again, to show that the click landed.
document.addEventListener('stage:focus', (event) => {
  (event.target as HTMLElement).querySelectorAll<HTMLElement>('[data-scramble]:not([data-scrambling])').forEach((title) => {
    if (title.closest('[data-reveal]')?.classList.contains('is-in')) scramble(title);
  });
});

// When a stage is switched on, look again at whatever in it has not come in yet. The observer
// only reports a block when it moves in or out of the window, and these may not have moved.
document.addEventListener('stage:change', (event) => {
  if (document.documentElement.classList.contains('gated')) return;
  const waiting = (event.target as HTMLElement).querySelectorAll('[data-reveal]:not(.is-in), [data-stagger]:not(.is-in)');
  waiting.forEach((el) => {
    observer.unobserve(el);
    observer.observe(el);
  });
});

// Panels with data-spotlight light up under the pointer.
document.querySelectorAll<HTMLElement>('[data-spotlight]').forEach((el) => {
  el.addEventListener('pointermove', (event) => {
    const box = el.getBoundingClientRect();
    // A panel on an enlarged stage (Stage.astro) is drawn bigger than it is laid out. The
    // pointer is measured as drawn; the styles want it as laid out.
    const drawn = box.width / el.offsetWidth || 1;
    el.style.setProperty('--mx', `${(event.clientX - box.left) / drawn}px`);
    el.style.setProperty('--my', `${(event.clientY - box.top) / drawn}px`);
  });
  el.addEventListener('pointerleave', () => {
    el.style.removeProperty('--mx');
    el.style.removeProperty('--my');
  });
});
