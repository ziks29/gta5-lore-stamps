/*! GTA V Lore Stamps · stamp-wear.js · (c) 2026 ziks (github.com/ziks29) · MIT License
 *  https://github.com/ziks29/gta5-lore-stamps */
/* stamp-wear.js: random rubber-stamp wear for the GTA stamp SVGs.
 *
 *   stampWear(svgElement, { seed, density, dry, scratches, rotate })
 *     svgElement  inline <svg class="gta-stamp"> (use inlineStamp() for <img>)
 *     seed        number or string; same seed = same wear. Omit for random.
 *     density     0..2  amount of speckle (default 1)
 *     dry         0..2  strength of the faded "dry" spot (default 1)
 *     scratches   number of thin scratches (default 6)
 *     rotate      true = also tilt the stamp randomly by ±8°, or pass degrees
 *   returns the seed that was used (save it to reproduce the same wear).
 *
 *   inlineStamp(imgElement) -> Promise<svgElement>   swaps an <img src="x.svg"> for inline SVG.
 */
(function (g) {
  const NS = 'http://www.w3.org/2000/svg';
  let uid = 0;

  function rng(seed) {                       // mulberry32
    let a = typeof seed === 'number' ? seed >>> 0 : [...String(seed)].reduce((h, c) => Math.imul(h ^ c.charCodeAt(0), 2654435761) >>> 0, 1779033703);
    return () => { a |= 0; a = (a + 0x6D2B79F5) | 0; let t = Math.imul(a ^ (a >>> 15), 1 | a); t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t; return ((t ^ (t >>> 14)) >>> 0) / 4294967296; };
  }

  // give every instance its own ids so many copies of one stamp can share a page
  function uniquify(svg) {
    const suf = '-w' + (++uid), map = {};
    svg.querySelectorAll('[id]').forEach(el => { map[el.id] = el.id + suf; el.id += suf; });
    svg.querySelectorAll('*').forEach(el => {
      for (const at of ['mask', 'clip-path', 'style']) {
        const v = el.getAttribute(at); if (!v || !v.includes('url(#')) continue;
        el.setAttribute(at, v.replace(/url\(#([^)]+)\)/g, (m, id) => `url(#${map[id] || id})`));
      }
    });
  }

  function stampWear(svg, o = {}) {
    if (!svg.dataset.wearReady) { uniquify(svg); svg.dataset.wearReady = '1'; }
    const mask = svg.querySelector('mask[id*="-wear"]');
    if (!mask) throw new Error('stampWear: no wear mask in this SVG');
    const seed = o.seed ?? Math.floor(Math.random() * 1e9), R = rng(seed);
    const dens = o.density ?? 1, dryK = o.dry ?? 1, nScr = o.scratches ?? 6;
    const u = (a, b) => a + (b - a) * R(), pick = arr => arr[Math.floor(R() * arr.length)];
    const [x0, y0, x1, y1] = [20, 20, 780, 780];
    let blots = '', soft = '', scr = '';

    const add = (x, y, r) => {
      if (r < 2.2) { blots += `<circle cx="${x.toFixed(1)}" cy="${y.toFixed(1)}" r="${r}"/>`; return; }
      const k = 6 + Math.floor(R() * 4); let d = '';
      for (let j = 0; j < k; j++) {
        const a = j * 2 * Math.PI / k + u(-.3, .3), rr = r * u(.55, 1.15);
        d += (j ? 'L' : 'M') + (x + rr * Math.cos(a)).toFixed(1) + ' ' + (y + rr * Math.sin(a)).toFixed(1);
      }
      blots += `<path d="${d}Z"/>`;
    };
    for (let i = 0; i < 1500 * dens; i++) add(u(x0, x1), u(y0, y1), pick([.6, .8, 1, 1.2, 1.5, 1.9]));
    for (let i = 0; i < 70 * dens; i++) add(u(x0, x1), u(y0, y1), u(2.4, 5.5));
    // dry spot: random place on the ring, random size
    const da = u(0, 2 * Math.PI), dd = u(120, 300), dx = 400 + dd * Math.cos(da), dy = 400 + dd * Math.sin(da), dr = u(80, 140);
    for (let i = 0; i < 700 * dens * dryK; i++) { const a = u(0, 2 * Math.PI), rr = dr * Math.sqrt(R()); add(dx + rr * Math.cos(a), dy + rr * Math.sin(a), pick([.8, 1.2, 1.6, 2.6, 3.4])); }
    for (let i = 0; i < nScr; i++) {
      const x = u(x0, x1), y = u(y0, y1), a = u(0, Math.PI), l = u(30, 110);
      scr += `<path d="M${x.toFixed(1)} ${y.toFixed(1)}l${(l * Math.cos(a)).toFixed(1)} ${(l * Math.sin(a)).toFixed(1)}" stroke="#000" stroke-width="${u(.8, 1.8).toFixed(1)}" fill="none"/>`;
    }
    for (let i = 0; i < 6; i++) soft += `<circle cx="${u(x0, x1).toFixed(0)}" cy="${u(y0, y1).toFixed(0)}" r="${u(60, 150).toFixed(0)}" fill="#000" opacity="${(u(.06, .16) * .8).toFixed(2)}"/>`;
    mask.innerHTML = `<rect width="800" height="800" fill="#fff"/>${soft}<g fill="#000">${blots}${scr}</g>`;

    if (o.rotate) {
      const deg = typeof o.rotate === 'number' ? o.rotate : u(-8, 8);
      svg.style.transform = `rotate(${deg.toFixed(1)}deg)`;
    }
    return seed;
  }

  async function inlineStamp(img) {
    const txt = await (await fetch(img.src)).text();
    const box = document.createElement('div'); box.innerHTML = txt;
    const svg = box.querySelector('svg');
    if (img.className) svg.classList.add(...img.classList);
    if (img.width) svg.setAttribute('width', img.width), svg.setAttribute('height', img.height || img.width);
    img.replaceWith(svg); return svg;
  }

  g.stampWear = stampWear; g.inlineStamp = inlineStamp;
})(typeof window !== 'undefined' ? window : globalThis);
