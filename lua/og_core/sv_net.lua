-- Small net helpers so addons don't hand-roll registration loops and rate limiting.
OG.Net = OG.Net or {}

-- Register a batch of network strings in one call.
-- OG.Net.Strings({ "og_stims.use", "og_stims.sync" })
function OG.Net.Strings(names)
    for _, name in ipairs(names) do
        util.AddNetworkString(name)
    end
end

local lastReceive = {} -- "<msg>:<steamid64>" -> CurTime()

-- Wraps net.Receive with a per-player cooldown so a spammed message can't flood the
-- server. cooldown defaults to 0.25s (matches skilltrees' commit/reset cooldown).
function OG.Net.Receive(name, cooldown, callback)
    net.Receive(name, function(len, ply)
        if not IsValid(ply) then return end

        local k = name .. ":" .. ply:SteamID64()
        local now = CurTime()
        if lastReceive[k] and now - lastReceive[k] < (cooldown or 0.25) then return end
        lastReceive[k] = now

        callback(len, ply)
    end)
end
