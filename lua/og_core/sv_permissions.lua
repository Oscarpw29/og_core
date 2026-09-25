-- One permission check every addon can share instead of writing its own admin gate.
-- Pattern lifted from og_npcs/core.lua: prefer SAM's permission system when it's loaded
-- and the permission is registered with it, otherwise fall back to a usergroup check.
--
-- perm: the SAM permission string (e.g. "vtx_skills - givexp"). Addons register these
-- themselves via SAM command SetPermission calls; this is just the runtime check used
-- outside of SAM commands (net receivers, concommands, etc).
-- fallbackFlag: "admin" or "superadmin" (default), used when SAM can't answer.
function OG.HasPermission(ply, perm, fallbackFlag)
    if not IsValid(ply) then return false end

    if sam and sam.player and sam.player.has_permission and perm then
        return sam.player.has_permission(ply, perm)
    end

    if fallbackFlag == "admin" then return ply:IsAdmin() end
    return ply:IsSuperAdmin()
end
