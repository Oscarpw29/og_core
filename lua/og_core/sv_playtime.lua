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

-- Progress towards the next point lives in memory between awards, so it's also written out
-- every SAVE_EVERY ticks and on shutdown. Without this, a server restart (which doesn't fire
-- PlayerDisconnected) throws away up to 15 minutes of progress - restarting often would mean
-- nobody ever earns a point.
local SAVE_EVERY = 5
local ticks = 0

timer.Create("OG_Playtime_Tick", TICK, 0, function()
    local cfg = OG.Config.Playtime
    ticks = ticks + 1
    local saveAll = ticks % SAVE_EVERY == 0

    for _, ply in ipairs(player.GetHumans()) do
        if not Store:IsLoaded(ply) then continue end

        local active = cfg.AfkTimeout <= 0 or CurTime() - (ply.OGLastActive or 0) <= cfg.AfkTimeout
        local data = Store:Get(ply)
        local awarded = false

        if active then
            data.progress = data.progress + TICK

            if data.progress >= cfg.Interval then
                local awards = math.floor(data.progress / cfg.Interval)
                data.progress = data.progress - awards * cfg.Interval
                data.points = data.points + awards * cfg.PointsPerInterval
                awarded = true

                push(ply)
                if cfg.Announce then
                    OG.Notify(ply, "You earned " .. awards * cfg.PointsPerInterval .. " playtime point(s). Total: " .. data.points .. ".", "good")
                end
            end
        end

        if awarded or saveAll then Store:Save(ply) end
    end
end)

hook.Add("ShutDown", "OG_Playtime_SaveAll", function()
    for _, ply in ipairs(player.GetHumans()) do Store:Save(ply) end
end)

-- `og_playtime` (console) or !playtime (chat): how many points you have and how long until the next.
local function status(ply)
    local data = Store:Get(ply)
    if not data then return "Your playtime data is still loading." end

    local cfg = OG.Config.Playtime
    local left = math.max(cfg.Interval - data.progress, 0)
    return string.format("You have %d playtime point(s). Next one in about %d min of active play.", data.points, math.ceil(left / 60))
end

concommand.Add("og_playtime", function(ply)
    if IsValid(ply) then OG.Notify(ply, status(ply), "info") end
end)

hook.Add("PlayerSay", "OG_Playtime_ChatCommand", function(ply, text)
    if string.lower(string.Trim(text)) ~= "!playtime" then return end
    OG.Notify(ply, status(ply), "info")
    return ""
end)
