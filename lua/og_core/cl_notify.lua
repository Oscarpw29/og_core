local KIND_COLOR = {
    info = Color(120, 190, 230),
    good = Color(110, 225, 130),
    warn = Color(245, 200, 70),
    bad  = Color(235, 90, 80),
}

net.Receive("OG_Notify", function()
    local msg  = net.ReadString()
    local kind = net.ReadString()
    chat.AddText(KIND_COLOR[kind] or KIND_COLOR.info, OG.Config.NotifyTag .. " ", color_white, msg)
end)
