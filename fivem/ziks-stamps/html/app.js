// ziks-stamps · NUI gallery · MIT © 2026 ziks (github.com/ziks29)
const $ = id => document.getElementById(id);
const RES = typeof GetParentResourceName === 'function' ? GetParentResourceName() : 'ziks-stamps';
const post = (ev, body = {}) => fetch(`https://${RES}/${ev}`, { method: 'POST', body: JSON.stringify(body) }).catch(() => {});
let catalog = { seals: [], status: [], mini: [] }, tab = 'seals', pick = null;

function list() {
  const q = $('q').value.trim().toLowerCase();
  $('items').innerHTML = '';
  for (const s of catalog[tab] || []) {
    if (q && !(s.title + ' ' + s.name).toLowerCase().includes(q)) continue;
    const el = document.createElement('div');
    el.className = 'it' + (pick && pick.name === s.name ? ' on' : '');
    el.innerHTML = `<img src="${s.file}" loading="lazy"><span>${s.title}</span>`;
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

window.addEventListener('message', ({ data: m }) => {
  if (m.action === 'open') { catalog = m.catalog || catalog; $('app').classList.add('on'); list(); }
  else if (m.action === 'close') $('app').classList.remove('on');
  else if (m.action === 'stamped') drop(m.data);
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
document.addEventListener('keydown', e => { if (e.key === 'Escape') post('close'); });

// browser preview without FiveM: open with ?preview
if (location.search.includes('preview')) {
  fetch('stamps.json').then(r => r.json()).then(c => {
    window.postMessage({ action: 'open', catalog: c }, '*');
    window.post = null;
  });
  $('go').onclick = () => {
    if (!pick) return;
    drop({ file: pick.file, title: pick.title, ink: $('own').checked ? pick.ink : $('ink').value, seed: Math.floor(Math.random() * 1e9),
           tilt: +(Math.random() * 16 - 8).toFixed(1), fields: { date: '17 OCT 2026', by: 'J. REYES', badge: '#1142', case: $('case').value || null } });
  };
}
