-- Small shared utilities. Nothing here should depend on any specific addon.
OG = OG or {}

function OG.ListHas(list, value)
    if not list then return false end
    for _, v in pairs(list) do
        if v == value then return true end
    end
    return false
end
