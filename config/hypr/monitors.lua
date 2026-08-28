-- See https://wiki.hypr.land/Configuring/Basics/Monitors/
-- List current monitors and supported resolutions with: hyprctl monitors all

hl.env("GDK_SCALE", "1")
hl.env("QT_SCALE_FACTOR", "1")
hl.env("STEAM_FORCE_DESKTOPUI_SCALING", "1")

hl.monitor({ output = "DP-1", mode = "1920x1080@144", position = "0x0", scale = 1 })
hl.monitor({ output = "DP-3", mode = "1920x1080@144", position = "1920x0", scale = 1 })

-- Workspace-to-monitor pinning (persistent so they spawn on the right
-- monitor from a clean start instead of only applying on first creation)
hl.workspace_rule({ workspace = "1", monitor = "DP-1", persistent = true })
hl.workspace_rule({ workspace = "2", monitor = "DP-1", persistent = true })
hl.workspace_rule({ workspace = "3", monitor = "DP-3", persistent = true })
hl.workspace_rule({ workspace = "4", monitor = "DP-3", persistent = true })
hl.workspace_rule({ workspace = "5", monitor = "DP-3", persistent = true })
