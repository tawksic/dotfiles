-- See https://wiki.hypr.land/Configuring/Basics/Monitors/
-- List current monitors and supported resolutions with: hyprctl monitors all

hl.env("GDK_SCALE", "1")
hl.env("QT_SCALE_FACTOR", "1")
hl.env("STEAM_FORCE_DESKTOPUI_SCALING", "1")

hl.monitor({ output = "DP-1", mode = "1920x1080@144", position = "0x0", scale = 1 })
hl.monitor({ output = "DP-3", mode = "1920x1080@144", position = "1920x0", scale = 1 })

-- No workspace pinning: Omarchy gives each monitor its own workspaces 1-10
-- (see /usr/share/omarchy/default/hypr/monitor-workspaces.lua).
