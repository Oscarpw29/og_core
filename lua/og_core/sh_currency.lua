-- Currency abstraction so addons (OG_stims crates, later shops/trading) don't hard-wire
-- DarkRP. A provider is { name, format(amount), available(), balance(ply), take(ply, n), give(ply, n) }.
-- `take`/`give` are only ever called on the server; `balance`/`format` also run on the
-- client for display. Override or add providers with OG.Currency.Register("id", {...}).
OG.Currency = OG.Currency or {}
local providers = {}

function OG.Currency.Register(id, def)
    providers[id] = def
end

function OG.Currency.Provider(id)
    return providers[id]
end

function OG.Currency.Name(id)
    local p = providers[id]
    return p and p.name or id
end

function OG.Currency.Format(id, amount)
    local p = providers[id]
    if p and p.format then return p.format(amount) end
    return string.Comma(amount) .. " " .. OG.Currency.Name(id)
end

function OG.Currency.IsAvailable(id)
    local p = providers[id]
    return p ~= nil and (not p.available or p.available() == true)
end

-- nil when the balance can't be read (e.g. currency not installed)
function OG.Currency.Balance(ply, id)
    local p = providers[id]
    if not p or not IsValid(ply) or not OG.Currency.IsAvailable(id) then return nil end
    return p.balance(ply)
end

function OG.Currency.CanAfford(ply, id, amount)
    local bal = OG.Currency.Balance(ply, id)
    return bal ~= nil and bal >= amount
end

if SERVER then
    -- Returns true only if the full amount was taken.
    function OG.Currency.Take(ply, id, amount)
        if not OG.Currency.CanAfford(ply, id, amount) then return false end
        providers[id].take(ply, amount)
        return true
    end

    function OG.Currency.Give(ply, id, amount)
        local p = providers[id]
        if not p or not IsValid(ply) or not OG.Currency.IsAvailable(id) then return false end
        p.give(ply, amount)
        return true
    end
end

-- DarkRP wallet
OG.Currency.Register("money", {
    name      = "Credits",
    available = function() return DarkRP ~= nil end,
    format    = function(amount)
        if DarkRP and DarkRP.formatMoney then return DarkRP.formatMoney(amount) end
        return "$" .. string.Comma(amount)
    end,
    balance   = function(ply) return ply:getDarkRPVar("money") or 0 end,
    take      = function(ply, n) ply:addMoney(-n) end,
    give      = function(ply, n) ply:addMoney(n) end,
})

-- Playtime points, earned by OG_core's sv_playtime.lua (1 per 15 min of active play).
-- The balance is mirrored to an NWInt so the client can display it.
OG.Currency.Register("playtime", {
    name    = "Playtime Points",
    format  = function(n) return string.Comma(n) .. (n == 1 and " point" or " points") end,
    balance = function(ply) return ply:GetNWInt("OG_PlaytimePoints", 0) end,
    take    = function(ply, n) OG.Playtime.Add(ply, -n) end,
    give    = function(ply, n) OG.Playtime.Add(ply, n) end,
})
