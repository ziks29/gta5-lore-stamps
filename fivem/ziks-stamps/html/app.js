// ziks-stamps · NUI (gallery + viewer) · MIT © 2026 ziks (github.com/ziks29)
const $ = id => document.getElementById(id);
const RES = typeof GetParentResourceName === 'function' ? GetParentResourceName() : 'ziks-stamps';
const post = (ev, body = {}) => fetch(`https://${RES}/${ev}`, { method: 'POST', body: JSON.stringify(body) }).catch(() => {});
let catalog = { seals: [], status: [], mini: [] }, tab = 'seals', pick = null;
const esc = s => String(s ?? '').replace(/[&<>"]/g, c => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' }[c]));

// ── gallery ──────────────────────────────────────────────
function list() {
  const q = $('q').value.trim().toLowerCase();
  $('items').innerHTML = '';
  for (const s of catalog[tab] || []) {
    if (q && !(s.title + ' ' + s.name).toLowerCase().includes(q)) continue;
    const el = document.createElement('div');
    el.className = 'it' + (pick && pick.name === s.name ? ' on' : '');
    el.innerHTML = `<img src="${s.file}" loading="lazy"><span>${esc(s.title)}</span>`;
    el.onclick = () => { pick = s; if ($('own').checked) $('ink').value = s.ink; list(); };
    $('items').appendChild(el);
  }
}

async function drop(data) {
  const paper = $('paper'), holder = document.createElement('div');
  const wide = data.file.includes('/status/');
  holder.className = 'drop' + (wide ? ' wide' : '');
  const SLOTS = [[6, 38], [52, 40], [8, 66], [50, 68]], n = paper.querySelectorAll('.drop').length;
  const [sx, sy] = SLOTS[n % SLOTS.length];
  holder.style.left = Math.min(sx + Math.random() * 4, wide ? 40 : 54) + '%';
  holder.style.top = Math.min(sy + Math.random() * 4, wide ? 74 : 66) + '%';
  holder.style.setProperty('--r', (data.tilt || 0) + 'deg');
  holder.style.transform = `rotate(${data.tilt || 0}deg)`;
  paper.appendChild(holder);
  await renderStamp(holder, { url: data.file, seed: data.seed, ink: data.ink, fields: data.fields });
  holder.classList.add('anim');
  $('meta').textContent = `${data.title} · seed ${data.seed} · ${data.fields.date}${data.fields.by ? ' · ' + data.fields.by : ''}`;
}

// ── viewer: ShowStamp / ShowStamps / ShowDocument ─────────
let hideTimer = null;
async function show(m) {
  const v = $('view');
  clearTimeout(hideTimer);
  v.innerHTML = ''; v.className = 'on' + (m.focus ? ' focus' : '');
  const stamps = (m.stamps || []).filter(s => s && s.file);
  const put = async (holder, s) => {
    holder.style.transform = `rotate(${s.tilt || 0}deg)`;
    await renderStamp(holder, { url: s.file, seed: s.seed, ink: s.ink, fields: s.fields || {} });
  };
  if (m.paper) {
    const doc = document.createElement('div'); doc.className = 'doc';
    doc.innerHTML = (m.title ? `<h2>${esc(m.title)}</h2>` : '') + (m.lines || []).map(l => `<p>${esc(l)}</p>`).join('');
    v.appendChild(doc);
    // 2x2 grid in the lower part of the page (then repeats, slightly shifted)
    const slots = [[54, 52], [6, 54], [56, 76], [8, 78]];
    stamps.forEach((s, i) => {
      const wide = s.file.includes('/status/'), h = document.createElement('div');
      h.className = 'st'; h.style.width = wide ? '40%' : '28%';
      const [x, y] = slots[i % slots.length], k = Math.floor(i / slots.length) * 3;
      h.style.left = Math.min(x + k, wide ? 56 : 66) + '%'; h.style.top = Math.min(y - k, wide ? 82 : 77) + '%';
      doc.appendChild(h); put(h, s);
    });
  } else {
    const row = document.createElement('div');
    row.className = 'solo pos-' + (m.position || 'center'); row.style.setProperty('--sz', (m.size || 22) + 'vh');
    v.appendChild(row);
    for (const s of stamps) { const h = document.createElement('div'); if (s.file.includes('/status/')) h.style.width = `calc(var(--sz) * 1.5)`; row.appendChild(h); put(h, s); }
  }
  if (m.focus) {
    const x = document.createElement('button'); x.className = 'x'; x.textContent = 'Close · Esc';
    x.onclick = () => post('hide'); v.appendChild(x);
  }
  if (m.duration > 0) hideTimer = setTimeout(() => post('hide'), m.duration);
}
function hide() { clearTimeout(hideTimer); $('view').className = ''; $('view').innerHTML = ''; }

window.addEventListener('message', ({ data: m }) => {
  if (m.action === 'open') { catalog = m.catalog || catalog; $('app').classList.add('on'); list(); }
  else if (m.action === 'close') $('app').classList.remove('on');
  else if (m.action === 'stamped') drop(m.data);
  else if (m.action === 'show') show(m);
  else if (m.action === 'hide') hide();
});

document.querySelectorAll('.tabs button').forEach(b => b.onclick = () => {
  document.querySelectorAll('.tabs button').forEach(x => x.classList.toggle('on', x === b)); tab = b.dataset.t; list();
});
$('q').oninput = list;
$('go').onclick = () => {
  if (!pick) { $('meta').textContent = 'Pick a stamp first.'; return; }
  post('stamp', { name: pick.name, ink: $('own').checked ? null : $('ink').value, fields: { case: $('case').value || null } });
};
$('clear').onclick = () => document.querySelectorAll('#paper .drop').forEach(e => e.remove());
$('close').onclick = () => post('close');
document.addEventListener('keydown', e => {
  if (e.key !== 'Escape') return;
  if ($('view').classList.contains('focus')) post('hide');
  else if ($('app').classList.contains('on')) post('close');
});

// browser preview without FiveM: ?preview (gallery) or ?viewer (ShowDocument demo)
if (location.search.includes('preview')) {
  fetch('stamps.json').then(r => r.json()).then(c => window.postMessage({ action: 'open', catalog: c }, '*'));
  $('go').onclick = () => {
    if (!pick) return;
    drop({ file: pick.file, title: pick.title, ink: $('own').checked ? pick.ink : $('ink').value, seed: Math.floor(Math.random() * 1e9),
           tilt: +(Math.random() * 16 - 8).toFixed(1), fields: { date: '17 OCT 2026', by: 'J. REYES', badge: '#1142', case: $('case').value || null } });
  };
}
if (location.search.includes('viewer')) {
  const f = { date: '17 OCT 2026', by: 'SGT. J. REYES', badge: '#1142', case: 'LS-24-0815' };
  window.postMessage({ action: 'show', paper: true, focus: true, title: 'ARREST REPORT · LSPD',
    lines: ['Suspect: Franklin Clinton', 'Charge: Grand theft auto (x3)', 'Location: Strawberry Ave', 'Officer: Sgt. J. Reyes #1142', '', 'Evidence logged under case LS-24-0815.'],
    stamps: [{ file: 'svg/00-lspd.svg', ink: '#1c3a8c', seed: 7, tilt: -5, fields: f },
             { file: 'svg/status/evidence.svg', ink: '#1c3a8c', seed: 11, tilt: 4, fields: f },
             { file: 'svg/status/approved.svg', ink: '#1e7a34', seed: 3, tilt: -2, fields: f }] }, '*');
}
