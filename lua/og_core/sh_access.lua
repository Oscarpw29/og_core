-- Generic "does this player's unit/job/rank match this rule?" check.
-- Lifted from SkillTrees:CanAccessTree so any addon (skilltrees, OG_stims, ...) can gate
-- content by team / MRS group / usergroup rank / SteamID with the same rules.
--
-- rule = { Teams = {...}, MRSGroup = {...}, Ranks = {...}, SteamIDs = {...} }
-- A rule with none of those fields set always matches.
function OG.MatchesAccess(ply, rule)
    if not IsValid(ply) then return false end
    if not rule then return true end

    if not rule.Teams and not rule.MRSGroup and not rule.Ranks and not rule.SteamIDs then
        return true
    end

    if rule.Teams then
        local t = ply:Team()
        if OG.ListHas(rule.Teams, t) or OG.ListHas(rule.Teams, team.GetName(t)) then return true end
    end
    if rule.MRSGroup and MRS and MRS.GetNWdata and OG.ListHas(rule.MRSGroup, MRS.GetNWdata(ply, "Group")) then
        return true
    end
    if rule.Ranks and OG.ListHas(rule.Ranks, ply:GetUserGroup()) then return true end
    if rule.SteamIDs and OG.ListHas(rule.SteamIDs, ply:SteamID()) then return true end

    return false
end
