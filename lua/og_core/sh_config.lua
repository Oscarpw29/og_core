-- Shared config for OG_core. Individual addons (skilltrees, OG_stims, og_medal) keep
-- their own config files; this only covers things genuinely shared between them.
OG.Config = OG.Config or {}

-- Chat/notify prefix used by OG.Notify when no addon-specific tag is given.
OG.Config.NotifyTag = "[OG]"

-- Fallback SAM permission -> usergroup mapping used by OG.HasPermission when SAM
-- isn't loaded (or the permission hasn't been registered with it).
OG.Config.DefaultFallbackGroup = "superadmin"

-- Playtime points (OG_core sv_playtime.lua). Earned from connected, non-AFK time.
OG.Config.Playtime = {
    Interval          = 900, -- seconds of active play per award (15 min)
    PointsPerInterval = 1,
    AfkTimeout        = 120, -- seconds without input before time stops counting (0 = count AFK too)
    Announce          = true, -- chat message when a point is earned
}
