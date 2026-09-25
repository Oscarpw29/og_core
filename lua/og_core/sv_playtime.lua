-- Playtime points: 1 point per OG.Config.Playtime.Interval of active (non-AFK) play.
-- Stored per SteamID via OG.DataStore and mirrored to an NWInt so the client can show the
-- balance. Spent through OG.Currency ("playtime") - see sh_currency.lua.
OG.Playtime = OG.Playtime or {}

local TICK = 60 -- seconds; progress is counted in whole ticks

local Store = OG.DataStore("og_playtime", {
    version = 1,
    defaults = function()
        return {
            points   = 0,
            progress = 0, -- seconds of active play towards the next point
        }
    end,
})

local function push(ply)
    local data = Store:Get(ply)
    if data then ply:SetNWInt("OG_PlaytimePoints", data.points) end
end

function OG.Playtime.Get(ply)
    local data = Store:Get(ply)
    return data and data.points or 0
end

-- n may be negative (spending). Never goes below 0.
function OG.Playtime.Add(ply, n)
    if not Store:IsLoaded(ply) then return false end
    local data = Store:Get(ply)
    data.points = math.max(data.points + n, 0)
    Store:Save(ply)
    push(ply)
    return true
end

hook.Add("PlayerInitialSpawn", "OG_Playtime_Load", function(ply)
    ply.OGLastActive = CurTime()
    Store:Load(ply, function() push(ply) end)
end)

hook.Add("PlayerDisconnected", "OG_Playtime_Save", function(ply)
    Store:Save(ply) -- keeps the partial-interval progress
end)

-- Any input counts as activity
hook.Add("StartCommand", "OG_Playtime_Activity", function(ply, cmd)
    if not ply:IsPlayer() or ply:IsBot() then return end
    if cmd:GetButtons() ~= 0 or cmd:GetMouseX() ~= 0 or cmd:GetMouseY() ~= 0 then
        ply.OGLastActive = CurTime()
    end
end)

timer.Create("OG_Playtime_Tick", TICK, 0, function()
    local cfg = OG.Config.Playtime

    for _, ply in ipairs(player.GetHumans()) do
        if not Store:IsLoaded(ply) then continue end
        if cfg.AfkTimeout > 0 and CurTime() - (ply.OGLastActive or 0) > cfg.AfkTimeout then continue end

        local data = Store:Get(ply)
        data.progress = data.progress + TICK

        if data.progress >= cfg.Interval then
            local awards = math.floor(data.progress / cfg.Interval)
            data.progress = data.progress - awards * cfg.Interval
            data.points = data.points + awards * cfg.PointsPerInterval

            Store:Save(ply)
            push(ply)
            if cfg.Announce then
                OG.Notify(ply, "You earned " .. awards * cfg.PointsPerInterval .. " playtime point(s). Total: " .. data.points .. ".", "good")
            end
        end
    end
end)
