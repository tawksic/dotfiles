-- Keep only your personal keybinding overrides here. Add new bindings or
-- unbind defaults before replacing them.

-- See current bindings and descriptions:
--   omarchy menu keybindings --print

-- Browser (LibreWolf doesn't need Chromium's scaling/ozone flags)
o.bind("SUPER + B", "Browser", { omarchy = "browser" })

-- Obsidian (displaces default "Pop window out", relocated to SUPER+P below)
hl.unbind("SUPER + O")
o.bind("SUPER + O", "Obsidian", 'omarchy-launch-or-focus obsidian "uwsm app -- obsidian -disable-gpu --enable-wayland-ime"')

-- Pop window out relocated here (displaces default "Pseudo window", dropped intentionally)
hl.unbind("SUPER + P")
o.bind("SUPER + P", "Pop window out (float & pin)", "omarchy-hyprland-window-pop")

-- Screenshot to clipboard (displaces default "Toggle scratchpad")
hl.unbind("SUPER + S")
o.bind("SUPER + S", "Screenshot", "omarchy-capture-screenshot region copy")

-- Screenshot with immediate edit in Tensaku (displaces default "Google Maps")
hl.unbind("SUPER + SHIFT + S")
o.bind("SUPER + SHIFT + S", "Screenshot (edit)", "bash -c 'f=$(omarchy-capture-screenshot region save); [ -n \"$f\" ] && tensaku-edit \"$f\"'")

-- Don't use X/Twitter
hl.unbind("SUPER + SHIFT + X")

-- Don't use the WhatsApp webapp (using ZapZap instead)
hl.unbind("SUPER + SHIFT + ALT + G")

-- Use Proton Mail/Calendar instead of HEY
hl.unbind("SUPER + SHIFT + C")
hl.unbind("SUPER + SHIFT + E")
hl.unbind("SUPER + SHIFT + ALT + E")
o.bind("SUPER + SHIFT + C", "Calendar", { webapp = "https://calendar.proton.me" })
o.bind("SUPER + SHIFT + E", "Email", { webapp = "https://mail.proton.me" })

-- YouTube
o.bind("SUPER + Y", "YouTube", { webapp = "https://youtube.com/" })

-- Push to mute (Wayland doesn't support global hotkeys for raw input)
o.bind("SUPER + Z", "Push to mute", "pactl set-source-mute @DEFAULT_SOURCE@ toggle")

-- Numpad workspace switching (parallel to the SUPER+1-9,0 top-row defaults)
local numpad_workspaces = { [87] = 1, [88] = 2, [89] = 3, [83] = 4, [84] = 5 }
for code, workspace in pairs(numpad_workspaces) do
  local key = "code:" .. tostring(code)
  o.bind("SUPER + " .. key, "Switch to workspace " .. workspace, hl.dsp.focus({ workspace = tostring(workspace) }))
  o.bind("SUPER + SHIFT + " .. key, "Move window to workspace " .. workspace, hl.dsp.window.move({ workspace = tostring(workspace) }))
end
