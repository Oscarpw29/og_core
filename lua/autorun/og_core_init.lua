-- Load order matters: config -> core -> everything else. Prefix decides the realm.
-- Mirrors skilltrees' loader (skilltrees_init.lua) so both addons behave the same way.
OG = OG or {}

local FILES = {
    "sh_config.lua",
    "sh_core.lua",
    "sh_currency.lua",
    "sh_stats.lua",
    "sh_access.lua",

    "sv_data.lua",
    "sv_net.lua",
    "sv_permissions.lua",
    "sv_notify.lua",
    "sv_playtime.lua",

    "cl_notify.lua",

    "menu/cl_theme.lua",
}

OG.Load = OG.Load or function(folder, files)
    for _, name in ipairs(files) do
        local path = folder .. "/" .. name
        local realm = string.GetFileFromFilename(name):sub(1, 3)

        if realm == "sv_" then
            if SERVER then include(path) end
        elseif realm == "cl_" then
            if SERVER then AddCSLuaFile(path) else include(path) end
        else
            if SERVER then AddCSLuaFile(path) end
            include(path)
        end
    end
end

OG.Load("og_core", FILES)
