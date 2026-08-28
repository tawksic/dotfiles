#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$SCRIPT_DIR/config"

# ─── Colors ───────────────────────────────────────────────────────────────────

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

info()  { echo -e "${CYAN}::${NC} $1"; }
ok()    { echo -e "${GREEN}::${NC} $1"; }
warn()  { echo -e "${YELLOW}::${NC} $1"; }
err()   { echo -e "${RED}::${NC} $1"; }

# ─── Pre-flight checks ───────────────────────────────────────────────────────

if [[ ! -d /usr/share/omarchy ]]; then
    err "Omarchy is not installed. Install it first: https://omarchy.org"
    exit 1
fi

if [[ ! -f /etc/arch-release ]]; then
    err "This script is designed for Arch Linux."
    exit 1
fi

echo ""
echo -e "${BOLD}══════════════════════════════════════════${NC}"
echo -e "${BOLD}  Omarchy Dotfiles Setup${NC}"
echo -e "${BOLD}══════════════════════════════════════════${NC}"
echo ""

# ─── Prompts (all upfront) ───────────────────────────────────────────────────

info "SSH configuration (for the 'vult' alias)"
read -rp "  SSH key path [~/.ssh/id_ed25519]: " ssh_key
ssh_key="${ssh_key:-~/.ssh/id_ed25519}"
read -rp "  SSH username: " ssh_user
read -rp "  SSH server IP/hostname: " ssh_host
echo ""

info "NVIDIA GPU"
read -rp "  Install NVIDIA packages? (y/n) [n]: " do_nvidia
do_nvidia="${do_nvidia:-n}"
echo ""

echo -e "${BOLD}All questions answered. Installing...${NC}"
echo ""

# ─── Remove apps you don't use ───────────────────────────────────────────────

info "Removing apps you don't use..."

pacman_remove=(
    kdenlive
    obs-studio
    signal-desktop
)
for pkg in "${pacman_remove[@]}"; do
    if pacman -Qi "$pkg" &>/dev/null; then
        sudo pacman -Rns --noconfirm "$pkg" || warn "Failed to remove $pkg."
    fi
done

desktop_remove=(
    "$HOME/.local/share/applications/Basecamp.desktop"
    "$HOME/.local/share/applications/Google Contacts.desktop"
    "$HOME/.local/share/applications/Google Photos.desktop"
    "$HOME/.local/share/applications/HEY.desktop"
    "$HOME/.local/share/applications/Discord.desktop"
    "$HOME/.local/share/applications/WhatsApp.desktop"
    "$HOME/.local/share/applications/X.desktop"
)
for f in "${desktop_remove[@]}"; do
    [[ -f "$f" ]] && rm -f "$f"
done

ok "Cleanup done."
echo ""

# ─── Package installation ────────────────────────────────────────────────────

info "Installing pacman packages..."

pacman_packages=(
    archlinux-keyring
    bind
    cursor-bin
    dialog
    flatpak
    fzf
    go
    icoutils
    k9s
    librewolf
    libreoffice-fresh
    noto-fonts
    openvpn
    p7zip
    python-pip
    python-setuptools
    reflector
    rust
    systemd-resolvconf
    ttf-dejavu
    ttf-liberation
    uv
    wget
    wine
    wireguard-tools
)

if [[ "$do_nvidia" == "y" ]]; then
    pacman_packages+=(nvidia-utils lib32-nvidia-utils lib32-libxcrypt-compat)
fi

sudo pacman -S --needed --noconfirm "${pacman_packages[@]}" || warn "Some pacman packages may have failed."

# AUR packages (via yay)
info "Installing AUR packages..."
if ! command -v yay &>/dev/null; then
    warn "yay not found. Skipping AUR packages."
else
    aur_packages=(
        bolt-launcher
        lib32-giflib
        lib32-v4l-utils
        proton-ge-custom-bin
        protonup-qt-bin
        vesktop-bin
    )
    yay -S --needed --noconfirm "${aur_packages[@]}" || warn "Some AUR packages may have failed."
fi

# Flatpak
info "Installing flatpak packages..."
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo 2>/dev/null || true

flatpak_packages=(
    com.rtosta.zapzap
    it.mijorus.gearlever
)
for pkg in "${flatpak_packages[@]}"; do
    flatpak install -y flathub "$pkg" 2>/dev/null || warn "Failed to install flatpak: $pkg"
done

# ─── Deploy config files ─────────────────────────────────────────────────────

info "Deploying config files..."

backup_ts="$(date +%s)"

deploy() {
    local src="$1" dest="$2"
    mkdir -p "$(dirname "$dest")"
    if [[ -f "$dest" ]]; then
        cp "$dest" "${dest}.bak.${backup_ts}"
    fi
    cp "$src" "$dest"
}

deploy "$SCRIPT_DIR/.inputrc"           "$HOME/.inputrc"
deploy "$SCRIPT_DIR/.bashrc"            "$HOME/.bashrc"
deploy "$CONFIG_DIR/hypr/bindings.lua"  "$HOME/.config/hypr/bindings.lua"
deploy "$CONFIG_DIR/hypr/monitors.lua"  "$HOME/.config/hypr/monitors.lua"
deploy "$CONFIG_DIR/hypr/input.lua"     "$HOME/.config/hypr/input.lua"
deploy "$CONFIG_DIR/omarchy/shell.json" "$HOME/.config/omarchy/shell.json"
deploy "$CONFIG_DIR/foot/foot.ini"      "$HOME/.config/foot/foot.ini"
deploy "$CONFIG_DIR/starship.toml"      "$HOME/.config/starship.toml"
deploy "$CONFIG_DIR/uwsm/default"       "$HOME/.config/uwsm/default"
deploy "$CONFIG_DIR/omarchy/hooks/post-update.d/check-keybind-conflicts" \
       "$HOME/.config/omarchy/hooks/post-update.d/check-keybind-conflicts"

for editor_dir in "$HOME/.config/Code/User" "$HOME/.config/Cursor/User"; do
    deploy "$SCRIPT_DIR/misc/settings.json" "$editor_dir/settings.json"
    deploy "$SCRIPT_DIR/misc/keybindings.json" "$editor_dir/keybindings.json"
done

ok "Config files deployed."

# ─── Template substitution ───────────────────────────────────────────────────

info "Applying template values..."

sed -i "s|{{SSH_KEY}}|${ssh_key}|g"   "$HOME/.bashrc"
sed -i "s|{{SSH_USER}}|${ssh_user}|g" "$HOME/.bashrc"
sed -i "s|{{SSH_HOST}}|${ssh_host}|g" "$HOME/.bashrc"

ok "Templates applied."

# ─── Reload live config ──────────────────────────────────────────────────────

info "Reloading Hyprland and shell config..."
hyprctl reload 2>/dev/null || warn "Could not reload Hyprland config (not running?)."
omarchy-shell shell reloadConfig 2>/dev/null || warn "Could not reload shell config."

# ─── Done ─────────────────────────────────────────────────────────────────────

echo ""
echo -e "${BOLD}══════════════════════════════════════════${NC}"
echo -e "${GREEN}  Setup complete!${NC}"
echo -e "${BOLD}══════════════════════════════════════════${NC}"
echo ""
echo "  Remaining manual steps:"
echo ""
echo "  - foot doesn't hot-reload its config: close and reopen any open"
echo "    terminal windows to pick up foot.ini."
echo ""
echo "  - uwsm/default (EDITOR, TERMINAL) only takes effect after relaunching"
echo "    Hyprland: Super+Esc -> Relaunch."
echo ""
echo "  - Check if you need to run protonup-qt to add/update Proton GE for Steam:"
echo "      protonup-qt"
echo ""
echo "  - Steam launch options:"
echo "      Deadlock:    DXVK_ASYNC=1 VKD3D_DEBUG=none %command%"
echo "      Elden Ring:  unset SDL_VIDEODRIVER; %command%"
echo ""
echo "  - Obsidian: Settings -> Editor -> disable 'Readable line length'"
echo ""
echo "  - IDE: Settings -> search 'files.exclude' -> add __pycache__ etc."
echo ""
