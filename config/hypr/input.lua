-- Keep only your personal input overrides here. Uncommented settings below
-- replace Omarchy's defaults.

hl.config({
  input = {
    -- Swap Alt/Ctrl so copy/paste etc. feel like Mac's Cmd position.
    kb_options = "ctrl:swap_lalt_lctl,ctrl:swap_ralt_rctl",

    repeat_delay = 600,

    numlock_by_default = false,

    sensitivity = -0.35,
    accel_profile = "flat",
  },
})

-- Scroll faster in the terminal
o.window({ tag = "terminal" }, { scroll_touchpad = 1.5 })
