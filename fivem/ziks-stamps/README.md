# ziks-stamps (FiveM resource)

A drop-in resource for the GTA V Lore Stamps. It gives you:
- every stamp as a NUI file, usable from any other resource's NUI;
- a server export that creates stamp data with the date, officer name and badge filled in, plus a seed;
- a `/stamps` gallery for testing and showing off the stamps;
- a JS renderer that applies random wear, ink colour and the text fields.

The resource is standalone. It reads the player's name and callsign automatically on **qbx_core**, **qb-core** and **es_extended**.

## Install
1. Copy `ziks-stamps` into your `resources` folder.
2. Add `ensure ziks-stamps` to `server.cfg`.
3. Restart the server, or run `refresh` then `ensure ziks-stamps`.
4. In game, type `/stamps` to open the gallery.

## Server export: create a stamp

```lua
local stamp = exports['ziks-stamps']:CreateStamp(source, 'approved', {
    fields = { case = 'LS-24-0815' },  -- date / by / badge are filled automatically
    -- ink = '#b11f2b', tilt = 0, seed = 123
})
-- save `stamp` (a plain table) with your document, e.g. json.encode(stamp) in your DB
```

It returns:
```lua
{
  stamp = 'approved', file = 'svg/status/approved.svg', title = 'Approved',
  ink = '#1e7a34', seed = 1838201, tilt = -3.4, at = 1792233600,
  fields = { date = '17 OCT 2026', by = 'J. Reyes', badge = '#1142', case = 'LS-24-0815' }
}
```

Other exports:
- `exports['ziks-stamps']:GetStamps()`: the full catalog (`seals`, `status`, `mini`).
- `exports['ziks-stamps']:GetOfficer(source)`: returns `name, badge`.
- Client side, `exports['ziks-stamps']:GetBaseUrl()` returns `https://cfx-nui-ziks-stamps/html/`. Send this to your NUI.

## Showing it in your own NUI

```html
<script src="https://cfx-nui-ziks-stamps/html/stamp-wear.js"></script>
<div id="stamp-slot" style="width:180px"></div>
<script>
// stamp = the table from CreateStamp, sent to your NUI with the document
renderStamp(document.getElementById('stamp-slot'), {
  url: 'https://cfx-nui-ziks-stamps/html/' + stamp.file,
  seed: stamp.seed, ink: stamp.ink, fields: stamp.fields,
}).then(({ svg }) => { svg.style.transform = `rotate(${stamp.tilt}deg)`; });
</script>
```

Because the stamp is rendered from the same seed, it looks identical every time the document is opened.

If your NUI can't fetch files from another resource, copy `html/stamp-wear.js` and the SVGs into your own resource; the code stays the same.
As a last resort, `renderStamp` falls back to a plain `<img>` that shows the default wear.

Tip: `mix-blend-mode: multiply` on the stamp makes it look printed on the paper.

## Config (`config.lua`)
| Key | Default | Description |
|---|---|---|
| `Command` | `'stamps'` | gallery command name; set to `false` to disable it |
| `AcePermission` | `false` | `true` requires the ace `command.stamps` |
| `DateFormat` | `'%d %b %Y'` | `os.date` format for the DATE field |
| `Framework` | `'auto'` | `'qbx'`, `'qb'`, `'esx'` or `'standalone'` |
| `MaxTilt` | `8` | random tilt range in degrees |

MIT © 2026 ziks (github.com/ziks29). Keep the license notice when you redistribute.
