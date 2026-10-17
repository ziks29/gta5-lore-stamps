-- ziks-stamps · server · MIT © 2026 ziks (github.com/ziks29)
local RES = GetCurrentResourceName()
local catalog, byName = {}, {}

local function loadCatalog()
    local raw = LoadResourceFile(RES, 'html/stamps.json')
    catalog = raw and json.decode(raw) or { seals = {}, status = {}, mini = {} }
    for group, list in pairs(catalog) do
        for _, s in ipairs(list) do
            s.group = group
            byName[s.name] = s
        end
    end
end
loadCatalog()

local function detectFramework()
    if Config.Framework ~= 'auto' then return Config.Framework end
    if GetResourceState('qbx_core') == 'started' then return 'qbx' end
    if GetResourceState('qb-core') == 'started' then return 'qb' end
    if GetResourceState('es_extended') == 'started' then return 'esx' end
    return 'standalone'
end

--- Name and badge/callsign of the player, from the framework when available.
local function getOfficer(src)
    local fw = detectFramework()
    local ok, name, badge = pcall(function()
        if fw == 'qbx' then
            local p = exports.qbx_core:GetPlayer(src)
            if p then
                local c = p.PlayerData.charinfo
                return ('%s. %s'):format(c.firstname:sub(1, 1), c.lastname), p.PlayerData.metadata and p.PlayerData.metadata.callsign
            end
        elseif fw == 'qb' then
            local QBCore = exports['qb-core']:GetCoreObject()
            local p = QBCore.Functions.GetPlayer(src)
            if p then
                local c = p.PlayerData.charinfo
                return ('%s. %s'):format(c.firstname:sub(1, 1), c.lastname), p.PlayerData.metadata and p.PlayerData.metadata.callsign
            end
        elseif fw == 'esx' then
            local ESX = exports.es_extended:getSharedObject()
            local p = ESX.GetPlayerFromId(src)
            if p then return p.getName(), nil end
        end
    end)
    if ok and name then
        if badge == 'NO CALLSIGN' or badge == '' then badge = nil end
        return name, badge and ('#' .. tostring(badge):gsub('^#', '')) or nil
    end
    return src and GetPlayerName(src) or 'UNKNOWN', nil
end

--- Create stamp data to store with your document.
--- @param src number|nil   player server id (fills BY / BADGE), nil for system stamps
--- @param name string      stamp name, e.g. '00-lspd', 'approved', '13-fib-mini'
--- @param opts table|nil   { ink = '#b11f2b', fields = { date=, by=, case=, badge= }, tilt = 3, seed = 123 }
--- @return table|nil data, string|nil err
local function CreateStamp(src, name, opts)
    opts = opts or {}
    local s = byName[name]
    if not s then return nil, ('unknown stamp "%s"'):format(tostring(name)) end
    local by, badge = getOfficer(src)
    local f = opts.fields or {}
    local tilt = opts.tilt
    if tilt == nil then tilt = (math.random() * 2 - 1) * (Config.MaxTilt or 0) end
    return {
        stamp = s.name,
        file = s.file,                     -- relative to html/, e.g. 'svg/status/approved.svg'
        title = s.title,
        ink = opts.ink or s.ink,
        seed = opts.seed or math.random(1, 2147483646),
        tilt = math.floor(tilt * 10 + 0.5) / 10,
        fields = {
            date = f.date or os.date(Config.DateFormat):upper(),
            by = f.by or by,
            case = f.case,
            badge = f.badge or badge,
        },
        at = os.time(),
    }
end

exports('CreateStamp', CreateStamp)
exports('GetStamps', function() return catalog end)
exports('GetOfficer', getOfficer)

-- gallery / showcase -------------------------------------------------------
local last = {}
RegisterNetEvent('ziks-stamps:server:create', function(name, opts)
    local src = source
    local now = os.time()
    if last[src] and now - last[src] < (Config.Cooldown or 1) then return end
    last[src] = now
    if type(name) ~= 'string' then return end
    opts = type(opts) == 'table' and opts or {}
    local data = CreateStamp(src, name, {
        ink = type(opts.ink) == 'string' and opts.ink:match('^#%x%x%x%x%x%x$') and opts.ink or nil,
        fields = type(opts.fields) == 'table' and {
            case = type(opts.fields.case) == 'string' and opts.fields.case:sub(1, 24) or nil,
        } or nil,
    })
    if data then TriggerClientEvent('ziks-stamps:client:stamped', src, data) end
end)

AddEventHandler('playerDropped', function() last[source] = nil end)
