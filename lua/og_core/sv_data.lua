-- Generic per-SteamID PData+JSON store, factored out of skilltrees' sv_data.lua
-- (load-guard flag, versioned migration, save). Skilltrees itself is NOT moved onto
-- this - it keeps its own sv_data.lua. This is for new addons (OG_stims) so they don't
-- have to write the same load/save/migrate dance again.
--
-- Usage:
--   local Store = OG.DataStore("og_stims_data", {
--       version  = 1,
--       defaults = function() return { inventory = {}, loadout = {} } end,
--       migrate  = function(ply, data) end, -- optional, mutate data in place
--   })
--
--   hook.Add("PlayerInitialSpawn", "MyAddon_Load", function(ply) Store:Load(ply) end)
--   Store:Get(ply)          -- data table, or nil if not loaded yet
--   Store:IsLoaded(ply)     -- bool
--   Store:Save(ply)         -- writes PData; does NOT network anything itself
--   Store:Save(ply, syncNetString) -- also net.Start(syncNetString); net.WriteTable(data); net.Send(ply)

OG.DataStore = OG.DataStore or {}
local stores = {}

local StoreMeta = {}
StoreMeta.__index = StoreMeta

function StoreMeta:Load(ply, onLoaded)
    if not IsValid(ply) then return end
    local pdataKey = self.pdataKey

    ply[self.loadedFlag] = false
    ply[self.dataField] = self.defaults()

    timer.Simple(2, function()
        if not IsValid(ply) then return end

        local raw = ply:GetPData(pdataKey, nil)
        local data = self.defaults()
        if raw and raw ~= "" then
            local decoded = util.JSONToTable(raw)
            if istable(decoded) then
                data = table.Merge(self.defaults(), decoded)
            end
        end

        if self.migrate then
            local version = tonumber(data._version) or 1
            if version < self.version then
                self.migrate(ply, data, version)
                data._version = self.version
            end
        else
            data._version = self.version
        end

        ply[self.dataField] = data
        ply[self.loadedFlag] = true

        self:Save(ply)
        if onLoaded then onLoaded(data) end
    end)
end

function StoreMeta:IsLoaded(ply)
    return IsValid(ply) and ply[self.loadedFlag] == true
end

function StoreMeta:Get(ply)
    if not IsValid(ply) then return nil end
    return ply[self.dataField]
end

function StoreMeta:Save(ply, syncNetString)
    if not IsValid(ply) or not self:IsLoaded(ply) then return end
    ply:SetPData(self.pdataKey, util.TableToJSON(ply[self.dataField]))

    if syncNetString then
        net.Start(syncNetString)
            net.WriteTable(ply[self.dataField])
        net.Send(ply)
    end
end

-- name: unique store id, also used as the PData key. opts = { version, defaults, migrate }
function OG.DataStore(name, opts)
    if stores[name] then return stores[name] end

    local store = setmetatable({
        pdataKey   = name,
        dataField  = "_ogdata_" .. name,
        loadedFlag = "_ogdata_" .. name .. "_loaded",
        version    = (opts and opts.version) or 1,
        defaults   = (opts and opts.defaults) or function() return {} end,
        migrate    = opts and opts.migrate,
    }, StoreMeta)

    stores[name] = store
    return store
end
