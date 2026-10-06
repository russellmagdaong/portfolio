const base = import.meta.env.BASE_URL.replace(/\/$/, '');

/** Prefix an internal path with the configured `base`, so links survive a sub-path deploy. */
export const url = (path: string) => `${base}${path}`;
