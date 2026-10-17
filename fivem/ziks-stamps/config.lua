Config = {}

-- Test / showcase command: opens the stamp gallery with a sample document.
-- Set to false to disable. Use AcePermission to limit it (e.g. 'command.stamps').
Config.Command = 'stamps'
Config.AcePermission = false

-- os.date format for the DATE field. '%d %b %Y' -> 17 OCT 2026 (text is uppercased).
Config.DateFormat = '%d %b %Y'

-- 'auto' detects qbx_core, qb-core or es_extended. 'standalone' uses the FiveM player name.
Config.Framework = 'auto'

-- Random tilt range in degrees for new stamps (0 = always straight).
Config.MaxTilt = 8

-- Seconds a player must wait between stamps created through the gallery event.
Config.Cooldown = 1
