Config = {}

-- /stamps gallery command (false = disabled). AcePermission = true requires ace 'command.stamps'.
Config.Command = 'stamps'
Config.AcePermission = false

-- DATE field source:
--   'real'   = server clock
--   'ingame' = the stamping player's in-game clock (needs a player source;
--              falls back to the server clock after Config.ClockTimeout ms)
Config.DateSource = 'real'
-- os.date format. '%d %b %Y' -> 17 OCT 2026, '%d.%m.%Y %H:%M' -> 17.10.2026 14:30 (text is uppercased)
Config.DateFormat = '%d %b %Y'
Config.ClockTimeout = 800

-- 'auto' detects qbx_core, qb-core or es_extended. 'standalone' uses the FiveM player name.
Config.Framework = 'auto'

-- Where Stamp() saves stamps: 'auto' (oxmysql if started, else KVP), 'oxmysql', 'kvp' or 'none'.
Config.Storage = 'auto'
Config.TableName = 'ziks_stamps'

-- Random tilt range in degrees for new stamps (0 = always straight).
Config.MaxTilt = 8

-- Seconds a player must wait between stamps created through the gallery.
Config.Cooldown = 1
