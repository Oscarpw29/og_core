-- Source-keyed stat modifier registry.
--
-- Any addon can contribute a table of { stat = amount } for a player under its own
-- source key (e.g. "stim_battle", "medal_valor"). OG.Stats.Get(ply) sums every source
-- into one flat table, the same shape skilltrees' SkillTrees:EmptyStats()/CalculateBuffs
-- already produce. This lets multiple stat-granting addons stack cleanly without any of
-- them needing to know about each other.
--
-- This registry only ADDS. It doesn't replace skilltrees' own skill-buff calculation;
-- skilltrees merges OG.Stats.Get(ply) into its own total (see sh_core.lua's bridge).
OG.Stats = OG.Stats or {}

-- ply(SteamID64) -> { [source] = { stat = amount } }
local sources = {}

local function key(ply)
    return IsValid(ply) and ply:SteamID64() or nil
end

-- Set (or replace) one source's contribution for a player. Passing nil/{} clears it.
function OG.Stats.Set(source, ply, statTable)
    local k = key(ply)
    if not k or not source then return end

    sources[k] = sources[k] or {}
    if not statTable or not next(statTable) then
        sources[k][source] = nil
    else
        sources[k][source] = statTable
    end
end

function OG.Stats.Clear(source, ply)
    OG.Stats.Set(source, ply, nil)
end

-- Clear every source for a player (disconnect cleanup).
function OG.Stats.ClearAll(ply)
    local k = key(ply)
    if k then sources[k] = nil end
end

-- Summed stat table across every registered source for this player.
function OG.Stats.Get(ply)
    local k = key(ply)
    local out = {}
    if not k or not sources[k] then return out end

    for _, statTable in pairs(sources[k]) do
        for stat, amount in pairs(statTable) do
            out[stat] = (out[stat] or 0) + amount
        end
    end
    return out
end

-- Clears any addon's cached total for this player and lets listeners react
-- (e.g. skilltrees calling SkillTrees:InvalidateBuffs via this hook).
function OG.Stats.Invalidate(ply)
    if not IsValid(ply) then return end
    hook.Run("OG_StatsChanged", ply)
end

if SERVER then
    hook.Add("PlayerDisconnected", "OG_Stats_Cleanup", function(ply)
        OG.Stats.ClearAll(ply)
    end)
end
