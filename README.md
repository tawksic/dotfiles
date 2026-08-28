This assumes you're using Omarchy (quattro / package-backed layout).

This is very oppinionated on top of DHH's opinions.

Removes the apps I don't use, installs the pacman/AUR/Flatpak packages I do use
and deploys the config in config/ (Hyprland's hypr/*.lua overrides,
omarchy/shell.json, foot.ini, starship.toml, uwsm/default, .bashrc, .inputrc,
and editor settings.json) into place. It'll prompt for a few things (SSH
details, NVIDIA) up front.

The hypr/*.lua files are overrides only (bindings, monitors, input), not
full configs. Omarchy's own defaults live in /usr/share/omarchy/default/hypr
and aren't touched by this. To see the effective merged result:

  - keybindings: `omarchy menu keybindings --print`
  - monitors/workspaces: `hyprctl monitors`, `hyprctl workspacerules`
  - input settings: `hyprctl getoption input:<name>`

~/.config/omarchy/hooks/post-update.d/check-keybind-conflicts also runs
automatically after every `omarchy update` and notifies if any of Omarchy's
default keybindings changed since the last check, so bindings.lua overrides
don't silently drift out of sync with new defaults.
