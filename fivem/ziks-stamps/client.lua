-- ziks-stamps · client · MIT © 2026 ziks (github.com/ziks29)
local RES = GetCurrentResourceName()
local catalog = json.decode(LoadResourceFile(RES, 'html/stamps.json') or '{}') or {}
local open = false

--- URL of a stamp SVG that any NUI page can use in <img src> (and fetch where allowed).
local function GetStampUrl(nameOrFile)
    local file = nameOrFile
    if not file:find('%.svg$') then
        for _, list in pairs(catalog) do
            for _, s in ipairs(list) do
                if s.name == nameOrFile then file = s.file end
            end
        end
    end
    return ('https://cfx-nui-%s/html/%s'):format(RES, file)
end
exports('GetStampUrl', GetStampUrl)
exports('GetBaseUrl', function() return ('https://cfx-nui-%s/html/'):format(RES) end)

local function setOpen(state)
    open = state
    SetNuiFocus(state, state)
    SendNUIMessage({ action = state and 'open' or 'close', catalog = state and catalog or nil })
end

if Config.Command then
    RegisterCommand(Config.Command, function() setOpen(not open) end, Config.AcePermission and true or false)
end

RegisterNUICallback('close', function(_, cb) setOpen(false); cb(1) end)
RegisterNUICallback('stamp', function(data, cb)
    TriggerServerEvent('ziks-stamps:server:create', data.name, { ink = data.ink, fields = data.fields })
    cb(1)
end)

RegisterNetEvent('ziks-stamps:client:stamped', function(data)
    if open then SendNUIMessage({ action = 'stamped', data = data }) end
end)

AddEventHandler('onResourceStop', function(r) if r == RES and open then SetNuiFocus(false, false) end end)
