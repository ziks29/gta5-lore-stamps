-- ziks-stamps · client · MIT © 2026 ziks (github.com/ziks29)
local RES = GetCurrentResourceName()
local catalog = json.decode(LoadResourceFile(RES, 'html/stamps.json') or '{}') or {}
local galleryOpen, viewOpen, viewFocus = false, false, false

local function findStamp(nameOrFile)
    for _, list in pairs(catalog) do
        for _, s in ipairs(list) do
            if s.name == nameOrFile or s.file == nameOrFile then return s end
        end
    end
end

--- URL of a stamp SVG for <img src> / fetch in any NUI.
local function GetStampUrl(nameOrFile)
    local s = findStamp(nameOrFile)
    return ('https://cfx-nui-%s/html/%s'):format(RES, s and s.file or nameOrFile)
end
exports('GetStampUrl', GetStampUrl)
exports('GetBaseUrl', function() return ('https://cfx-nui-%s/html/'):format(RES) end)

-- in-game clock ------------------------------------------------------------
local function gameDate()
    return { y = GetClockYear(), m = GetClockMonth() + 1, d = GetClockDayOfMonth(), h = GetClockHours(), min = GetClockMinutes() }
end
RegisterNetEvent('ziks-stamps:client:clock', function(id) TriggerServerEvent('ziks-stamps:server:clock', id, gameDate()) end)
exports('GetGameDate', gameDate)

-- viewer -------------------------------------------------------------------
local function normalise(s)
    if type(s) == 'string' then
        local c = findStamp(s)
        return c and { file = c.file, title = c.title, ink = c.ink, seed = math.random(1, 2147483646), tilt = 0, fields = {} } or nil
    end
    if type(s) == 'table' and not s.file and s.stamp then
        local c = findStamp(s.stamp); if c then s.file = c.file end
    end
    return s
end

--- Show stamps on screen.
--- @param stamps table  stamp data (from CreateStamp / Stamp / GetDocumentStamps) or stamp names
--- @param opts table|nil
---   title, lines  draw a paper document behind the stamps (lines = list of strings)
---   paper         paper without title/lines (default: true when title or lines are set)
---   position      without paper: 'center' | 'top-right' | 'bottom-right' | 'bottom-left' | 'top-left'
---   size          without paper: stamp width in vh (default 22)
---   duration      ms until it hides itself (0 = until HideStamps / Esc)
---   focus         mouse + Esc/close (default: true with paper, false without)
local function ShowStamps(stamps, opts)
    opts = opts or {}
    local list = {}
    for _, s in ipairs(stamps or {}) do list[#list + 1] = normalise(s) end
    local paper = opts.paper
    if paper == nil then paper = opts.title ~= nil or opts.lines ~= nil end
    local focus = opts.focus
    if focus == nil then focus = paper end
    viewOpen, viewFocus = true, focus
    if focus then SetNuiFocus(true, true) end
    SendNUIMessage({ action = 'show', stamps = list, paper = paper, title = opts.title, lines = opts.lines,
        position = opts.position or 'center', size = opts.size or 22, duration = opts.duration or 0, focus = focus })
end

local function ShowStamp(stamp, opts) ShowStamps({ stamp }, opts) end

local function HideStamps()
    if not viewOpen then return end
    viewOpen = false
    if viewFocus and not galleryOpen then SetNuiFocus(false, false) end
    SendNUIMessage({ action = 'hide' })
end

exports('ShowStamps', ShowStamps)
exports('ShowStamp', ShowStamp)
exports('HideStamps', HideStamps)
exports('IsShowing', function() return viewOpen end)

RegisterNetEvent('ziks-stamps:client:show', function(opts) ShowStamps(opts.stamps, opts) end)
RegisterNUICallback('hide', function(_, cb) HideStamps(); cb(1) end)

-- gallery ------------------------------------------------------------------
local function setGallery(state)
    galleryOpen = state
    SetNuiFocus(state, state)
    SendNUIMessage({ action = state and 'open' or 'close', catalog = state and catalog or nil })
end

if Config.Command then
    RegisterCommand(Config.Command, function() setGallery(not galleryOpen) end, Config.AcePermission and true or false)
end

RegisterNUICallback('close', function(_, cb) setGallery(false); cb(1) end)
RegisterNUICallback('stamp', function(data, cb)
    TriggerServerEvent('ziks-stamps:server:create', data.name, { ink = data.ink, fields = data.fields })
    cb(1)
end)
RegisterNetEvent('ziks-stamps:client:stamped', function(data)
    if galleryOpen then SendNUIMessage({ action = 'stamped', data = data }) end
end)

AddEventHandler('onResourceStop', function(r)
    if r == RES and (galleryOpen or viewOpen) then SetNuiFocus(false, false) end
end)
