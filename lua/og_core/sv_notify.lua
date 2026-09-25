-- Shared notify net message. Existing chat prints in skilltrees/og_medal are left alone;
-- this is for new code (OG_stims and anything built on OG_core going forward).
util.AddNetworkString("OG_Notify")

-- kind: "info" (default), "good", "warn", "bad" - purely a hint for client-side styling.
function OG.Notify(ply, msg, kind)
    if not IsValid(ply) then return end
    net.Start("OG_Notify")
        net.WriteString(msg)
        net.WriteString(kind or "info")
    net.Send(ply)
end
