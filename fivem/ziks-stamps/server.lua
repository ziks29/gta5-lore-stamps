-- ziks-stamps · server · MIT © 2026 ziks (github.com/ziks29)
local RES = GetCurrentResourceName()
local catalog, byName = {}, {}

do
    local raw = LoadResourceFile(RES, 'html/stamps.json')
    catalog = raw and json.decode(raw) or { seals = {}, status = {}, mini = {} }
    for group, list in pairs(catalog) do
        for _, s in ipairs(list) do s.group = group; byName[s.name] = s end
    end
end

-- framework ---------------------------------------------------------------
local function detectFramework()
    if Config.Framework ~= 'auto' then return Config.Framework end
    if GetResourceState('qbx_core') == 'started' then return 'qbx' end
    if GetResourceState('qb-core') == 'started' then return 'qb' end
    if GetResourceState('es_extended') == 'started' then return 'esx' end
    return 'standalone'
end

--- Name and badge/callsign of a player, from the framework when available.
local function getOfficer(src)
    if not src then return nil, nil end
    local fw = detectFramework()
    local ok, name, badge = pcall(function()
        local p
        if fw == 'qbx' then p = exports.qbx_core:GetPlayer(src)
        elseif fw == 'qb' then p = exports['qb-core']:GetCoreObject().Functions.GetPlayer(src)
        elseif fw == 'esx' then
            local x = exports.es_extended:getSharedObject().GetPlayerFromId(src)
            if x then return x.getName(), nil end
        end
        if p then
            local c = p.PlayerData.charinfo
            return ('%s. %s'):format(c.firstname:sub(1, 1), c.lastname), p.PlayerData.metadata and p.PlayerData.metadata.callsign
        end
    end)
    if ok and name then
        if badge == 'NO CALLSIGN' or badge == '' then badge = nil end
        return name, badge and ('#' .. tostring(badge):gsub('^#', '')) or nil
    end
    return GetPlayerName(src) or 'UNKNOWN', nil
end

-- date: real server clock or the player's in-game clock ---------------------
local clockReq, clockId = {}, 0
RegisterNetEvent('ziks-stamps:server:clock', function(id, c)
    local r = clockReq[id]
    if r and r.src == source then
        clockReq[id] = nil
        r.p:resolve(type(c) == 'table' and c or nil)
    end
end)

local function ingameClock(src)
    clockId = clockId + 1
    local id, p = clockId, promise.new()
    clockReq[id] = { p = p, src = src }
    TriggerClientEvent('ziks-stamps:client:clock', src, id)
    SetTimeout(Config.ClockTimeout or 800, function()
        if clockReq[id] then clockReq[id] = nil; p:resolve(nil) end
    end)
    return Citizen.Await(p)
end

--- Formatted date for the DATE field. Config.DateSource = 'ingame' uses the player's game clock.
local function getDate(src, fmt)
    fmt = fmt or Config.DateFormat
    if Config.DateSource == 'ingame' and src then
        local c = ingameClock(src)
        if c and tonumber(c.y) and tonumber(c.m) and tonumber(c.d) then
            local t = os.time({ year = c.y, month = c.m, day = c.d, hour = c.h or 12, min = c.min or 0 })
            if t then return os.date(fmt, t):upper() end
        end
    end
    return os.date(fmt):upper()
end

-- create ------------------------------------------------------------------
--- Create stamp data (not saved).
--- @param src number|nil  player server id (fills BY / BADGE / in-game date), nil for system stamps
--- @param name string     '00-lspd', 'approved', '13-fib-mini' …
--- @param opts table|nil  { ink, tilt, seed, fields = { date, by, case, badge } }
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
        stamp = s.name, file = s.file, title = s.title, group = s.group,
        ink = opts.ink or s.ink,
        seed = opts.seed or math.random(1, 2147483646),
        tilt = math.floor(tilt * 10 + 0.5) / 10,
        fields = { date = f.date or getDate(src), by = f.by or by, case = f.case, badge = f.badge or badge },
        at = os.time(),
        license = src and GetPlayerIdentifierByType(src, 'license') or nil,
    }
end

-- storage: oxmysql, falls back to KVP ----------------------------------------
local mode = 'none'
local function sql(method, q, p)
    local pr = promise.new()
    exports.oxmysql[method](nil, q, p or {}, function(r) pr:resolve(r) end)
    return Citizen.Await(pr)
end

CreateThread(function()
    local want = Config.Storage
    if want == 'auto' then want = GetResourceState('oxmysql') == 'started' and 'oxmysql' or 'kvp' end
    if want == 'oxmysql' then
        local ok = pcall(sql, 'query', ([[CREATE TABLE IF NOT EXISTS `%s` (
            `id` INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
            `doc_id` VARCHAR(64) NOT NULL,
            `stamp` VARCHAR(64) NOT NULL,
            `data` LONGTEXT NOT NULL,
            `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
            INDEX `doc_id` (`doc_id`))]]):format(Config.TableName))
        mode = ok and 'oxmysql' or 'kvp'
        if not ok then print('^3[ziks-stamps] oxmysql table setup failed, using KVP storage^7') end
    else
        mode = want
    end
end)

local function kvpKey(docId) return ('stamps:%s'):format(docId) end
local function kvpGet(docId) return json.decode(GetResourceKvpString(kvpKey(docId)) or '[]') or {} end
local function kvpSet(docId, list)
    if #list == 0 then DeleteResourceKvp(kvpKey(docId)) else SetResourceKvp(kvpKey(docId), json.encode(list)) end
end

local function save(docId, data)
    if mode == 'oxmysql' then
        data.id = sql('insert', ('INSERT INTO `%s` (doc_id, stamp, data) VALUES (?, ?, ?)'):format(Config.TableName),
            { docId, data.stamp, json.encode(data) })
    elseif mode == 'kvp' then
        local list = kvpGet(docId)
        data.id = (list[#list] and list[#list].id or 0) + 1
        list[#list + 1] = data
        kvpSet(docId, list)
    end
    data.doc_id = docId
    return data
end

--- All stamps on a document, oldest first.
local function GetDocumentStamps(docId)
    docId = tostring(docId)
    if mode == 'oxmysql' then
        local rows = sql('query', ('SELECT id, data FROM `%s` WHERE doc_id = ? ORDER BY id'):format(Config.TableName), { docId }) or {}
        local out = {}
        for i, r in ipairs(rows) do
            local d = json.decode(r.data) or {}
            d.id, d.doc_id = r.id, docId
            out[i] = d
        end
        return out
    elseif mode == 'kvp' then
        local list = kvpGet(docId)
        for _, d in ipairs(list) do d.doc_id = docId end
        return list
    end
    return {}
end

--- Remove one stamp (stampId) or every stamp (stampId = nil) from a document.
local function RemoveStamps(docId, stampId)
    docId = tostring(docId)
    if mode == 'oxmysql' then
        if stampId then sql('update', ('DELETE FROM `%s` WHERE doc_id = ? AND id = ?'):format(Config.TableName), { docId, stampId })
        else sql('update', ('DELETE FROM `%s` WHERE doc_id = ?'):format(Config.TableName), { docId }) end
    elseif mode == 'kvp' then
        local keep = {}
        if stampId then for _, d in ipairs(kvpGet(docId)) do if d.id ~= stampId then keep[#keep + 1] = d end end end
        kvpSet(docId, keep)
    end
    return true
end

--- Create a stamp AND save it on a document in one call.
--- @return table|nil data (with id + doc_id), string|nil err
local function Stamp(src, docId, name, opts)
    if docId == nil then return nil, 'docId is required' end
    local data, err = CreateStamp(src, name, opts)
    if not data then return nil, err end
    return save(tostring(docId), data)
end

--- Show a document's saved stamps on a player's screen.
--- @param opts table|nil { title = 'ARREST REPORT', lines = { 'Suspect: …' }, focus = true }
local function ShowDocument(src, docId, opts)
    opts = opts or {}
    opts.stamps = GetDocumentStamps(docId)
    opts.docId = tostring(docId)
    TriggerClientEvent('ziks-stamps:client:show', src, opts)
    return #opts.stamps
end

exports('CreateStamp', CreateStamp)
exports('Stamp', Stamp)
exports('GetDocumentStamps', GetDocumentStamps)
exports('RemoveStamps', RemoveStamps)
exports('ShowDocument', ShowDocument)
exports('GetStamps', function() return catalog end)
exports('GetOfficer', getOfficer)
exports('GetDate', getDate)
exports('GetStorage', function() return mode end)

-- gallery ------------------------------------------------------------------
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
