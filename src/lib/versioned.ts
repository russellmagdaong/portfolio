import { createHash } from 'node:crypto';
import { readFileSync } from 'node:fs';
import { url } from './url';

/**
 * The address of a file in public/, with a short fingerprint of its contents on the end.
 *
 * Browsers hold on to a site's icon, and link-preview sites to its picture, long after the
 * file has changed, because the address is still the same. The fingerprint changes whenever
 * the file does, which makes it a new address that they have to fetch.
 *
 * It reads the file from disk, so it can only be used while a page is being built, not in a
 * script that runs in the browser.
 */
export const versioned = (path: string) => {
  const fingerprint = createHash('sha1').update(readFileSync(`public${path}`)).digest('hex').slice(0, 8);
  return `${url(path)}?v=${fingerprint}`;
};
